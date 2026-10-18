class AppConstants {
  // App
  static const String appName = 'SoundWave';
  static const String tagline = 'Feel the Pulse of Live Music';
  static const String appVersion = '2.4.7';
  // Label versi TERPUSAT. Jangan tulis versi manual di layar mana pun —
  // ubah cukup di sini agar seluruh aplikasi ikut berubah.
  static const String appVersionLabel = '$appName V$appVersion';
  static const String appVersionLabelSecure =
      '$appName V$appVersion (Secure)';

  // User Roles
  static const String roleSuperAdmin = 'super_admin';
  static const String roleAdmin = 'admin';
  static const String roleUser = 'user';

  // Super Admin identity (no password in client — bootstrap via Console / dart-define)
  static const String superAdminEmail = String.fromEnvironment(
    'SUPER_ADMIN_EMAIL',
    defaultValue: 'admin@soundwave.id',
  );
  static const String superAdminName = 'Super Admin';

  // Midtrans — client key only from dart-define; server key lives in Cloud Functions
  static const String midtransClientKey = String.fromEnvironment(
    'MIDTRANS_CLIENT_KEY',
    defaultValue: '',
  );
  static const bool midtransIsProduction = bool.fromEnvironment(
    'MIDTRANS_PRODUCTION',
    defaultValue: false,
  );
  static String get midtransSnapUrl => midtransIsProduction
      ? 'https://app.midtrans.com/snap/snap.js'
      : 'https://app.sandbox.midtrans.com/snap/snap.js';

  // Firestore Collections
  static const String collectionUsers = 'users';
  static const String collectionEvents = 'events';
  static const String collectionTickets = 'tickets';
  static const String collectionOrders = 'orders';
  static const String collectionFavorites = 'favorites';
  static const String collectionReviews = 'reviews';
  static const String collectionNotifications = 'notifications';

  // Order Status
  static const String orderStatusPending = 'PENDING';
  static const String orderStatusPaid = 'PAID';
  static const String orderStatusActive = 'AKTIF';
  static const String orderStatusUsed = 'TERPAKAI';
  static const String orderStatusCancelled = 'CANCELLED';
  static const String orderStatusExpired = 'EXPIRED';
  /// Stok SUDAH dipotong, pesanan menunggu pembayaran (hasil /checkout-atomic).
  static const String orderStatusReserved = 'RESERVED';
  static const String orderStatusRefundRequired = 'REFUND_REQUIRED';
  static const String orderStatusRefundRequested = 'REFUND_REQUESTED';
  static const String orderStatusRefunded = 'REFUNDED';

  // Inventory & Reservation Constraints
  // Jendela pembayaran 5 MENIT: stok dipotong saat pembayaran dimulai dan
  // dilepas otomatis kalau tidak dibayar dalam waktu ini (penyapu backend).
  // Angka ini HARUS sama dengan default RESERVATION_HOLD_MINUTES di backend.
  static const int reservationHoldMinutes = 5;
  static const Duration reservationHold =
      Duration(minutes: reservationHoldMinutes);
  static const int maxActiveReservationsPerUser = 3;
  static const int maxTicketsPerOrder = 4;

  // Event Status
  static const String eventStatusUpcoming = 'upcoming';
  static const String eventStatusOngoing = 'ongoing';
  static const String eventStatusCompleted = 'completed';
  static const String eventStatusCancelled = 'cancelled';

  // Payment Methods
  static const List<String> paymentMethods = [
    'QRIS Instan',
    'Transfer Bank (BCA)',
    'Transfer Bank (Mandiri)',
    'Transfer Bank (BRI)',
    'Kartu Kredit/Debit',
    'GoPay',
    'OVO',
    'DANA',
  ];

  // Genres
  static const List<String> genres = [
    'Pop',
    'Rock',
    'Jazz',
    'Electronic',
    'Hip-Hop',
    'R&B',
    'Indie',
    'Metal',
    'Country',
    'Dangdut',
    'K-Pop',
  ];

  // Ticket Categories — urut dari paling bergengsi ke paling murah.
  // Urutan list ini SEKALIGUS menjadi peringkat tampilan di seluruh aplikasi,
  // jadi jangan diacak: dropdown admin dan daftar tiket user memakai sumber sama.
  static const List<String> ticketCategories = [
    'VVIP',
    'VIP',
    'Festival',
    'Tribun',
    'Reguler',
  ];

  /// Peringkat kategori untuk pengurutan daftar tiket:
  /// VVIP = 0, VIP = 1, Festival = 2, Tribun = 3, Reguler = 4.
  /// Kategori yang tidak dikenal tidak dibuang — hanya ditaruh paling bawah.
  static int peringkatKategori(String kategori) {
    final i = ticketCategories.indexWhere(
      (k) => k.toLowerCase() == kategori.trim().toLowerCase(),
    );
    return i == -1 ? ticketCategories.length : i;
  }

  // Kota
  static const List<String> cities = [
    'Jakarta',
    'Bandung',
    'Surabaya',
    'Yogyakarta',
    'Semarang',
    'Medan',
    'Bali',
    'Makassar',
    'Palembang',
    'Malang',
  ];
}
