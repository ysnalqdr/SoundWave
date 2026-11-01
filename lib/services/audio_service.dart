import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

/// Layanan audio tunggal untuk seluruh aplikasi.
///
/// Dua alasan kenapa dibuat singleton:
///
/// 1. **Satu pemutar saja.** Kalau setiap widget membuat `AudioPlayer` sendiri,
///    dua preview bisa berbunyi bersamaan dan tidak ada yang bisa menghentikan
///    yang lain. Semua pemutaran lewat satu instance di sini.
/// 2. **State global yang bisa dihentikan.** Saat pengguna berpindah layar,
///    siapa pun bisa memanggil [stopPreview] tanpa perlu tahu widget mana yang
///    sedang memutar.
///
/// Beep gate sengaja memakai pemutar terpisah: ia harus tetap berbunyi
/// walaupun preview musik sedang berjalan, dan tidak boleh memotongnya.
class AudioService {
  static final AudioService instance = AudioService._();

  AudioService._() {
    // Preview diputar SEKALI, tidak diulang. Saat habis, posisi
    // dikembalikan ke awal supaya tombol play langsung bisa dipakai lagi
    // tanpa pengguna harus menekan dua kali.
    _completedSub = _previewPlayer.playerStateStream.listen((state) {
      // Hanya relevan pada mode sekali-putar. Pada mode loop, pemutar
      // mengulang sendiri sehingga status `completed` tidak tercapai.
      if (state.processingState == ProcessingState.completed) {
        _previewPlayer.seek(Duration.zero);
        _previewPlayer.pause();
      }
    });
  }

  final AudioPlayer _previewPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _sessionConfigured = false;
  StreamSubscription<PlayerState>? _completedSub;

  /// Detik akhir potongan untuk berkas jaringan. 0 = tidak dibatasi.
  int _batasAkhirPreview = 0;

  /// Pengawas batas akhir potongan audio.
  Timer? _pengawasPreview;

  /// Menghentikan preview tepat di batas akhir potongan.
  ///
  /// Diperlukan untuk berkas jaringan yang panjang: pemutar tidak tahu di
  /// mana "potongan" berakhir, jadi posisinya diperiksa berkala lalu dijeda
  /// paksa. Tanpa ini, memilih 20 detik dari lagu 4 menit akan memutar
  /// seluruh lagu.
  void _pasangPengawasPreview() {
    _pengawasPreview?.cancel();
    if (_batasAkhirPreview <= 0) return;
    _pengawasPreview = Timer.periodic(const Duration(milliseconds: 400), (_) {
      final posisi = _previewPlayer.position.inSeconds;
      if (posisi >= _batasAkhirPreview) {
        _pengawasPreview?.cancel();
        _previewPlayer.pause();
      }
    });
  }

  /// Id berkas yang sedang diputar pada pemutar preview (null bila diam).
  String? _activePreview;

  /// Judul track yang sedang aktif. Bernilai null bila tidak ada audio.
  ///
  /// Dipakai mini player untuk memutuskan kapan dirinya harus tampil:
  /// selama ada track aktif (baik sedang main maupun dijeda), bar tetap
  /// terlihat supaya pengguna bisa menjeda atau melanjutkan kapan saja.
  final ValueNotifier<String?> nowPlaying = ValueNotifier<String?>(null);

  /// True bila pemutar preview sedang berbunyi.
  Stream<bool> get isPlayingStream => _previewPlayer.playerStateStream
      .map((s) =>
          s.playing && s.processingState != ProcessingState.completed);

  /// Stream posisi pemutar preview, untuk progress bar.
  Stream<Duration> get positionStream => _previewPlayer.positionStream;

  /// Stream durasi total berkas yang sedang diputar.
  Stream<Duration?> get durationStream => _previewPlayer.durationStream;

  /// Stream status pemutaran (playing / paused / completed).
  Stream<PlayerState> get playerStateStream => _previewPlayer.playerStateStream;

  /// Id berkas yang sedang diputar, atau null.
  String? get activePreview => _activePreview;

