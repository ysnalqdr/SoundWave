import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../models/tiket_konser_model.dart';
import '../../models/konser_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/gambar_widget.dart';

class FormTiketScreen extends ConsumerStatefulWidget {
  final TiketKonserModel? tiket;

  const FormTiketScreen({super.key, this.tiket});

  @override
  ConsumerState<FormTiketScreen> createState() => _FormTiketScreenState();
}

class _FormTiketScreenState extends ConsumerState<FormTiketScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _hargaCtrl;
  late final TextEditingController _stokCtrl;
  late final TextEditingController _deskripsiCtrl;

  late String _kategoriPilihan;
  KonserModel? _konserDipilih;

  bool _sedangSimpan = false;
  bool _konserInitialized = false;

  bool get _modeEdit => widget.tiket != null;

  @override
  void initState() {
    super.initState();

    final t = widget.tiket;
    _hargaCtrl = TextEditingController(
      text: t != null ? t.harga.toStringAsFixed(0) : '',
    );
    _stokCtrl = TextEditingController(
      text: t != null ? t.stok.toString() : '',
    );
    _deskripsiCtrl = TextEditingController(text: t?.deskripsi ?? '');
    _kategoriPilihan = t?.kategori ?? AppConstants.ticketCategories.first;
  }

  @override
  void dispose() {
    _hargaCtrl.dispose();
    _stokCtrl.dispose();
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_konserDipilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pilih konser terlebih dahulu',
            style: GoogleFonts.spaceGrotesk(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _sedangSimpan = true);

    try {
      final db = ref.read(databaseServiceProvider);

      if (_modeEdit) {
        await db.updateTicket(
          widget.tiket!.id,
          {
            'idKonser': _konserDipilih!.id,
            'judulKonser': _konserDipilih!.judul,
            'gambarKonser': _konserDipilih!.gambarUrl,
            'kategori': _kategoriPilihan,
            'harga': double.tryParse(_hargaCtrl.text) ?? 0,
            'stok': int.tryParse(_stokCtrl.text) ?? 0,
            'deskripsi': _deskripsiCtrl.text.trim(),
          },
        );
      } else {
        final tiketBaru = TiketKonserModel(
          id: '',
          idKonser: _konserDipilih!.id,
          judulKonser: _konserDipilih!.judul,
          gambarKonser: _konserDipilih!.gambarUrl,
          kategori: _kategoriPilihan,
          harga: double.tryParse(_hargaCtrl.text) ?? 0,
          stok: int.tryParse(_stokCtrl.text) ?? 0,
          deskripsi: _deskripsiCtrl.text.trim(),
        );
        await db.createTicket(tiketBaru);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sedangSimpan = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan tiket: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _modeEdit ? 'EDIT TIKET' : 'TAMBAH TIKET BARU',
          style: GoogleFonts.rajdhani(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _labelField('Konser *'),
              const SizedBox(height: 8),
              eventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        'Belum ada event di Firestore. Buat event terlebih dahulu.',
                        style: GoogleFonts.spaceGrotesk(color: AppColors.warning),
                      ),
                    );
                  }

                  if (!_konserInitialized) {
                    if (widget.tiket != null) {
                      _konserDipilih = events.firstWhere(
                        (k) => k.id == widget.tiket!.idKonser,
                        orElse: () => events.first,
                      );
                    } else {
                      _konserDipilih = events.first;
                    }
                    _konserInitialized = true;
                  }

                  // Pastikan _konserDipilih referensinya ada di list
                  final matching = events.where((k) => k.id == _konserDipilih?.id).toList();
                  final selectedValue = matching.isNotEmpty ? matching.first : events.first;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<KonserModel>(
                        value: selectedValue,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                        items: events
                            .map(
                              (k) => DropdownMenuItem(
                                value: k,
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: GambarWidget(
                                        url: k.gambarUrl,
                                        width: 36,
                                        height: 36,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        k.judul,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() => _konserDipilih = val);
                        },
                      ),
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text(
                  'Gagal memuat event: $e',
                  style: GoogleFonts.spaceGrotesk(color: AppColors.error),
                ),
              ),

              const SizedBox(height: 16),

              _labelField('Kategori Tiket *'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _kategoriPilihan,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    items: {
                      ...AppConstants.ticketCategories,
                      if (_kategoriPilihan.isNotEmpty) _kategoriPilihan,
                    }
                        .map(
                          (kat) => DropdownMenuItem(
                            value: kat,
                            child: Row(
                              children: [
                                Text(kat),
                                if (kat == 'VVIP') ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '(Front Row + Lounge)',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: AppColors.warnaHarga,
                                      fontSize: 11,
                                    ),
                                  ),
                                ] else if (kat == 'VIP') ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '(Center Stage + Seating)',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: const Color(0xFFFF9100),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _kategoriPilihan = val);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _labelField('Harga Tiket (Rp) *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _hargaCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Contoh: 500000',
                  hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.textMuted),
                  prefixIcon: const Icon(
                    Icons.monetization_on_outlined,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Harga wajib diisi';
                  }
                  if (double.tryParse(val.trim()) == null) {
                    return 'Harga harus berupa angka';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _labelField('Jumlah Stok Tiket *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _stokCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Contoh: 100',
                  hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.textMuted),
                  prefixIcon: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Stok wajib diisi';
                  }
                  if (int.tryParse(val.trim()) == null) {
                    return 'Stok harus berupa bilangan bulat';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _labelField('Deskripsi / Benefit Tiket'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deskripsiCtrl,
                maxLines: 3,
                style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Contoh: Free merchandise, Akses gate VIP...',
                  hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _sedangSimpan ? null : _simpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceLight,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.warnaHarga, width: 1.5),
                    ),
                  ),
                  icon: _sedangSimpan
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.warnaHarga,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.save_rounded,
                          color: AppColors.warnaHarga,
                        ),
                  label: Text(
                    _modeEdit ? 'Perbarui Tiket' : 'Simpan Tiket',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labelField(String teks) {
    return Text(
      teks,
      style: GoogleFonts.spaceGrotesk(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}