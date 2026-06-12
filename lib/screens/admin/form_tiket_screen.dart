import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../models/tiket_konser_model.dart';
import '../../models/konser_model.dart';
import '../../data/dummy_data.dart';
import '../../widgets/gambar_widget.dart';

class FormTiketScreen extends StatefulWidget {
  final TiketKonserModel? tiket;

  const FormTiketScreen({super.key, this.tiket});

  @override
  State<FormTiketScreen> createState() => _FormTiketScreenState();
}

class _FormTiketScreenState extends State<FormTiketScreen> {

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _hargaCtrl;
  late final TextEditingController _stokCtrl;
  late final TextEditingController _deskripsiCtrl;

  late String _kategoriPilihan;
  KonserModel? _konserDipilih;

  bool _sedangSimpan = false;

  bool get _modeEdit => widget.tiket != null;

  @override
  void initState() {
    super.initState();

    final t = widget.tiket;
    _hargaCtrl     = TextEditingController(
      text: t != null ? t.harga.toStringAsFixed(0) : '',
    );
    _stokCtrl      = TextEditingController(
      text: t != null ? t.stok.toString() : '',
    );
    _deskripsiCtrl = TextEditingController(text: t?.deskripsi ?? '');
    _kategoriPilihan = t?.kategori ?? AppConstants.ticketCategories.first;

    //!Search Mode Edit(Disesuaiin)
    if (t != null) {
      _konserDipilih = DummyData.daftarKonser.firstWhere(
        (k) => k.id == t.idKonser,
        orElse: () => DummyData.daftarKonser.first,
      );
    } else {
      //! Mode Tambah (Frist Pick Konser Default)
      if (DummyData.daftarKonser.isNotEmpty) {
        _konserDipilih = DummyData.daftarKonser.first;
      }
    }
  }

  @override
  void dispose() {
    _hargaCtrl.dispose();
    _stokCtrl.dispose();
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  void _simpan() {
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

    if (_modeEdit) {
      //! Area update
      final index = DummyData.daftarTiket.indexWhere(
        (t) => t.id == widget.tiket!.id,
      );
      if (index != -1) {
        DummyData.daftarTiket[index] = widget.tiket!.copyWith(
          idKonser     : _konserDipilih!.id,
          judulKonser  : _konserDipilih!.judul,
          gambarKonser : _konserDipilih!.gambarUrl,
          kategori     : _kategoriPilihan,
          harga        : double.tryParse(_hargaCtrl.text) ?? 0,
          stok         : int.tryParse(_stokCtrl.text) ?? 0,
          deskripsi    : _deskripsiCtrl.text.trim(),
        );
      }
    } else {
      //! Area Create
      DummyData.daftarTiket.add(
        TiketKonserModel(
          id           : DummyData.buatId(),
          idKonser     : _konserDipilih!.id,
          judulKonser  : _konserDipilih!.judul,
          gambarKonser : _konserDipilih!.gambarUrl,
          kategori     : _kategoriPilihan,
          harga        : double.tryParse(_hargaCtrl.text) ?? 0,
          stok         : int.tryParse(_stokCtrl.text) ?? 0,
          deskripsi    : _deskripsiCtrl.text.trim(),
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
          _modeEdit ? 'Edit Tiket' : 'Tambah Tiket',
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

              //TODO Field Konser
              _labelField('Konser *'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<KonserModel>(
                    value: _konserDipilih,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    items: DummyData.daftarKonser
                        .map(
                          (k) => DropdownMenuItem(
                            value: k,
                            child: Row(
                              children: [
                                // Gambar kecil konser di dropdown
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
              ),

              const SizedBox(height: 16),

              //TODO: Field Katagori
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
                    items: AppConstants.ticketCategories
                        .map(
                          (k) => DropdownMenuItem(
                            value: k,
                            child: Text(k),
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

              //TODO Harg Stok
              Row(
                children: [
                  //!Harga
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _labelField('Harga (Rp) *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _hargaCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: '850000',
                            prefixIcon: Icon(
                              Icons.attach_money_rounded,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                          ),
                          // Update preview saat ketik
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Wajib diisi';
                            }
                            if (double.tryParse(v) == null) {
                              return 'Angka saja';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stok
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _labelField('Stok *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _stokCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: '100',
                            prefixIcon: Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Wajib diisi';
                            }
                            if (int.tryParse(v) == null) {
                              return 'Angka saja';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              //TODO: Preview Harga RT
              if (_hargaCtrl.text.isNotEmpty &&
                  double.tryParse(_hargaCtrl.text) != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.confirmation_number_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Preview: ',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        // Format harga realtime
                        'Rp ${double.parse(_hargaCtrl.text).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                        style: GoogleFonts.rajdhani(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              //TODO: Deskripsi
              _labelField('Deskripsi Tiket'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deskripsiCtrl,
                maxLines: 3,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Fasilitas, area, benefit tiket...',
                  hintStyle: GoogleFonts.spaceGrotesk(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
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

              //TODO Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, Color(0xFFFF4F8B)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _sedangSimpan ? null : _simpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
                      _modeEdit ? 'Perbarui Tiket' : 'Simpan Tiket',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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