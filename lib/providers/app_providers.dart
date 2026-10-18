import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/konser_model.dart';
import '../models/pesanan_tiket_model.dart';
import '../models/tiket_konser_model.dart';
import '../models/notifikasi_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/midtrans_service.dart';
import '../services/storage_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final databaseServiceProvider =
    Provider<DatabaseService>((ref) => DatabaseService());

final midtransServiceProvider =
    Provider<MidtransService>((ref) => MidtransService());

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return null;
  return ref.watch(authServiceProvider).getUserData(authUser.uid);
});

final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) {
    return Stream.value(null);
  }
  return authService.streamUserData(authUser.uid);
});

final eventsProvider = StreamProvider<List<KonserModel>>((ref) {
  return ref.watch(databaseServiceProvider).getAllEvents();
});

final ticketsByEventProvider =
    StreamProvider.family<List<TiketKonserModel>, String>((ref, eventId) {
  return ref.watch(databaseServiceProvider).getTicketsByEvent(eventId);
});

final allTicketsProvider = StreamProvider<List<TiketKonserModel>>((ref) {
  return ref.watch(databaseServiceProvider).getAllTickets();
});

final userOrdersProvider =
    StreamProvider.family<List<PesananTiketModel>, String>((ref, userId) {
  return ref.watch(databaseServiceProvider).getUserOrders(userId);
});

final allOrdersProvider = StreamProvider<List<PesananTiketModel>>((ref) {
  return ref.watch(databaseServiceProvider).getAllOrders();
});

/// Notifikasi in-app milik user (terbaru dulu).
/// Ditulis OTOMATIS oleh backend — lihat server.js → kirimNotifikasi.
final notifikasiProvider =
    StreamProvider.family<List<NotifikasiModel>, String>((ref, userId) {
  return ref.watch(databaseServiceProvider).streamNotifikasi(userId);
});

final favoriteIdsProvider =
    StreamProvider.family<List<String>, String>((ref, userId) {
  return ref.watch(databaseServiceProvider).getUserFavoriteEventIds(userId);
});

/// Sinyal "buka menu utama" dari tap notifikasi push (FCM).
///
/// Kenapa perlu: tap push tidak boleh menumpuk halaman baru di atas yang
/// sedang dibuka. FcmGateway cukup kembali ke halaman utama akun yang sedang
/// login (`popUntil(isFirst)`) lalu menaikkan nilai ini — dan halaman utama
/// yang SEDANG terpasang yang menentukan tujuannya sendiri, sehingga user dan
/// admin otomatis mendarat di tempat yang benar:
///   · UserMainScreen -> tab Jelajah (index 0)
///   · AdminDashboard -> menu Konser (index 0)
///
/// Sengaja berupa PENGHITUNG, bukan bool: kalau memakai bool, nilai `true`
/// yang tertinggal dari push sebelumnya membuat `ref.listen` tidak melihat
/// PERUBAHAN sama sekali, sehingga perintah pindah menu diam-diam tidak jalan.
final permintaanMenuUtamaProvider = StateProvider<int>((ref) => 0);

/// Permintaan pindah tab dari layar lain di menu utama user.
/// Nilai = indeks tab tujuan (0 Jelajah, 1 Tiket Saya, 2 Wishlist, 3 Akun).
/// Dipakai alur pembayaran: setelah user menutup pembayaran, ia mendarat
/// langsung di Tiket Saya, bukan tertinggal di langkah 3 checkout.
final permintaanTabUserProvider = StateProvider<int>((ref) => 0);
