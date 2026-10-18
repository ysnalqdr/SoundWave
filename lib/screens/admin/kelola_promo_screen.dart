import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/promo_model.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';

/// Admin screen untuk mengelola kode promo.
/// Form di atas untuk membuat promo baru, list di bawah menampilkan
/// seluruh promo dari koleksi Firestore `promo_codes`.
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
  final _mulaiCtrl = TextEditingController();
  final _akhirCtrl = TextEditingController();

  String _tipe = 'percentage';
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

  /// Pilih satu tanggal (mulai / akhir) via date picker sederhana.
  /// Dipisah 2 field agar nilainya jelas terlihat & pasti tersimpan.
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
                primary: AppColors.primary,
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
        // Jika akhir sudah dipilih tapi jadi lebih awal, kosongkan agar valid.
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

    setState(() => _saving = true);
    try {
      final promo = PromoCodeModel(
        id: '',
        kode: _kodeCtrl.text.trim().toUpperCase(),
        tipe: _tipe,
        nilai: double.parse(_nilaiCtrl.text.trim()),
        minPembelian: _minPembelianCtrl.text.trim().isEmpty
            ? 0
            : double.parse(_minPembelianCtrl.text.trim()),
        maxPakai: int.parse(_maxPakaiCtrl.text.trim()),
        berlakuMulai: DateTime(
            _berlakuMulai!.year, _berlakuMulai!.month, _berlakuMulai!.day),
        // Simpan akhir hari agar promo tetap valid sampai habis hari terakhir.
        berlakuAkhir: DateTime(_berlakuAkhir!.year, _berlakuAkhir!.month,
            _berlakuAkhir!.day, 23, 59, 59),
        deskripsi: _deskripsiCtrl.text.trim().isEmpty
            ? null
            : _deskripsiCtrl.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('promo_codes')
          .add(promo.toMap());

      _resetForm();
      _toast('Promo berhasil dibuat', AppColors.success);
    } catch (e) {
      _toast('Gagal membuat promo: $e', AppColors.error);
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
    _mulaiCtrl.clear();
    _akhirCtrl.clear();
    setState(() {
      _tipe = 'percentage';
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
      _toast('Gagal menonaktifkan: $e', AppColors.error);
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
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
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
              'DAFTAR KODE PROMO',
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
        borderRadius: BorderRadius.circular(16),
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
                    color: AppColors.warnaHarga, size: 22),
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
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Nilai tidak valid';
                      return null;
                    },
                  ),
                ),
              ],
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
            // Masa berlaku: 2 field terpisah agar nilainya jelas terlihat
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
                  backgroundColor: AppColors.warnaTombolBg,
                  foregroundColor: AppColors.warnaTombolTeks,
                  minimumSize: const Size.fromHeight(50),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
              child: CircularProgressIndicator(color: AppColors.primary),
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
    final statusColor = promo.isValid
        ? AppColors.success
        : (promo.aktif ? AppColors.warning : AppColors.textMuted);
    final statusLabel = promo.isValid
        ? 'AKTIF'
        : (promo.aktif ? 'BERAKHIR' : 'NONAKTIF');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
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
                  borderRadius: BorderRadius.circular(8),
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
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.warnaHarga,
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
