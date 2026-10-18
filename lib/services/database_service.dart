import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/konser_model.dart';
import '../models/tiket_konser_model.dart';
import '../models/pesanan_tiket_model.dart';
import '../models/user_model.dart';
import '../models/review_model.dart';
import '../models/promo_model.dart';
import '../models/claimed_promo_model.dart';
import '../models/notifikasi_model.dart';
import '../utils/urutan_tiket.dart';
import 'offline_ticket_service.dart';
import 'midtrans_service.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String buatId() =>
      _firestore.collection('_').doc().id;

  String buatKodeBooking() =>
      'SW-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

  // ===== EVENTS =====

  Stream<List<KonserModel>> getAllEvents() {
    return _firestore
        .collection(AppConstants.collectionEvents)
        .orderBy('tanggal', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => KonserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<KonserModel?> getEventById(String eventId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionEvents)
          .doc(eventId)
          .get();
      if (doc.exists) {
        return KonserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> createEvent(KonserModel event) async {
    try {
      final id = event.id.isEmpty ? buatId() : event.id;
      await _firestore
          .collection(AppConstants.collectionEvents)
          .doc(id)
          .set(event.toMap());
    } catch (e) {
      throw 'Gagal membuat konser';
    }
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(AppConstants.collectionEvents)
          .doc(eventId)
          .update(updates);
    } catch (e) {
      throw 'Gagal memperbarui konser';
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      final tickets = await _firestore
          .collection(AppConstants.collectionTickets)
          .where('idKonser', isEqualTo: eventId)
          .get();
      final batch = _firestore.batch();
      for (final doc in tickets.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(
        _firestore.collection(AppConstants.collectionEvents).doc(eventId),
      );
      await batch.commit();
    } catch (e) {
      throw 'Gagal menghapus konser';
    }
  }

  Future<void> incrementEventViews(String eventId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionEvents)
          .doc(eventId)
          .update({'views': FieldValue.increment(1)});
    } catch (_) {}
  }

  // ===== TICKETS =====

  Stream<List<TiketKonserModel>> getTicketsByEvent(String eventId) {
    return _firestore
        .collection(AppConstants.collectionTickets)
        .where('idKonser', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
      final tickets = snapshot.docs
          .map((doc) => TiketKonserModel.fromMap(doc.data(), doc.id))
          .toList();
      // VVIP -> VIP -> Festival -> Tribun -> Reguler (bukan urutan harga).
      urutkanTiket(tickets);
      return tickets;
    });
  }

  Stream<List<TiketKonserModel>> getAllTickets() {
    return _firestore
        .collection(AppConstants.collectionTickets)
        .orderBy('judulKonser')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TiketKonserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<TiketKonserModel?> getTicketById(String ticketId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionTickets)
          .doc(ticketId)
          .get();
      if (doc.exists) {
        return TiketKonserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> createTicket(TiketKonserModel ticket) async {
    try {
      final id = ticket.id.isEmpty ? buatId() : ticket.id;
      await _firestore
          .collection(AppConstants.collectionTickets)
          .doc(id)
          .set(ticket.toMap());
    } catch (e) {
      throw 'Gagal membuat tiket';
    }
  }

  Future<void> updateTicket(
    String ticketId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.collectionTickets)
          .doc(ticketId)
          .update(updates);
    } catch (e) {
      throw 'Gagal memperbarui tiket';
    }
  }

  Future<void> deleteTicket(String ticketId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionTickets)
          .doc(ticketId)
          .delete();
    } catch (e) {
      throw 'Gagal menghapus tiket';
    }
  }

  // ===== ORDERS =====

  /// Creates a PENDING order with 15-minute reservation window.
  /// Enforces:
  /// 1. Maximum 4 tickets per order.
  /// 2. Maximum 3 active pending orders per user (prevents multiple hold abuse).
  /// 3. Read-only stock validation (buyer cannot write to /tickets/).
  /// 4. Actual stock decrement is deferred to Cloud Functions upon payment settlement.
  Future<PesananTiketModel> createPendingOrder(PesananTiketModel order) async {
    final docRef = _firestore.collection(AppConstants.collectionOrders).doc();
    final kode = order.kodeBooking.isEmpty ? buatKodeBooking() : order.kodeBooking;

    if (order.jumlahTiket > AppConstants.maxTicketsPerOrder) {
      throw 'Maksimal ${AppConstants.maxTicketsPerOrder} tiket per transaksi.';
    }

    try {
      // 1. Guard against Multiple Hold Abuse (max 3 active holds)
      final userPendingQuery = await _firestore
          .collection(AppConstants.collectionOrders)
          .where('userId', isEqualTo: order.userId)
          .where('status', isEqualTo: AppConstants.orderStatusPending)
          .get();

      final now = DateTime.now();
      final activeHoldsCount = userPendingQuery.docs.where((d) {
        final data = d.data();
        final resUntil = (data['reservedUntil'] as Timestamp?)?.toDate();
        return resUntil == null || resUntil.isAfter(now);
      }).length;

      if (activeHoldsCount >= AppConstants.maxActiveReservationsPerUser) {
        throw 'Batas reservasi tercapai. Anda memiliki ${AppConstants.maxActiveReservationsPerUser} pesanan aktif yang belum diselesaikan.';
      }

      // 2. Read-only Stock Validation (buyer cannot update /tickets/ per Rules)
      if (order.idTiket != null && order.idTiket!.isNotEmpty) {
        final ticketDoc = await _firestore
            .collection(AppConstants.collectionTickets)
            .doc(order.idTiket)
            .get();
        if (!ticketDoc.exists || ticketDoc.data() == null) {
          throw 'Tiket konser tidak ditemukan.';
        }

        final currentStock = (ticketDoc.data()!['stok'] as num?)?.toInt() ?? 0;
        if (currentStock < order.jumlahTiket) {
          throw 'Stok tiket tidak mencukupi (Sisa stok: $currentStock).';
        }
      }

      // 3. 15-minute reservation window
      final reservedUntil = now.add(const Duration(minutes: AppConstants.reservationHoldMinutes));

      // 4. Create PENDING order — stock decrement handled by Cloud Functions on payment
      final payload = order.copyWith(
        id: docRef.id,
        kodeBooking: kode,
        status: AppConstants.orderStatusPending,
        reservedUntil: reservedUntil,
        qrPayloadSignature: null,
      );

      await docRef.set(payload.toMap());
      return payload;
    } catch (e) {
      if (e is String) rethrow;
      throw 'Gagal membuat reservasi pesanan: $e';
    }
  }

  /// Cancels a pending order. Stock restoration is handled by Cloud Functions.
  /// Buyer can only change status from PENDING to CANCELLED (per Firestore Rules).
  Future<void> cancelPendingOrderAndReleaseStock(String orderId) async {
    try {
      final orderRef = _firestore.collection(AppConstants.collectionOrders).doc(orderId);
      final orderSnap = await orderRef.get();
      if (!orderSnap.exists || orderSnap.data() == null) return;

      final status = orderSnap.data()!['status'];
      if (status == AppConstants.orderStatusPending) {
        // Buyer-permitted update: PENDING → CANCELLED (matches Firestore Rules)
        await orderRef.update({
          'status': AppConstants.orderStatusCancelled,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        // Stock restoration is deferred to Cloud Functions / scheduled cleanup
      }
    } catch (e) {
      throw 'Gagal membatalkan pesanan: $e';
    }
  }

  // ===== NOTIFIKASI IN-APP =====
  // Koleksi global `notifications`, ditulis OTOMATIS oleh backend
  // (server.js → kirimNotifikasi) saat pembayaran/refund berubah status.
  //
  // PENTING: filter `userId` WAJIB ada. Firestore Rules hanya mengizinkan
  // user membaca dokumen miliknya sendiri, sehingga query tanpa filter ini
  // akan ditolak (permission-denied). Pengurutan dikerjakan di sisi app
  // supaya tidak memerlukan composite index.

  /// Stream notifikasi milik user (terbaru dulu).
  Stream<List<NotifikasiModel>> streamNotifikasi(String userId) {
    return _firestore
        .collection(AppConstants.collectionNotifications)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => NotifikasiModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Tandai SATU notifikasi sudah dibaca.
  Future<void> tandaiNotifikasiDibaca(String notifId) async {
    await _firestore
        .collection(AppConstants.collectionNotifications)
        .doc(notifId)
        .update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  /// Tandai SEMUA notifikasi user sudah dibaca.
  /// Mengembalikan jumlah notifikasi yang berubah.
  Future<int> tandaiSemuaNotifikasiDibaca(String userId) async {
    final snap = await _firestore
        .collection(AppConstants.collectionNotifications)
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return 0;

    final batch = _firestore.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return snap.docs.length;
  }

  // ===== CLAIMED PROMOS (voucher milik user) =====
  // Subkoleksi: users/{userId}/claimed_promos/{promoId}

  /// Stream voucher yang sudah diklaim user (terbaru dulu).
  Stream<List<ClaimedPromoModel>> streamClaimedPromos(String userId) {
    return _firestore
        .collection(AppConstants.collectionUsers)
        .doc(userId)
        .collection('claimed_promos')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ClaimedPromoModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.claimedAt.compareTo(a.claimedAt));
      return list;
    });
  }

  /// Klaim promo ke akun user. Idempotent (docId = promoId).
  /// Melempar error bila promo sudah pernah diklaim.
  Future<void> claimPromo(String userId, PromoCodeModel promo) async {
    final ref = _firestore
        .collection(AppConstants.collectionUsers)
        .doc(userId)
        .collection('claimed_promos')
        .doc(promo.id);

    final existing = await ref.get();
    if (existing.exists) {
      throw 'Promo ini sudah ada di akunmu.';
    }

    await ref.set({
      'promoId': promo.id,
      'kode': promo.kode,
      'tipe': promo.tipe,
      'nilai': promo.nilai,
      'minPembelian': promo.minPembelian,
      'deskripsi': promo.deskripsi,
      'berlakuAkhir': Timestamp.fromDate(promo.berlakuAkhir),
      'claimedAt': FieldValue.serverTimestamp(),
      'used': false,
      'usedAt': null,
      'orderId': null,
    });
  }

  /// Tandai voucher sudah terpakai (dipanggil setelah pembayaran sukses).
  Future<void> markClaimedPromoUsed(
    String userId,
    String promoId, {
    String? orderId,
  }) async {
    await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(userId)
        .collection('claimed_promos')
        .doc(promoId)
        .update({
      'used': true,
      'usedAt': FieldValue.serverTimestamp(),
      'orderId': orderId,
    });
  }

  // ===== REFUND (status pengajuan refund milik user) =====

  /// Menandai reservasi yang jendela bayarnya sudah lewat sebagai EXPIRED.
  ///
  /// Aturan stok (sama dengan penyapu di backend):
  ///   PENDING  → stok BELUM pernah dipotong, jadi jangan disentuh.
  ///   RESERVED → stok sudah dipotong, lepas SEKALI (tandai stokDilepas).
  ///
  /// Catatan: jalur utama tetap penyapu di backend (`/sweep-expired`) karena
  /// hanya server yang boleh mengubah stok. Fungsi ini dipakai sebagai
  /// jaring pengaman dan sengaja tidak pernah menambah stok untuk PENDING
  /// (dulu justru menambah → stok naik palsu).
  Future<int> releaseExpiredReservations() async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      // Satu field saja supaya tidak perlu composite index.
      final expiredQuery = await _firestore
          .collection(AppConstants.collectionOrders)
          .where('reservedUntil', isLessThan: now)
          .limit(25)
          .get();

      int releasedCount = 0;
      for (final doc in expiredQuery.docs) {
        final orderData = doc.data();
        final status = orderData['status'];
        final sudahDilepas = orderData['stokDilepas'] == true;
        final stokDipotong = orderData['stokDipotong'] == true ||
            status == AppConstants.orderStatusReserved;

        // Hanya dua status ini yang masih menggenggam slot pembayaran.
        if (status != AppConstants.orderStatusPending &&
            status != AppConstants.orderStatusReserved) {
          continue;
        }

        final ticketId = orderData['idTiket'] as String?;
        final qty = (orderData['jumlahTiket'] as num?)?.toInt() ?? 1;
        final perluLepasStok =
            stokDipotong && !sudahDilepas && (ticketId ?? '').isNotEmpty;

        await _firestore.runTransaction((transaction) async {
          final freshDoc = await transaction.get(doc.reference);
          final fresh = freshDoc.data();
          if (!freshDoc.exists || fresh == null) return;

          final freshStatus = fresh['status'];
          if (freshStatus != AppConstants.orderStatusPending &&
              freshStatus != AppConstants.orderStatusReserved) {
            return; // sudah diurus pihak lain (webhook / penyapu backend)
          }

          transaction.update(doc.reference, {
            'status': AppConstants.orderStatusExpired,
            ...(perluLepasStok ? {'stokDilepas': true} : {}),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (perluLepasStok) {
            final ticketRef = _firestore
                .collection(AppConstants.collectionTickets)
                .doc(ticketId);
            final ticketSnap = await transaction.get(ticketRef);
            final ticket = ticketSnap.data();
            if (ticketSnap.exists && ticket != null) {
              final currentStock = (ticket['stok'] as num?)?.toInt() ?? 0;
              final currentTerjual = (ticket['terjual'] as num?)?.toInt() ?? 0;
              transaction.update(ticketRef, {
                'stok': currentStock + qty,
                'terjual': currentTerjual - qty < 0 ? 0 : currentTerjual - qty,
                'revisionCounter':
                    ((ticket['revisionCounter'] as num?)?.toInt() ?? 0) + 1,
              });
            }
          }
          releasedCount++;
        });
      }
      return releasedCount;
    } catch (_) {
      return 0;
    }
  }

  /// Flag order as requiring refund
  Future<void> flagOrderRefundRequired(String orderId, String reason) async {
    await _firestore.collection(AppConstants.collectionOrders).doc(orderId).update({
      'status': AppConstants.orderStatusRefundRequired,
      'refundReason': reason,
      'refundRequestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Process refund confirmation by admin
  Future<void> markOrderRefunded(String orderId, Map<String, dynamic> refundAudit) async {
    await _firestore.collection(AppConstants.collectionOrders).doc(orderId).update({
      'status': AppConstants.orderStatusRefunded,
      'refundDetails': refundAudit,
      'refundCompletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<PesananTiketModel>> getUserOrders(String userId) {
    return _firestore
        .collection(AppConstants.collectionOrders)
        .where('userId', isEqualTo: userId)
        .orderBy('tanggalBeli', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = <PesananTiketModel>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(PesananTiketModel.fromMap(doc.data(), doc.id));
        } catch (e) {
          // Lewati 1 dokumen korup agar tidak mengosongkan seluruh daftar tiket.
          // ignore: avoid_print
          print('⚠️ Skip order ${doc.id} (parse gagal): $e');
        }
      }
      return list;
    });
  }

  Stream<List<PesananTiketModel>> getAllOrders() {
    return _firestore
        .collection(AppConstants.collectionOrders)
        .orderBy('tanggalBeli', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PesananTiketModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<PesananTiketModel?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionOrders)
          .doc(orderId)
          .get();
      if (doc.exists) {
        return PesananTiketModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<PesananTiketModel?> getOrderByBookingCode(String kode) async {
    try {
      final clean = kode.trim();
      final query = await _firestore
          .collection(AppConstants.collectionOrders)
          .where('kodeBooking', isEqualTo: clean)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      final doc = query.docs.first;
      return PesananTiketModel.fromMap(doc.data(), doc.id);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    DateTime? tanggalDigunakan,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (tanggalDigunakan != null) {
        updates['tanggalDigunakan'] = Timestamp.fromDate(tanggalDigunakan);
      }
      await _firestore
          .collection(AppConstants.collectionOrders)
          .doc(orderId)
          .update(updates);
    } catch (e) {
      throw 'Gagal mengubah status pesanan';
    }
  }

  /// Admin gate validation — marks AKTIF/PAID ticket as TERPAKAI atomically.
  /// Prevents double-scan race conditions if two scanners process the same ticket simultaneously.
  /// Gracefully falls back to OfflineTicketService if device has no network.
  Future<Map<String, dynamic>> validateGateTicket(String rawInput) async {
    final raw = rawInput.trim();
    if (raw.isEmpty) {
      return {'ok': false, 'message': 'Kode booking kosong'};
    }

    // Extract booking code if rawInput is signed QR payload
    // SW1 format: SW1|orderId|kodeBooking|...
    // SW2 format: SW2|keyId|orderId|kodeBooking|idKonser|kategoriTiket|jumlahTiket|signatureHex
    var cleanCode = raw;
    if (raw.startsWith('SW1|') && raw.split('|').length >= 3) {
      cleanCode = raw.split('|')[2];
    } else if (raw.startsWith('SW2|') && raw.split('|').length >= 4) {
      cleanCode = raw.split('|')[3];
    }

    try {
      // 1. Locate order document reference by kodeBooking or orderId
      final query = await _firestore
          .collection(AppConstants.collectionOrders)
          .where('kodeBooking', isEqualTo: cleanCode)
          .limit(1)
          .get();

      DocumentReference<Map<String, dynamic>> orderRef;
      if (query.docs.isNotEmpty) {
        orderRef = query.docs.first.reference;
      } else {
        // Fallback: check if cleanCode is the document ID directly
        final directDoc = await _firestore
            .collection(AppConstants.collectionOrders)
            .doc(cleanCode)
            .get();
        if (directDoc.exists) {
          orderRef = directDoc.reference;
        } else {
          return {'ok': false, 'message': 'Kode booking tidak ditemukan di database'};
        }
      }

      // 2. Atomic Transaction Execution
      final result = await _firestore.runTransaction<Map<String, dynamic>>((transaction) async {
        final snapshot = await transaction.get(orderRef);
        if (!snapshot.exists || snapshot.data() == null) {
          return {'ok': false, 'message': 'Data pesanan tidak ditemukan'};
        }

        final data = snapshot.data()!;
        final order = PesananTiketModel.fromMap(data, snapshot.id);

        if (order.isTerpakai) {
          return {
            'ok': false,
            'message': 'Tiket SUDAH DIGUNAKAN sebelumnya',
            'order': order,
          };
        }

        if (order.isCancelled) {
          return {
            'ok': false,
            'message': 'Tiket DIBATALKAN / CANCELLED',
            'order': order,
          };
        }

        if (order.isPending) {
          return {
            'ok': false,
            'message': 'Tiket BELUM DIBAYAR (Status: PENDING)',
            'order': order,
          };
        }

        if (!order.isAktif) {
          return {
            'ok': false,
            'message': 'Status tiket tidak valid untuk check-in: ${order.status}',
            'order': order,
          };
        }

        final now = DateTime.now();
        // Atomic status mutation
        transaction.update(orderRef, {
          'status': AppConstants.orderStatusUsed,
          'tanggalDigunakan': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return {
          'ok': true,
          'message': 'Tiket Valid — Silakan Masuk',
          'order': order.copyWith(
            status: AppConstants.orderStatusUsed,
            tanggalDigunakan: now,
          ),
        };
      });

      return result;
    } catch (e) {
      // Offline fallback: if network is down and input has signed token SW2|...
      if (raw.startsWith('SW2|')) {
        return await OfflineTicketService().verifyOfflineTicket(raw);
      }
      return {
        'ok': false,
        'message': 'Koneksi terputus & tiket tidak memiliki signed token offline: $e',
      };
    }
  }

  /// Synchronizes un-synced offline gate admission records to the authoritative server
  /// Uses Cloud Functions syncOfflineScans as the single authoritative ingestion path.
  Future<Map<String, dynamic>> syncPendingOfflineScans() async {
    final pending = OfflineTicketService().pendingOfflineRecords;
    if (pending.isEmpty) {
      return {
        'ok': true,
        'syncedCount': 0,
        'message': 'Tidak ada data scan offline tertunda.',
      };
    }

    final payload = pending
        .map((r) => {
              'scanId': r.scanId,
              'kodeBooking': r.kodeBooking,
              'orderId': r.orderId,
              'idKonser': r.idKonser,
              'deviceId': r.deviceId,
              'scannedAt': r.scannedAt.toIso8601String(),
            })
        .toList();

    try {
      final backendUrl = await MidtransService.getBackendUrl();
      final response = await http.post(
        Uri.parse('$backendUrl/sync-offline-scans'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'scans': payload}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final syncedCount = data['syncedCount'] as int? ?? 0;
      final duplicateCount = data['duplicateCount'] as int? ?? 0;

      // Server Ack Received: Only mark local records synced after server returns success
      final syncedIds = pending.map((r) => r.scanId).toList();
      await OfflineTicketService().markRecordsSynced(syncedIds);

      return {
        'ok': true,
        'syncedCount': syncedCount,
        'duplicateCount': duplicateCount,
        'message':
            'Sinkronisasi berhasil: $syncedCount tiket diproses, $duplicateCount duplikat diabaikan.',
      };
    } catch (e) {
      // Network failure, timeout, or server rejection: records remain strictly PENDING locally
      return {
        'ok': false,
        'message': 'Gagal menyinkronkan scan offline ke server. Coba lagi sebentar.',
      };
    }
  }

  // ===== FAVORITES =====

  Future<void> addToFavorites(String userId, String eventId) async {
    final favId = '$userId-$eventId';
    await _firestore.collection(AppConstants.collectionFavorites).doc(favId).set({
      'userId': userId,
      'eventId': eventId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFromFavorites(String userId, String eventId) async {
    await _firestore
        .collection(AppConstants.collectionFavorites)
        .doc('$userId-$eventId')
        .delete();
  }

  Future<void> toggleFavorite(String userId, String eventId) async {
    final fav = await isEventFavorite(userId, eventId);
    if (fav) {
      await removeFromFavorites(userId, eventId);
    } else {
      await addToFavorites(userId, eventId);
    }
  }

  Stream<List<String>> getUserFavoriteEventIds(String userId) {
    return _firestore
        .collection(AppConstants.collectionFavorites)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data()['eventId'] as String)
          .toList();
    });
  }

  Future<bool> isEventFavorite(String userId, String eventId) async {
    final doc = await _firestore
        .collection(AppConstants.collectionFavorites)
        .doc('$userId-$eventId')
        .get();
    return doc.exists;
  }

  // ===== REVIEWS =====

  Stream<List<ReviewModel>> getReviewsByEvent(String eventId) {
    return _firestore
        .collection(AppConstants.collectionReviews)
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> createReview(ReviewModel review) async {
    await _firestore
        .collection(AppConstants.collectionReviews)
        .add(review.toMap());
  }

  // ===== ANALYTICS =====

  Future<Map<String, dynamic>> getEventSalesAnalytics(String eventId) async {
    try {
      final ticketsQuery = await _firestore
          .collection(AppConstants.collectionTickets)
          .where('idKonser', isEqualTo: eventId)
          .get();

      final ordersQuery = await _firestore
          .collection(AppConstants.collectionOrders)
          .where('idKonser', isEqualTo: eventId)
          .get();

      int totalTicketsSold = 0;
      double totalRevenue = 0.0;
      int pendingOrders = 0;
      int paidOrders = 0;

      for (final doc in ordersQuery.docs) {
        final order = PesananTiketModel.fromMap(doc.data(), doc.id);
        if (order.isCancelled) continue;
        if (order.isPending) {
          pendingOrders++;
          continue;
        }
        totalTicketsSold += order.jumlahTiket;
        totalRevenue += order.totalHarga;
        paidOrders++;
      }

      int totalStockAvailable = 0;
      for (final doc in ticketsQuery.docs) {
        totalStockAvailable += (doc.data()['stok'] as num?)?.toInt() ?? 0;
      }

      return {
        'totalTicketsSold': totalTicketsSold,
        'totalRevenue': totalRevenue,
        'pendingOrders': pendingOrders,
        'paidOrders': paidOrders,
        'totalStockAvailable': totalStockAvailable,
      };
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getAllEventsAnalytics() async {
    try {
      final events =
          await _firestore.collection(AppConstants.collectionEvents).get();
      final analytics = <Map<String, dynamic>>[];
      for (final doc in events.docs) {
        final eventAnalytics = await getEventSalesAnalytics(doc.id);
        analytics.add({
          'eventId': doc.id,
          'eventName': doc.data()['judul'],
          ...eventAnalytics,
        });
      }
      return analytics;
    } catch (e) {
      return [];
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore
        .collection(AppConstants.collectionUsers)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> updateUserRole(String userId, String role) async {
    final caller = FirebaseAuth.instance.currentUser;
    if (caller == null) {
      throw 'Pengguna belum terautentikasi.';
    }
    if (caller.uid == userId) {
      throw 'Tidak dapat mengubah role akun sendiri.';
    }
    if (![AppConstants.roleUser, AppConstants.roleAdmin].contains(role)) {
      throw 'Role target tidak valid. Hanya role user atau admin yang diizinkan.';
    }

    final callerDoc = await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(caller.uid)
        .get();
    if (!callerDoc.exists || callerDoc.data()?['role'] != AppConstants.roleSuperAdmin) {
      throw 'Hanya superadmin yang berhak mengubah role pengguna.';
    }

    try {
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('[DatabaseService.updateUserRole] Firestore error: [${e.code}] ${e.message}');
      throw 'Gagal mengubah role [${e.code}]: ${e.message}';
    } catch (e) {
      throw 'Gagal mengubah role: $e';
    }
  }

  Future<void> deleteUser(String userId) async {
    final caller = FirebaseAuth.instance.currentUser;
    if (caller == null) {
      throw 'Pengguna belum terautentikasi.';
    }
    if (caller.uid == userId) {
      throw 'Tidak dapat menghapus akun sendiri.';
    }

    final callerDoc = await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(caller.uid)
        .get();
    if (!callerDoc.exists || callerDoc.data()?['role'] != AppConstants.roleSuperAdmin) {
      throw 'Hanya superadmin yang berhak menghapus profil pengguna.';
    }

    final targetDoc = await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(userId)
        .get();
    if (targetDoc.exists && targetDoc.data()?['role'] == AppConstants.roleSuperAdmin) {
      throw 'Tidak dapat menghapus profil sesama superadmin.';
    }

    try {
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .delete();
    } on FirebaseException catch (e) {
      debugPrint('[DatabaseService.deleteUser] Firestore error: [${e.code}] ${e.message}');
      throw 'Gagal menghapus user [${e.code}]: ${e.message}';
    } catch (e) {
      throw 'Gagal menghapus user: $e';
    }
  }

}