  /// Menyiapkan sesi audio: fokus audio, perilaku saat telepon masuk, dsb.
  ///
  /// Dipanggil sekali secara lazy — tidak di `main()` supaya startup tidak
  /// menunggu plugin audio.
  Future<void> _ensureSession() async {
    if (_sessionConfigured) return;
    _sessionConfigured = true;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      // Di lingkungan tanpa audio (mis. unit test), kegagalan sesi tidak
      // boleh menggagalkan pemutaran.
      debugPrint('[AudioService] sesi audio gagal disiapkan: $e');
    }
  }

  /// Memutar potongan preview.
  ///
  /// [ref] boleh berupa:
  /// - path aset, mis. `assets/audio/preview_01.mp3` (dibundel di APK), atau
  /// - URL http/https, mis. `https://cdn.contoh.com/lagu.mp3` (diunduh lalu
  ///   di-cache oleh pemutar).
  ///
  /// Kenapa dua bentuk: berkas bawaan tidak bisa ditambah tanpa build ulang,
  /// sedangkan admin perlu bisa memasang lagu apa pun untuk konser tertentu.
  /// Kolom URL pada form konser menutup celah itu tanpa perlu Firebase Storage
  /// (yang menuntut paket Blaze).
  ///
  /// [loop] `true` (bawaan) membuat potongan diulang terus sampai pengguna
  /// menekan jeda atau meninggalkan halaman.
  ///
  /// Mengembalikan true bila pemutaran dimulai.
  Future<bool> playPreview(
    String ref, {
    bool loop = true,
    String? title,
    int startSec = 0,
    int durationSec = 0,
  }) async {
    await _ensureSession();
    try {
      // Kalau berkas yang sama sedang diputar, cukup lanjutkan.
      if (_activePreview == ref &&
          _previewPlayer.processingState != ProcessingState.completed) {
        await _previewPlayer.play();
        return true;
      }
      _activePreview = ref;
      nowPlaying.value = (title ?? '').trim().isEmpty ? 'Preview lagu' : title!.trim();
      await _previewPlayer.setLoopMode(
        loop ? LoopMode.one : LoopMode.off,
      );
      if (_isRemote(ref)) {
        await _previewPlayer.setUrl(ref);
      } else {
        await _previewPlayer.setAsset(ref);
      }

      // Potongan mulai dari detik tertentu (berkas jaringan yang panjang).
      //
      // Dilakukan setelah berkas termuat, karena posisi tidak bisa dilompati
      // sebelum durasi diketahui. `startSec` 0 pada berkas bawaan, jadi
      // cabang ini tidak berpengaruh pada aset yang sudah dipotong.
      _batasAkhirPreview = durationSec > 0 ? startSec + durationSec : 0;
      if (startSec > 0) {
        try {
          await _previewPlayer.seek(Duration(seconds: startSec));
        } catch (_) {
          // Sebagian format tidak mendukung seek sebelum siap; abaikan dan
          // mulai dari awal daripada gagal memutar sama sekali.
        }
      }
      _pasangPengawasPreview();

      // Tidak di-await: play() selesai saat pemutaran berakhir, bukan saat
      // dimulai. Menunggunya akan menggantung pemanggil selama 20 detik.
      unawaited(_previewPlayer.play());
      return true;
    } catch (e) {
      debugPrint('[AudioService] gagal memutar $ref: $e');
      _activePreview = null;
      return false;
    }
  }

  /// True bila [ref] adalah URL jaringan, bukan path aset.
  static bool _isRemote(String ref) {
    final r = ref.toLowerCase();
    return r.startsWith('http://') || r.startsWith('https://');
  }

  /// Menjeda preview tanpa membuang posisi.
  Future<void> pausePreview() async {
    try {
      await _previewPlayer.pause();
    } catch (_) {}
  }

  /// Melanjutkan preview dari posisi terakhir.
  Future<void> resumePreview() async {
    try {
      await _previewPlayer.play();
    } catch (_) {}
  }

  /// Menghentikan preview dan mengembalikan posisi ke awal.
  ///
  /// Dipanggil dari `dispose()` layar agar audio tidak terus berbunyi setelah
  /// pengguna keluar halaman.
  Future<void> stopPreview() async {
    _pengawasPreview?.cancel();
    _batasAkhirPreview = 0;
    try {
      await _previewPlayer.stop();
    } catch (_) {}
    _activePreview = null;
    nowPlaying.value = null;
  }

  /// Melompat ke posisi tertentu (untuk seek dari progress bar).
  Future<void> seekPreview(Duration position) async {
    try {
      await _previewPlayer.seek(position);
    } catch (_) {}
  }

  // ---------------------------------------------------------------- beep gate
  //
  // Beep dimainkan pada pemutar terpisah supaya bisa tumpang tindih dengan
  // preview musik, dan supaya `stop()` pada preview tidak mematikannya.

  /// Nada pendek untuk hasil scan yang **valid**.
  Future<void> beepOk() => _playSfx('assets/audio/beep_ok.mp3');

  /// Nada pendek untuk hasil scan yang **ditolak**.
  Future<void> beepFail() => _playSfx('assets/audio/beep_fail.mp3');

  Future<void> _playSfx(String assetPath) async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setAsset(assetPath);
      unawaited(_sfxPlayer.play());
    } catch (e) {
      // Beep bersifat pelengkap: kalau gagal, haptic & warna layar tetap
      // memberi tahu petugas. Jangan sampai error audio menghentikan scan.
      debugPrint('[AudioService] beep gagal ($assetPath): $e');
    }
  }

  /// Getar + bunyi sekaligus untuk hasil scan.
  ///
  /// Digabung di satu tempat agar gate selalu memberi umpan balik yang sama,
  /// tidak bergantung pada pemanggil mengingat salah satunya.
  Future<void> feedbackScan({required bool valid}) async {
    if (valid) {
      unawaited(HapticFeedback.mediumImpact());
      unawaited(SystemSound.play(SystemSoundType.click));
      await beepOk();
    } else {
      unawaited(HapticFeedback.heavyImpact());
      unawaited(SystemSound.play(SystemSoundType.alert));
      await beepFail();
    }
  }

  /// Membebaskan pemutar. Dipanggil saat aplikasi benar-benar berhenti.
  Future<void> dispose() async {
    _pengawasPreview?.cancel();
    await _completedSub?.cancel();
    await _previewPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
