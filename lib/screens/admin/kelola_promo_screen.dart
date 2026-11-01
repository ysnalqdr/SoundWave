import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/promo_model.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';
import '../../core/errors/pesan_galat.dart';

/// Admin screen for managing promo codes: a form to create, and the list
/// below it streamed from `promo_codes`.
class KelolaPromoScreen extends ConsumerStatefulWidget {
  final UserModel user;
  final VoidCallback? onBukaSidebar;
  const KelolaPromoScreen({super.key, required this.user, this.onBukaSidebar});

  @override
  ConsumerState<KelolaPromoScreen> createState() => _KelolaPromoScreenState();
}

class _KelolaPromoScreenState extends ConsumerState<KelolaPromoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kodeCtrl = TextEditingController();
  final _nilaiCtrl = TextEditingController();
  final _minPembelianCtrl = TextEditingController();
  final _maxPakaiCtrl = TextEditingController(text: '100');
  final _deskripsiCtrl = TextEditingController();

  /// Label kecil di kartu promo, mis. "EARLY BIRD" atau "SIGNATURE".
  /// Kosong berarti memakai label bawaan tema.
  final _labelCtrl = TextEditingController();
  final _mulaiCtrl = TextEditingController();
  final _akhirCtrl = TextEditingController();

  String _tipe = 'percentage';

  /// Tema kartu promo. Kosong = bergilir otomatis menurut urutan tampil.
  /// Admin tidak wajib mengisi; ini hanya untuk mengatur tampilan.
  String _tema = '';
  DateTime? _berlakuMulai;
  DateTime? _berlakuAkhir;
  bool _saving = false;

  @override
  void dispose() {
    _kodeCtrl.dispose();
    _nilaiCtrl.dispose();
    _minPembelianCtrl.dispose();
    _maxPakaiCtrl.dispose();
    _deskripsiCtrl.dispose();
    _labelCtrl.dispose();
    _mulaiCtrl.dispose();
    _akhirCtrl.dispose();
    super.dispose();
  }

  String _formatRupiah(double nominal) {
    final formatted = nominal
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  String _formatTanggal(DateTime t) {
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';
  }

  /// Pilih tanggal mulai atau akhir lewat date picker.
  /// Dua field terpisah supaya nilainya terlihat dan pasti tersimpan.
  Future<void> _pilihTanggal({required bool mulai}) async {
    final now = DateTime.now();
    final initial = mulai
        ? (_berlakuMulai ?? now)
        : (_berlakuAkhir ?? _berlakuMulai ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: mulai ? 'Pilih tanggal mulai' : 'Pilih tanggal akhir',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.aksi,
                onPrimary: AppColors.warnaTombolTeks,
                surface: AppColors.surfaceLight,
                surfaceContainerHigh: AppColors.surfaceLight,
              ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    final d = DateTime(picked.year, picked.month, picked.day);
    if (mulai) {
      setState(() {
        _berlakuMulai = d;
        _mulaiCtrl.text = _formatTanggal(d);
        // Kalau akhir jadi lebih awal dari mulai, kosongkan supaya valid.
        if (_berlakuAkhir != null && _berlakuAkhir!.isBefore(d)) {
          _berlakuAkhir = null;
          _akhirCtrl.clear();
        }
      });
    } else {
      if (_berlakuMulai != null && d.isBefore(_berlakuMulai!)) {
        _toast('Tanggal akhir tidak boleh sebelum tanggal mulai',
            AppColors.warning);
        return;
      }
      setState(() {
        _berlakuAkhir = d;
        _akhirCtrl.text = _formatTanggal(d);
      });
    }
  }

  Future<void> _buatPromo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_berlakuMulai == null || _berlakuAkhir == null) {
      _toast('Isi tanggal "Berlaku Mulai" & "Berlaku Akhir"',
          AppColors.warning);
      return;
    }
    if (!_berlakuAkhir!.isAfter(_berlakuMulai!)) {
      _toast('Tanggal akhir harus setelah tanggal mulai', AppColors.warning);
      return;
    }

    // Nilai dibaca dengan `tryParse`, bukan `parse`.
    //
    // Validator seharusnya sudah menahan input tidak sah, tapi satu jalur
    // saja yang lolos (mis. tombol Simpan ditekan lewat keyboard saat kolom
    // masih kosong) akan melempar FormatException di dalam `try` — dan
    // pengguna hanya melihat tombol yang seolah tidak bereaksi.
    final nilai = double.tryParse(_nilaiCtrl.text.trim());
    final maxPakai = int.tryParse(_maxPakaiCtrl.text.trim());
    final minTeks = _minPembelianCtrl.text.trim();
    final minPembelian = minTeks.isEmpty ? 0.0 : double.tryParse(minTeks);

    if (nilai == null || nilai <= 0) {
      _toast('Nilai diskon belum diisi dengan benar', AppColors.warning);
      return;
    }
    if (maxPakai == null || maxPakai <= 0) {
      _toast('Maks. pakai harus angka lebih dari 0', AppColors.warning);
      return;
    }
    if (minPembelian == null || minPembelian < 0) {
      _toast('Minimum belanja tidak valid', AppColors.warning);
      return;
    }

    setState(() => _saving = true);
    try {
      final promo = PromoCodeModel(
        id: '',
        kode: _kodeCtrl.text.trim().toUpperCase(),
        tipe: _tipe,
        nilai: nilai,
        minPembelian: minPembelian,
        maxPakai: maxPakai,
        berlakuMulai: DateTime(
            _berlakuMulai!.year, _berlakuMulai!.month, _berlakuMulai!.day),
        // Simpan akhir hari supaya promo tetap berlaku sampai hari terakhir.
        berlakuAkhir: DateTime(_berlakuAkhir!.year, _berlakuAkhir!.month,
            _berlakuAkhir!.day, 23, 59, 59),
        deskripsi: _deskripsiCtrl.text.trim().isEmpty
            ? null
            : _deskripsiCtrl.text.trim(),
        tema: _tema.isEmpty ? null : _tema,
        label: _labelCtrl.text.trim().isEmpty
            ? null
            : _labelCtrl.text.trim().toUpperCase(),
      );

      // ID dokumen = kode promo, BUKAN acak.
      //
      // Sebelumnya dipakai `.add()`, sehingga Firestore membuat ID acak.
      // Backend mencari voucher dengan `.doc(kode)` — jadi setiap promo
      // yang dibuat dari form ini TIDAK PERNAH ditemukan, dan kode yang
      // diketik pengguna selalu ditolak dengan "Kode promo tidak ditemukan".
      // Bug ini tidak terlihat di tes karena tes memakai model, bukan
      // Firestore sungguhan.
      //
      // `.doc(kode).set()` juga membuat pembuatan promo idempoten: kode
      // yang sama tidak bisa menghasilkan dua dokumen berbeda.
      await FirebaseFirestore.instance
          .collection('promo_codes')
          .doc(promo.kode)
          .set(promo.toMap());

      _resetForm();
      _toast('Promo berhasil dibuat', AppColors.aksi);
    } catch (e) {
      _toast(PesanGalat.untuk(e, awalan: 'Gagal membuat promo'), AppColors.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _kodeCtrl.clear();
    _nilaiCtrl.clear();
    _minPembelianCtrl.clear();
    _maxPakaiCtrl.text = '100';
    _deskripsiCtrl.clear();
    _labelCtrl.clear();
    _mulaiCtrl.clear();
    _akhirCtrl.clear();
    setState(() {
      _tipe = 'percentage';
      _tema = '';
      _berlakuMulai = null;
      _berlakuAkhir = null;
    });
  }

  /// Soft-delete: set aktif=false (bukan hapus permanen).
  Future<void> _nonaktifkanPromo(PromoCodeModel promo) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          'Nonaktifkan Promo',
          style: GoogleFonts.rajdhani(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Kode "${promo.kode}" akan dinonaktifkan dan tidak bisa dipakai lagi.',
          style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Nonaktifkan',
                style: GoogleFonts.spaceGrotesk(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (konfirmasi != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('promo_codes')
          .doc(promo.id)
          .update({'aktif': false});
      _toast('Promo dinonaktifkan', AppColors.warning);
    } catch (e) {
      _toast(PesanGalat.untuk(e, awalan: 'Gagal menonaktifkan promo'), AppColors.error);
    }
  }

  void _toast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: AppRadius.rMd),
      ),
    );
  }

  InputDecoration _input(String label, {String? prefix, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.spaceGrotesk(
          color: AppColors.textMuted, fontSize: 13),
      hintStyle: GoogleFonts.spaceGrotesk(
          color: AppColors.textMuted, fontSize: 13),
      prefixText: prefix,
      filled: true,
      fillColor: AppColors.surfaceLight,
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.rMd,
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.rMd,
        borderSide: const BorderSide(color: AppColors.aksi, width: 1.2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Buka menu',
          icon: Icon(widget.onBukaSidebar != null ? Icons.menu_rounded : Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (widget.onBukaSidebar != null) {
              widget.onBukaSidebar!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'KELOLA PROMO',
          style: GoogleFonts.rajdhani(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormCard(),
            const SizedBox(height: 24),
            Text(
              'Daftar Promo',
              style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _buildPromoList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: AppColors.divider),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer_rounded,
                    color: AppColors.aksi, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Buat Promo Baru',
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _kodeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: _input('Kode Promo', hint: 'Mis. GIGS50'),
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary, fontSize: 14),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Kode wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_tipe),
                    initialValue: _tipe,
                    isExpanded: true,
                    decoration: _input('Tipe Diskon'),
                    dropdownColor: AppColors.surfaceLight,
                    style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary, fontSize: 14),
                    items: const [
                      DropdownMenuItem(
                          value: 'percentage',
                          child: Text('Persentase (%)',
                              overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 'fixed',
                          child: Text('Nominal (Rp)',
                              overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => _tipe = v ?? 'percentage'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _nilaiCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _input(
                      'Nilai',
                      prefix: _tipe == 'fixed' ? 'Rp ' : null,
                      hint: _tipe == 'percentage' ? 'Mis. 10' : 'Mis. 25000',
                    ),
                    style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary, fontSize: 14),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').trim());
                      if (n == null || n <= 0) return 'Nilai tidak valid';
                      // Diskon persentase di atas 100% tidak masuk akal dan
                      // membuat potongan melebihi harga tiket.
                      if (_tipe == 'percentage' && n > 100) {
                        return 'Maksimal 100%';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Label kartu. Dipisah dari tema supaya warna dan makna tidak
            // dipaksa berpasangan: promo "Early Bird" cocok berwarna emas
            // tetapi tidak cocok disebut "SIGNATURE".
            TextFormField(
              controller: _labelCtrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 18,
              decoration: _input('Label Kartu',
                  hint: 'Mis. EARLY BIRD').copyWith(counterText: ''),
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary, fontSize: 14),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return null; // kosong = pakai label tema
                if (t.length > 18) return 'Maksimal 18 karakter';
                return null;
              },
            ),
            const SizedBox(height: 14),
            // Tema hanya mengatur warna kartu di halaman Jelajah. Kosongkan
            // bila ingin warna bergilir otomatis — deretan kartu tetap
            // beragam tanpa admin harus mengisi apa pun.
            DropdownButtonFormField<String>(
              key: ValueKey('tema-$_tema'),
              initialValue: _tema,
              isExpanded: true,
              decoration: _input('Tema Kartu'),
              dropdownColor: AppColors.surfaceLight,
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary, fontSize: 14),
              items: const [
                DropdownMenuItem(
                    value: '',
                    child: Text('Otomatis (bergilir)',
                        overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(
                    value: 'gold',
                    child: Text('Gold — Early Bird',
                        overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(
                    value: 'emerald',
                    child: Text('Emerald — Member',
                        overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(
                    value: 'amethyst',
                    child: Text('Amethyst — Eksklusif',
                        overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(
                    value: 'silver',
                    child: Text('Silver — Platinum',
                        overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(
                    value: 'red',
                    child: Text('Red — LiveVibes',
                        overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _tema = v ?? ''),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minPembelianCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        _input('Min. Pembelian', prefix: 'Rp ', hint: '0'),
                    style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary, fontSize: 14),
                    // Tanpa validator, kolom kosong membuat `double.parse('')`
                    // melempar FormatException saat menyimpan — tombol Simpan
                    // tampak tidak bereaksi apa pun.
                    validator: (v) {
                      final teks = (v ?? '').trim();
                      if (teks.isEmpty) return null; // kosong = tanpa minimum
                      final n = double.tryParse(teks);
                      if (n == null) return 'Masukkan angka yang valid';
                      if (n < 0) return 'Minimum tidak boleh negatif';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxPakaiCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _input('Maks. Pakai', hint: '100'),
                    style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary, fontSize: 14),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Angka tidak valid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Masa berlaku dipecah dua field supaya nilainya terlihat jelas.
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _mulaiCtrl,
                    readOnly: true,
                    onTap: () => _pilihTanggal(mulai: true),
                    decoration: _input('Berlaku Mulai', hint: 'Pilih tanggal'),
                    style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _akhirCtrl,
                    readOnly: true,
                    onTap: () => _pilihTanggal(mulai: false),
                    decoration: _input('Berlaku Akhir', hint: 'Pilih tanggal'),
                    style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _deskripsiCtrl,
              maxLines: 2,
              decoration: _input('Deskripsi (opsional)'),
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _buatPromo,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.warnaTombolTeks),
                      )
                    : const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  _saving ? 'Menyimpan...' : 'Buat Promo',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.rMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('promo_codes')
          .orderBy('berlakuMulai', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.aksi),
            ),
          );
        }
        if (snapshot.hasError) {
          return Text('Gagal memuat promo: ${snapshot.error}',
              style: GoogleFonts.spaceGrotesk(color: AppColors.error));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Belum ada kode promo terdaftar',
                style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted),
              ),
            ),
          );
        }
        return Column(
          children: docs.map((doc) {
            final promo =
                PromoCodeModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            return _buildPromoCard(promo);
          }).toList(),
        );
      },
    );
  }

  Widget _buildPromoCard(PromoCodeModel promo) {
    // AKTIF = hijau (status berhasil), BERAKHIR = sunset (perlu tindakan),
    // NONAKTIF = redup.
    //
    // Hijau di sini bukan "uang", melainkan "berhasil/berlaku" — dua makna
    // yang sama-sama positif dan sudah disepakati memakai hijau. Navigasi
    // tetap putih.
    final statusColor = promo.isValid
        ? AppColors.primary
        : (promo.aktif ? AppColors.warning : AppColors.textMuted);
    final statusLabel = promo.isValid
        ? 'AKTIF'
        : (promo.aktif ? 'BERAKHIR' : 'NONAKTIF');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  promo.kode,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: AppRadius.rSm,
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.spaceGrotesk(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                promo.labelNilai,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.aksi,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${promo.tipe == 'percentage' ? 'Persentase' : 'Tetap'} • '
                'Terpakai ${promo.sudahDipakai}/${promo.maxPakai}',
                style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (promo.minPembelian > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Min. pembelian ${_formatRupiah(promo.minPembelian)}',
                style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          Text(
            'Berlaku ${_formatTanggal(promo.berlakuMulai)} - ${_formatTanggal(promo.berlakuAkhir)}',
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary, fontSize: 12),
          ),
          if (promo.deskripsi != null && promo.deskripsi!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              promo.deskripsi!,
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: promo.aktif ? () => _nonaktifkanPromo(promo) : null,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(
                'Nonaktifkan',
                style: GoogleFonts.spaceGrotesk(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
