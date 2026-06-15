import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../models/konser_model.dart';
import '../../data/dummy_data.dart';
import '../../widgets/gambar_widget.dart';

class FormKonserScreen extends StatefulWidget {
  final KonserModel? konser;

  const FormKonserScreen({super.key, this.konser});

  @override
  State<FormKonserScreen> createState() => _FormKonserScreenState();
}

class _FormKonserScreenState extends State<FormKonserScreen> {
  final _formKey = GlobalKey<FormState>();

  //!Field Ctrl
  late final TextEditingController _judulCtrl;
  late final TextEditingController _lokasiCtrl;
  late final TextEditingController _hargaCtrl;
  late final TextEditingController _gambarCtrl;
  late final TextEditingController _deskripsiCtrl;
  late final TextEditingController _penyelenggaraCtrl;

  List<String> _genreTerpilih = [];
  bool _sedangSimpan = false;

  //!Mod Edit/Tambah
  bool get _modeEdit => widget.konser != null;

  @override
  void initState() {
    super.initState();

    final k = widget.konser;
    _judulCtrl = TextEditingController(text: k?.judul ?? '');
    _lokasiCtrl = TextEditingController(text: k?.lokasi ?? '');
    _hargaCtrl = TextEditingController(
      text: k != null ? k.harga.toStringAsFixed(0) : '',
    );
    _gambarCtrl = TextEditingController(text: k?.gambarUrl ?? '');
    _deskripsiCtrl = TextEditingController(text: k?.deskripsi ?? '');
    _penyelenggaraCtrl = TextEditingController(text: k?.penyelenggara ?? '');

    if (k != null && k.genre.isNotEmpty) {
      _genreTerpilih = List.from(k.genre);
    } else {
      _genreTerpilih = [];
    }

    _tanggalPilihan = k?.tanggal ??
        DateTime.now().add(
          const Duration(days: 30),
        );
  }

  late DateTime _tanggalPilihan;

  @override
  void dispose() {
    _judulCtrl.dispose();
    _lokasiCtrl.dispose();
    _hargaCtrl.dispose();
    _gambarCtrl.dispose();
    _deskripsiCtrl.dispose();
    _penyelenggaraCtrl.dispose();
    super.dispose();
  }

