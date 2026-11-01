import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../models/konser_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/gambar_widget.dart';
import '../../widgets/media/audio_picker_field.dart';
import '../../widgets/media/video_picker_field.dart';
import '../../widgets/media/venue_model_picker_field.dart';
import '../../models/event_media_model.dart';
import '../../core/errors/pesan_galat.dart';

class FormKonserScreen extends ConsumerStatefulWidget {
  final KonserModel? konser;

  const FormKonserScreen({super.key, this.konser});

  @override
  ConsumerState<FormKonserScreen> createState() => _FormKonserScreenState();
}

class _FormKonserScreenState extends ConsumerState<FormKonserScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _judulCtrl;
  late final TextEditingController _venueCtrl;
  late final TextEditingController _hargaCtrl;
  late final TextEditingController _gambarCtrl;
  late final TextEditingController _deskripsiCtrl;
  late final TextEditingController _penyelenggaraCtrl;

  late String _selectedKota;
  List<String> _genreTerpilih = [];
  bool _sedangSimpan = false;
  EventMedia _media = EventMedia.empty;

  bool get _modeEdit => widget.konser != null;

  static const List<Map<String, String>> _presetPosters = [
    {
      'label': 'Rock Stage',
      'url': 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=800',
    },
    {
      'label': 'Electronic EDM',
      'url': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=800',
    },
    {
      'label': 'Jazz Night',
      'url': 'https://images.unsplash.com/photo-1511192336575-5a79af67a629?w=800',
    },
    {
      'label': 'Pop Festival',
      'url': 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800',
    },
    {
      'label': 'Indie Stage',
      'url': 'https://images.unsplash.com/photo-1465847899084-d164df4dedc6?w=800',
    },
  ];

  @override
  void initState() {
    super.initState();

    final k = widget.konser;
    _judulCtrl = TextEditingController(text: k?.judul ?? '');

    String initKota = AppConstants.cities.first;
    String initVenue = '';
    if (k != null && k.lokasi.isNotEmpty) {
      for (final city in AppConstants.cities) {
        if (k.lokasi.toLowerCase().contains(city.toLowerCase())) {
          initKota = city;
          break;
        }
      }
      initVenue = k.lokasi.replaceAll(RegExp(',\\s*$initKota', caseSensitive: false), '').trim();
      if (initVenue.isEmpty) initVenue = k.lokasi;
    }
    _selectedKota = initKota;
    _venueCtrl = TextEditingController(text: initVenue);

    _hargaCtrl = TextEditingController(
      text: k != null ? k.harga.toStringAsFixed(0) : '',
    );
    _gambarCtrl = TextEditingController(text: k?.gambarUrl ?? '');
    _deskripsiCtrl = TextEditingController(text: k?.deskripsi ?? '');
    _penyelenggaraCtrl = TextEditingController(text: k?.penyelenggara ?? '');

    _media = k?.media ?? EventMedia.empty;

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
    _venueCtrl.dispose();
    _hargaCtrl.dispose();
    _gambarCtrl.dispose();
    _deskripsiCtrl.dispose();
    _penyelenggaraCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggalPilihan,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.aksi,
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

  Future<void> _simpan() async {
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

    final venueName = _venueCtrl.text.trim();
    final lokasiLengkap = venueName.isEmpty ? _selectedKota : '$venueName, $_selectedKota';

    try {
      final db = ref.read(databaseServiceProvider);

      if (_modeEdit) {
        await db.updateEvent(
          widget.konser!.id,
          {
            'judul': _judulCtrl.text.trim(),
            'lokasi': lokasiLengkap,
            'tanggal': _tanggalPilihan,
            'harga': double.tryParse(_hargaCtrl.text) ?? 0,
            'genre': _genreTerpilih,
            'gambarUrl': _gambarCtrl.text.trim(),
            'deskripsi': _deskripsiCtrl.text.trim(),
            'penyelenggara': _penyelenggaraCtrl.text.trim(),
            'media': _media.toMap(),
          },
        );
      } else {
        final konserBaru = KonserModel(
          id: '',
          judul: _judulCtrl.text.trim(),
          lokasi: lokasiLengkap,
          tanggal: _tanggalPilihan,
          harga: double.tryParse(_hargaCtrl.text) ?? 0,
          genre: _genreTerpilih,
          gambarUrl: _gambarCtrl.text.trim(),
          deskripsi: _deskripsiCtrl.text.trim(),
          penyelenggara: _penyelenggaraCtrl.text.trim(),
          media: _media,
        );
        await db.createEvent(konserBaru);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sedangSimpan = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(PesanGalat.untuk(e, awalan: 'Gagal menyimpan konser')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _modeEdit ? 'EDIT KONSER' : 'TAMBAH KONSER BARU',
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
              _labelField('Judul Konser'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _judulCtrl,
                decoration: const InputDecoration(
                  hintText: 'Contoh: SoundWave Festival 2026',
                  prefixIcon: Icon(Icons.music_note_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Kota dan venue disimpan terstruktur.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _labelField('Kota'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: AppConstants.cities.contains(_selectedKota)
                              ? _selectedKota
                              : AppConstants.cities.first,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                          dropdownColor: AppColors.surface,
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                          items: AppConstants.cities.map((city) {
                            return DropdownMenuItem(
                              value: city,
                              child: Text(
                                city,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedKota = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _labelField('Nama Venue / Tempat'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _venueCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Contoh: Gelora Bung Karno',
                            prefixIcon: Icon(Icons.place_outlined),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Venue wajib diisi' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _labelField('Tanggal Konser'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pilihTanggal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.rMd,
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined,
                          color: AppColors.textMuted, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${_tanggalPilihan.day}/${_tanggalPilihan.month}/${_tanggalPilihan.year}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _labelField('Harga Tiket Mulai Dari (Rp)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _hargaCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Contoh: 350000',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Harga wajib diisi';
                  final n = double.tryParse(v.trim());
                  if (n == null) return 'Masukkan angka yang valid';
                  // Tanpa batas bawah, harga negatif atau nol lolos dan
                  // tersimpan apa adanya. Harga nol membuat tiket gratis
                  // tanpa disengaja; harga negatif membuat total di checkout
                  // ikut negatif dan Midtrans menolak transaksi.
                  if (n <= 0) return 'Harga harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _labelField('Penyelenggara / Promotor'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _penyelenggaraCtrl,
                decoration: const InputDecoration(
                  hintText: 'Contoh: SoundWave Live Inc.',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Penyelenggara wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),

              // Poster dari preset atau URL. Tidak ada unggah berkas, karena
              // Storage tidak tersedia di paket Spark.
              _labelField('Sumber Gambar Poster (Bebas Biaya / HTTPS Link)'),
              const SizedBox(height: 6),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presetPosters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final preset = _presetPosters[i];
                    final isSelected = _gambarCtrl.text.trim() == preset['url'];
                    return ActionChip(
                      label: Text(preset['label']!),
                      backgroundColor: isSelected ? AppColors.aksi : AppColors.surfaceLight,
                      labelStyle: GoogleFonts.spaceGrotesk(
                        color: isSelected ? Colors.black : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.aksi : AppColors.divider,
                      ),
                      onPressed: () {
                        setState(() {
                          _gambarCtrl.text = preset['url']!;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _gambarCtrl,
                decoration: const InputDecoration(
                  hintText: 'Pilih preset di atas atau paste URL gambar https://...',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'URL gambar poster wajib diisi'
                    : null,
              ),
              if (_gambarCtrl.text.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: AppRadius.rSm,
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: GambarWidget(
                      url: _gambarCtrl.text.trim(),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              _labelField('Audio Pratinjau'),
              const SizedBox(height: 6),
              AudioPickerField(
                media: _media,
                onChanged: (m) => setState(() => _media = m),
              ),
              const SizedBox(height: 16),

              _labelField('Trailer Video'),
              const SizedBox(height: 6),
              VideoPickerField(
                media: _media,
                onChanged: (m) => setState(() => _media = m),
              ),
              const SizedBox(height: 16),

              _labelField('Panggung 3D'),
              const SizedBox(height: 6),
              VenueModelPickerField(
                media: _media,
                onChanged: (m) => setState(() => _media = m),
              ),
              const SizedBox(height: 16),

              _labelField('Deskripsi Acara'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _deskripsiCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Tuliskan deskripsi lengkap konser...',
                  alignLabelWithHint: true,
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Deskripsi wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),

              _labelField('Genre Musik (Bisa pilih lebih dari satu)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.genres.map((g) {
                  final dipilih = _genreTerpilih.contains(g);
                  return FilterChip(
                    label: Text(g),
                    selected: dipilih,
                    selectedColor: AppColors.aksi,
                    checkmarkColor: Colors.black,
                    labelStyle: GoogleFonts.spaceGrotesk(
                      color: dipilih ? Colors.black : AppColors.textSecondary,
                      fontWeight: dipilih ? FontWeight.w700 : FontWeight.normal,
                    ),
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.rSm,
                      side: BorderSide(
                        color: dipilih ? AppColors.aksi : AppColors.divider,
                      ),
                    ),
                    onSelected: (aktif) {
                      setState(() {
                        if (aktif) {
                          _genreTerpilih.add(g);
                        } else {
                          _genreTerpilih.remove(g);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sedangSimpan ? null : _simpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceLight,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.rMd,
                      side: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                  icon: _sedangSimpan
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.onAksi,
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
