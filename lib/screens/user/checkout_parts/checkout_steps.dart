part of '../checkout_screen.dart';

/// Tiga langkah utama wizard, konfirmasi, bilah bawah, dan layar sukses.
///
/// Dipisahkan dari `checkout_screen.dart` agar berkas utama tidak lagi
/// menampung seluruh layar checkout. Perilaku tidak berubah: mixin ini
/// berada dalam library yang sama (`part of`) dan di-`with` oleh state,
/// sehingga tetap dapat mengakses field, method, serta `setState`.
mixin _CheckoutSteps on _CheckoutBase {
  @override
  Widget _buildStep1Methods() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Metode Pembayaran',
            style: GoogleFonts.rajdhani(
              color: SwCheckout.ink,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih cara pembayaran yang paling nyaman untuk kamu.',
            style: GoogleFonts.spaceGrotesk(color: SwCheckout.sub, fontSize: 13),
          ),
          const SizedBox(height: 24),
          if (_lanjut) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: AppRadius.rMd,
                border: Border.all(color: AppColors.warningBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.swap_horiz_rounded,
                      color: AppColors.warningStrong, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Metode baru akan membuat instrumen pembayaran baru. '
                      'Nomor VA / QR lama tidak dipakai lagi untuk pesanan ini.',
                      style: GoogleFonts.spaceGrotesk(
                          color: SwCheckout.sub, fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildConcertSummary(),
          const SizedBox(height: 20),
          ...kPaymentMethods.map((m) => _buildMethodCard(m)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget _buildMethodCard(PaymentMethod m) {
    final selected = _selectedMethod == m.id;
    // Jangan pakai Colors.transparent di satu sisi border selama ada
    // borderRadius: Flutter menghitung transparan sebagai warna yang terlihat,
    // lalu melempar "A borderRadius can only be given on borders with uniform
    // colors" saat paint. Kartu tampak kosong karena isinya tidak pernah
    // digambar. Semua sisi wajib satu warna; lebar boleh berbeda.
    final Color borderColor =
        selected ? SwCheckout.aksi.withValues(alpha: 0.4) : SwCheckout.line;
    return GestureDetector(
      onTap: () => setState(() {
        if (_selectedMethod != m.id) {
          // Metode berganti: instrumen lama tidak dipakai lagi.
          _vaNumber = null;
          _vaBank = null;
          _billerCode = null;
          _qrString = null;
          _gopayPhone = null;
          _autoInstrumenDicoba = false;
        }
        _selectedMethod = m.id;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: SwCheckout.surface,
          borderRadius: AppRadius.rMd,
          border: Border(
            left: BorderSide(color: borderColor, width: 4),
            top: BorderSide(color: borderColor),
            right: BorderSide(color: borderColor),
            bottom: BorderSide(color: borderColor),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? SwCheckout.aksi.withValues(alpha: 0.12)
                    : SwCheckout.chip,
                borderRadius: AppRadius.rSm,
                border: Border.all(
                  color: selected ? SwCheckout.aksi : SwCheckout.line,
                ),
              ),
              child: Icon(m.icon,
                  color: selected ? SwCheckout.aksi : SwCheckout.sub, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.title,
                    style: GoogleFonts.spaceGrotesk(
                      color: SwCheckout.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      color: SwCheckout.sub,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? SwCheckout.aksi : Colors.transparent,
                border: Border.all(
                  color: selected ? SwCheckout.aksi : SwCheckout.muted,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: SwCheckout.btnFg)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget _buildConcertSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SwCheckout.chip,
        borderRadius: AppRadius.rMd,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.rSm,
            child: SizedBox(
              width: 56,
              height: 56,
              child:
                  GambarWidget(url: widget.konser.gambarUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.konser.judul,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.rajdhani(
                    color: SwCheckout.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _tiket.kategori,
                  style: GoogleFonts.spaceGrotesk(
                    color: SwCheckout.sub,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.konser.tanggal.day}/${widget.konser.tanggal.month}/${widget.konser.tanggal.year} · ${widget.konser.lokasi}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    color: SwCheckout.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget _buildStep2Form(String currentUserId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data pemesan.
          // Mode lanjut: data pemesan terkunci di pesanan, jadi tiga kolom
          // formulir readOnly hanya memanjangkan layar.
          if (_lanjut) ...[
            _buildKartuPemesanTerkunci(),
            const SizedBox(height: 6),
            _buildTautanGantiMetode(),
          ] else ...[
            _sectionTitle('Informasi Pemesan'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _namaCtrl,
              decoration:
                  _whiteInput('Nama Lengkap', icon: Icons.person_outline),
              style:
                  GoogleFonts.spaceGrotesk(color: SwCheckout.ink, fontSize: 14),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _whiteInput('Email Konfirmasi E-Tiket',
                  icon: Icons.email_outlined),
              style:
                  GoogleFonts.spaceGrotesk(color: SwCheckout.ink, fontSize: 14),
              validator: (v) =>
                  v == null || !v.contains('@') ? 'Email tidak valid' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _teleponCtrl,
              keyboardType: TextInputType.phone,
              decoration: _whiteInput('Nomor WhatsApp / HP',
                  icon: Icons.phone_outlined),
              style:
                  GoogleFonts.spaceGrotesk(color: SwCheckout.ink, fontSize: 14),
              validator: (v) => v == null || v.trim().length < 8
                  ? 'Nomor HP tidak valid'
                  : null,
            ),
          ],

          // Jumlah tiket.
          // Mode lanjut: jumlah tiket dan voucher terkunci ke pesanan asli.
          if (_lanjut) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _sectionTitle('Jumlah Tiket')),
                const SizedBox(width: 8),
                Text(
                  '$_jumlahTiket tiket',
                  style: GoogleFonts.rajdhani(
                    color: SwCheckout.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Jumlah tiket & data pemesan mengikuti pesanan '
              '${widget.orderLanjutan!.kodeBooking} yang sudah dibuat.',
              style:
                  GoogleFonts.spaceGrotesk(color: SwCheckout.muted, fontSize: 11),
            ),
          ] else ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _sectionTitle('Jumlah Tiket')),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: SwCheckout.chip,
                    borderRadius: AppRadius.rMd,
                    border: Border.all(color: SwCheckout.line),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Kurangi jumlah tiket',
                        onPressed: _jumlahTiket > 1
                            ? () => setState(() => _jumlahTiket--)
                            : null,
                        icon: const Icon(Icons.remove, size: 18),
                        color: SwCheckout.ink,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$_jumlahTiket',
                          style: GoogleFonts.spaceGrotesk(
                            color: SwCheckout.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Tambah jumlah tiket',
                        onPressed: _jumlahTiket < _maxTiket
                            ? () => setState(() => _jumlahTiket++)
                            : null,
                        icon: const Icon(Icons.add, size: 18),
                        color: SwCheckout.ink,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Maks. $_maxTiket tiket · Sisa stok: ${_tiket.stok}',
              style:
                  GoogleFonts.spaceGrotesk(color: SwCheckout.muted, fontSize: 11),
            ),
            const SizedBox(height: 22),
            _sectionTitle('Diskon / Voucher'),
            const SizedBox(height: 10),
            _buildVoucherPicker(),
          ],

          const SizedBox(height: 24),
          const Divider(color: SwCheckout.line, height: 1),
          const SizedBox(height: 20),

          if (_selectedMethod == 'va') ..._buildVaForm(currentUserId),
          if (_selectedMethod == 'card') ..._buildCardForm(),
          if (_selectedMethod == 'gopay') ..._buildGoPayForm(currentUserId),
          if (_selectedMethod == 'qris') ..._buildQrForm(currentUserId, 'qris'),
        ],
      ),
    );
  }

  @override
  Widget _buildStep3Confirm(String currentUserId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Konfirmasi Pesanan',
            style: GoogleFonts.rajdhani(
              color: SwCheckout.ink,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Periksa detail pesanan sebelum membayar.',
            style: GoogleFonts.spaceGrotesk(color: SwCheckout.sub, fontSize: 13),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SwCheckout.chip,
              borderRadius: AppRadius.rMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.rSm,
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: GambarWidget(
                            url: widget.konser.gambarUrl, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.konser.judul,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.rajdhani(
                              color: SwCheckout.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${widget.konser.tanggal.day}/${widget.konser.tanggal.month}/${widget.konser.tanggal.year}',
                            style: GoogleFonts.spaceGrotesk(
                                color: SwCheckout.muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: SwCheckout.line, height: 1),
                const SizedBox(height: 14),
                _confirmRow('Konser', widget.konser.judul),
                _confirmRow('Kategori Tiket', _tiket.kategori),
                _confirmRow('Jumlah', '$_jumlahTiket tiket'),
                _confirmRow('Metode', _methodLabel),
                if (_savedOrder != null && _savedOrder!.kodeBooking.isNotEmpty)
                  _confirmRow('Kode Booking', _savedOrder!.kodeBooking),
                const SizedBox(height: 14),
                const Divider(color: SwCheckout.line, height: 1),
                const SizedBox(height: 14),
                // Rincian diturunkan dari `RincianHarga` — rumus yang sama
                // dengan yang dipakai backend. Dulu barisnya ditulis manual
                // (Subtotal / Biaya Admin / Diskon), sehingga setiap kali
                // komponen baru ditambahkan, layar dan tagihan bisa berbeda.
                _confirmRow(
                    'Subtotal ($_jumlahTiket tiket)', _formatRupiah(_subtotal)),
                for (final b in _rincian.baris)
                  if (b.label != 'Harga tiket' && b.label != 'Total bayar') ...[
                    const SizedBox(height: 8),
                    _confirmRow(
                      b.label,
                      b.nilai < 0
                          ? '- ${_formatRupiah(b.nilai.abs().toDouble())}'
                          : _formatRupiah(b.nilai.toDouble()),
                    ),
                  ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL',
                      style: GoogleFonts.rajdhani(
                        color: SwCheckout.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      _formatRupiah(_totalTagih),
                      style: GoogleFonts.spaceGrotesk(
                        color: SwCheckout.greenDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_paymentDetected)
            _detectedBanner()
          else ...[
            Row(
              children: [
                const Icon(Icons.lock_outline, size: 14, color: SwCheckout.sub),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Dengan menekan BAYAR SEKARANG, kamu menyetujui Syarat & Ketentuan Soundwave.',
                    style: GoogleFonts.spaceGrotesk(
                        color: SwCheckout.muted, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tiketmu dikunci selama 15 menit. Selesaikan pembayaran sebelum waktu habis.',
              style:
                  GoogleFonts.spaceGrotesk(color: SwCheckout.muted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style:
                  GoogleFonts.spaceGrotesk(color: SwCheckout.sub, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.spaceGrotesk(
                  color: SwCheckout.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget _buildBottomBar(String currentUserId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(
        color: SwCheckout.bg,
        border: Border(top: BorderSide(color: SwCheckout.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Pembayaran',
                  style: GoogleFonts.spaceGrotesk(
                      color: SwCheckout.sub, fontSize: 12),
                ),
                Text(
                  _formatRupiah(_totalTagih),
                  style: GoogleFonts.rajdhani(
                    color: SwCheckout.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBottomButton(currentUserId),
          ],
        ),
      ),
    );
  }

  @override
  Widget _buildBottomButton(String currentUserId) {
    if (_currentStep == 0) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _selectedMethod == null ? null : _nextFromStep1,
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: SwCheckout.chip,
            disabledForegroundColor: SwCheckout.muted,
            minimumSize: const Size.fromHeight(52),
            shape:
                RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          ),
          child: Text(
            'Lanjut',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    if (_currentStep == 1) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _lanjut ? _keTiketSaya : () => _goToStep(0),
              style: OutlinedButton.styleFrom(
                foregroundColor: SwCheckout.ink,
                side: const BorderSide(color: SwCheckout.line),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.rMd),
              ),
              child: Text(
                _lanjut ? 'Ke Tiket Saya' : 'Kembali',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _nextFromStep2,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.rMd),
              ),
              child: Text(
                'Lanjut ke Konfirmasi',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : () => _bayarSekarang(currentUserId),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape:
              RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: SwCheckout.btnFg),
              )
            : Text(
                _paymentDetected ? 'Lihat E-Tiket' : 'BAYAR SEKARANG',
                style: GoogleFonts.rajdhani(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }


  /// Pengganti bila aset Lottie gagal dimuat (mis. korup atau tidak terbundel).
  /// Menjaga layar sukses tetap terbaca, bukan kotak kosong.
  @override
  Widget _successFallback() {
    return Center(
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: SwCheckout.green.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle,
          color: SwCheckout.green,
          size: 80,
        ),
      ),
    );
  }

  @override
  Widget _buildSuccessView() {
    return Scaffold(
      backgroundColor: SwCheckout.bg,
      appBar: AppBar(
        backgroundColor: SwCheckout.bg,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Pembayaran Berhasil',
          style: GoogleFonts.rajdhani(
            color: SwCheckout.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      // Layar sukses dulu memakai Column + Spacer dengan animasi 460x460.
      // Di layar 5" itu melebihi tinggi yang tersedia dan memicu
      // "BOTTOM OVERFLOWED BY 46 PIXELS". Sekarang isinya bisa digulir dan
      // animasi menyesuaikan lebar layar.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, batas) {
            // Animasi mengambil porsi tinggi yang tersedia, dibatasi agar
            // tidak mendominasi layar pendek.
            final sisiAnimasi = (batas.maxHeight * 0.42).clamp(160.0, 320.0);
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: batas.maxHeight),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Animasi Lottie menggantikan ikon centang statis. Aset ini
                    // sudah memuat lingkaran sukses + centang + burst confetti,
                    // jadi tidak perlu elemen tambahan di sekitarnya.
                    //
                    // Diulang selama layar terbuka. Asetnya berdurasi ~3
                    // detik; kalau hanya sekali, animasi berhenti dan layar
                    // terasa mati padahal pengguna masih membaca kode booking.
                    // Gerakannya halus (partikel, bukan kilatan), jadi aman
                    // diulang tanpa terasa mengganggu.
                    SizedBox(
                      width: sisiAnimasi,
                      height: sisiAnimasi,
                      child: Lottie.asset(
                        'assets/lottie/success_confetti.json',
                        repeat: true,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) =>
                            _successFallback(),
                      ),
                    ),
                    const SizedBox(height: 8),
              Text(
                'Transaksi Berhasil!',
                style: GoogleFonts.rajdhani(
                  color: SwCheckout.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _savedOrder != null
                    ? 'E-Tiket kamu sudah aktif. Kode booking: ${_savedOrder!.kodeBooking}'
                    : 'E-Tiket kamu sudah aktif dan siap digunakan.',
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.spaceGrotesk(color: SwCheckout.sub, fontSize: 14),
              ),
              const SizedBox(height: 20),
              if (_savedOrder != null && _savedOrder!.kodeBooking.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: SwCheckout.chip,
                    borderRadius: AppRadius.rMd,
                    border: Border.all(color: SwCheckout.line),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Kode booking',
                        style: GoogleFonts.spaceGrotesk(
                          color: SwCheckout.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Kode booking bisa panjang (format lama:
                      // "SW-1793006751664-XQQT" = 21 karakter). Dengan
                      // fontSize 22 + letterSpacing 2, lebarnya melebihi
                      // kartu dan teksnya pecah ke baris berikutnya di
                      // tengah kode — itulah yang terlihat "berantakan".
                      //
                      // FittedBox mengecilkan teks agar SELALU satu baris,
                      // berapa pun panjang kodenya. Ukuran 22 tetap dipakai
                      // sebagai batas atas, jadi kode pendek tidak ikut
                      // mengecil.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _savedOrder!.kodeBooking,
                          maxLines: 1,
                          softWrap: false,
                          style: GoogleFonts.rajdhani(
                            color: SwCheckout.greenDark,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _keTiketSaya,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.rMd),
                  ),
                  child: Text(
                    'Lihat Tiket Saya',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  child: Text(
                    'Kembali ke Beranda',
                    style: GoogleFonts.spaceGrotesk(
                        color: SwCheckout.sub,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}