  //! Open Data Picker
  Future<void> _pilihTanggal() async {
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggalPilihan,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.white, // Dipaksa putih agar senada
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (hasil != null) {
      setState(() => _tanggalPilihan = hasil);
    }
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;

    if (_genreTerpilih.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu genre terlebih dahulu!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _sedangSimpan = true);

    if (_modeEdit) {
      final index = DummyData.daftarKonser.indexWhere(
        (k) => k.id == widget.konser!.id,
      );
      if (index != -1) {
        DummyData.daftarKonser[index] = widget.konser!.copyWith(
          judul: _judulCtrl.text.trim(),
          lokasi: _lokasiCtrl.text.trim(),
          tanggal: _tanggalPilihan,
          harga: double.tryParse(_hargaCtrl.text) ?? 0,
          genre: _genreTerpilih,
          gambarUrl: _gambarCtrl.text.trim(),
          deskripsi: _deskripsiCtrl.text.trim(),
          penyelenggara: _penyelenggaraCtrl.text.trim(),
        );
      }
    } else {
      DummyData.daftarKonser.add(
        KonserModel(
          id: DummyData.buatId(),
          judul: _judulCtrl.text.trim(),
          lokasi: _lokasiCtrl.text.trim(),
          tanggal: _tanggalPilihan,
          harga: double.tryParse(_hargaCtrl.text) ?? 0,
          genre: _genreTerpilih,
          gambarUrl: _gambarCtrl.text.trim(),
          deskripsi: _deskripsiCtrl.text.trim(),
          penyelenggara: _penyelenggaraCtrl.text.trim(),
        ),
      );
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _modeEdit ? 'Edit Konser' : 'Tambah Konser',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_gambarCtrl.text.isNotEmpty)
                Container(
                  height: 160,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: GambarWidget(
                    url: _gambarCtrl.text,
                    width: double.infinity,
                    height: 160,
                    ikonDefault: Icons.broken_image_outlined,
                  ),
                ),

              _labelField('Judul Konser'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _judulCtrl,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Contoh: Coldplay • Music of the Spheres',
                  prefixIcon: Icon(
                    Icons.title_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Judul wajib diisi' : null,
              ),

              const SizedBox(height: 16),

              _labelField('Lokasi'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lokasiCtrl,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Contoh: Gelora Bung Karno, Jakarta',
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Lokasi wajib diisi' : null,
              ),

              const SizedBox(height: 16),

              _labelField('Harga Tiket (Rp)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _hargaCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.spaceGrotesk(
                  // KUNCI 1: Menggunakan warnaHarga dari tema agar otomatis menyala hijau neon menonjol!
                  color: AppColors.warnaHarga,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  hintText: 'Contoh: 850000',
                  prefixIcon: Icon(
                    Icons.attach_money_rounded,
                    color: AppColors
                        .warnaHarga, // Icon dollar juga ikut menyala hijau neon
                    size: 20,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Harga wajib diisi';
                  if (double.tryParse(v) == null) return 'Masukkan angka';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _labelField('Genre'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: AppConstants.genres.map((g) {
                    final isChecked = _genreTerpilih.contains(g);

                    return Theme(
                      data: ThemeData.dark().copyWith(
                        unselectedWidgetColor: AppColors.textMuted,
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          g,
                          style: GoogleFonts.spaceGrotesk(
                            // KUNCI 2: Jika dipilih, teks menyala mengikuti warnaHarga (Hijau Neon)
                            color: isChecked
                                ? AppColors.warnaHarga
                                : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight:
                                isChecked ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        value: isChecked,
                        activeColor: Colors.transparent,
                        checkColor:
                            AppColors.warnaHarga, // Warna centang hijau neon
                        controlAffinity: ListTileControlAffinity.trailing,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              if (!_genreTerpilih.contains(g)) {
                                _genreTerpilih.add(g);
                              }
                            } else {
                              _genreTerpilih.remove(g);
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              _labelField('Tanggal'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pilihTanggal,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_tanggalPilihan.day}/${_tanggalPilihan.month}/${_tanggalPilihan.year}',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _labelField('URL Gambar'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _gambarCtrl,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'https://...',
                  prefixIcon: Icon(
                    Icons.image_outlined,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 16),

              _labelField('Penyelenggara'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _penyelenggaraCtrl,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Contoh: Live Nation Indonesia',
                  prefixIcon: Icon(
                    Icons.business_outlined,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _labelField('Deskripsi'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deskripsiCtrl,
                maxLines: 4,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Ceritakan detail konser ini...',
                  hintStyle: GoogleFonts.spaceGrotesk(
                    color: AppColors.textMuted,
                    fontSize: 14,
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
              ),

              const SizedBox(height: 32),

              //! KUNCI 3: Tombol bawaanmu di-render pakai skema warna baru (Putih-Hitam)
              //! TOMBOL: Di-set manual warna abu-abu dengan teks putih
              //! TOMBOL: Sudah diperbaiki bagian border-nya menggunakan properti 'side'
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _sedangSimpan ? null : _simpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.surfaceLight, // Warna abu-abu gelap
                    foregroundColor: Colors.white, // Teks & ikon warna putih
                    disabledBackgroundColor:
                        AppColors.surfaceLight.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      // KUNCI PERBAIKAN: Pakai 'side', bukan 'border'
                      side: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                  icon: _sedangSimpan
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.save_rounded,
                          color: Colors.white,
                        ),
                  label: Text(
                    _modeEdit ? 'Perbarui Konser' : 'Simpan Konser',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
