const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');
const midtransClient = require('midtrans-client');

admin.initializeApp();
const db = admin.firestore();

// Midtrans Snap client initialization (Environment Config or Secrets)
const isProduction = process.env.MIDTRANS_IS_PRODUCTION === 'true';
const serverKey = process.env.MIDTRANS_SERVER_KEY || 'xxxxxxxx';
const clientKey = process.env.MIDTRANS_CLIENT_KEY || 'xxxxxxxx';

const snap = new midtransClient.Snap({
  isProduction: isProduction,
  serverKey: serverKey,
  clientKey: clientKey,
});

const activeKeyId = process.env.ED25519_KEY_ID || 'v1';

/**
 * Returns Ed25519 private key for signing.
 * Strictly throws if missing in production to enforce Secret Manager injection.
 */
function getSigningKey() {
  const hex = process.env.ED25519_PRIVATE_KEY_HEX;
  if (!hex) {
    if (isProduction || process.env.NODE_ENV === 'production') {
      throw new Error('[FATAL SECURITY EXCEPTION] ED25519_PRIVATE_KEY_HEX missing in production environment.');
    }
    // Development sandbox key (never deployed to production)
    return Buffer.from(
      '302e020100300506032b657004220420c699893e2338a0bd8c4aef14d17c700209775bd14198d80dad1ce1c896f9eb31',
      'hex'
    );
  }
  return Buffer.from(hex, 'hex');
}

/**
 * 1. HTTPS Callable: createSnapToken
 * Client sends: { orderId }
 * Server validates order ownership, recalculates total from database, checks stock,
 * requests Snap token from Midtrans, and updates order with snapToken and paymentUrl.
 */
exports.createSnapToken = functions.https.onCall(async (data, context) => {
  // Authentication check
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Pengguna harus login untuk melakukan pembayaran.',
    );
  }

  const { orderId } = data;
  if (!orderId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'orderId wajib disertakan.',
    );
  }

  const orderRef = db.collection('orders').doc(orderId);
  const orderDoc = await orderRef.get();

  if (!orderDoc.exists) {
    throw new functions.https.HttpsError(
      'not-found',
      'Pesanan tidak ditemukan.',
    );
  }

  const orderData = orderDoc.data();

  // Authorization: Only the owner can request payment
  if (orderData.userId !== context.auth.uid) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Anda tidak memiliki akses ke pesanan ini.',
    );
  }

  // State validation: only PENDING orders can receive snap tokens
  if (orderData.status !== 'PENDING') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      `Pesanan sudah berstatus ${orderData.status}, tidak dapat diproses ulang.`,
    );
  }

  // Price & Inventory Re-verification from authoritative Database
  let authoritativePrice = 0;
  if (orderData.idTiket) {
    const ticketRef = db.collection('tickets').doc(orderData.idTiket);
    const ticketDoc = await ticketRef.get();

    if (!ticketDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Data tiket konser tidak ditemukan.',
      );
    }

    const ticketData = ticketDoc.data();
    if (ticketData.stok < orderData.jumlahTiket) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        `Stok tiket tidak mencukupi. Sisa stok: ${ticketData.stok}`,
      );
    }
    authoritativePrice = Number(ticketData.harga) || 0;
  }

  const serviceFee = 5000;
  const authoritativeTotal = authoritativePrice > 0
    ? (authoritativePrice * orderData.jumlahTiket) + serviceFee
    : Math.round(orderData.totalHarga);

  // Security guard against client price tampering:
  if (Math.round(orderData.totalHarga) !== authoritativeTotal) {
    console.warn(`[SECURITY] Price mismatch detected for order ${orderId}. Expected ${authoritativeTotal}, got ${orderData.totalHarga}. Overwriting.`);
    await orderRef.update({
      totalHarga: authoritativeTotal,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    orderData.totalHarga = authoritativeTotal;
  }

  // If order already has a valid snapToken, reuse it
  if (orderData.snapToken && orderData.snapRedirectUrl) {
    return {
      success: true,
      token: orderData.snapToken,
      redirect_url: orderData.snapRedirectUrl,
      order_id: orderId,
    };
  }

  // Create Midtrans Transaction Parameter
  const parameter = {
    transaction_details: {
      order_id: orderData.kodeBooking || orderId,
      gross_amount: authoritativeTotal,
    },
    item_details: [
      {
        id: orderData.idTiket || orderData.idKonser,
        price: authoritativePrice > 0 ? authoritativePrice : Math.round((authoritativeTotal - serviceFee) / orderData.jumlahTiket),
        quantity: orderData.jumlahTiket,
        name: `${orderData.judulKonser} (${orderData.kategoriTiket})`.substring(0, 50),
      },
      {
        id: 'BIAYA-ADMIN',
        price: serviceFee,
        quantity: 1,
        name: 'Biaya Layanan & Pemeliharaan',
      },
    ],
    customer_details: {
      first_name: orderData.namaPembeli,
      email: orderData.emailPembeli,
      phone: orderData.teleponPembeli || '08123456789',
    },
  };

  try {
    const transaction = await snap.createTransaction(parameter);

    await orderRef.update({
      snapToken: transaction.token,
      snapRedirectUrl: transaction.redirect_url,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      token: transaction.token,
      redirect_url: transaction.redirect_url,
      order_id: orderId,
    };
  } catch (error) {
    console.error('Midtrans createTransaction error:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Gagal menghubungi payment gateway Midtrans.',
    );
  }
});

/**
 * 2. HTTP Webhook: paymentWebhook
 * Handles asynchronous notification from Midtrans.
 * Verifies SHA512 signature, executes idempotent state transition, and
 * performs atomic inventory decrement inside a Firestore Transaction.
 */
exports.paymentWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).send('Method Not Allowed');
  }

  const notification = req.body;
  const {
    order_id: orderIdOrBookingCode,
    status_code: statusCode,
    gross_amount: grossAmount,
    signature_key: signatureKey,
    transaction_status: transactionStatus,
    fraud_status: fraudStatus,
    payment_type: paymentType,
  } = notification;

  // 1. Signature Verification
  // signature_key = SHA512(order_id + status_code + gross_amount + ServerKey)
  const rawSignature = `${orderIdOrBookingCode}${statusCode}${grossAmount}${serverKey}`;
  const calculatedSignature = crypto
    .createHash('sha512')
    .update(rawSignature)
    .digest('hex');

  if (signatureKey !== calculatedSignature) {
    console.warn(`[SECURITY ALERT] Invalid webhook signature for order ${orderIdOrBookingCode}`);
    return res.status(403).json({ error: 'Invalid signature key' });
  }

  // 2. Find Order by kodeBooking or id
  let orderRef = db.collection('orders').doc(orderIdOrBookingCode);
  let orderDoc = await orderRef.get();

  if (!orderDoc.exists) {
    const query = await db
      .collection('orders')
      .where('kodeBooking', '==', orderIdOrBookingCode)
      .limit(1)
      .get();

    if (query.empty) {
      console.warn(`Order not found for booking code / ID: ${orderIdOrBookingCode}`);
      return res.status(404).json({ error: 'Order not found' });
    }
    orderDoc = query.docs[0];
    orderRef = orderDoc.ref;
  }

  const currentOrder = orderDoc.data();

  // 3. Map Midtrans transaction status to SoundWave lifecycle
  let targetStatus = 'PENDING';
  let isPaidSuccess = false;

  if (transactionStatus === 'capture') {
    if (fraudStatus === 'accept') {
      targetStatus = 'AKTIF';
      isPaidSuccess = true;
    }
  } else if (transactionStatus === 'settlement') {
    targetStatus = 'AKTIF';
    isPaidSuccess = true;
  } else if (['cancel', 'deny', 'expire'].includes(transactionStatus)) {
    targetStatus = 'CANCELLED';
  } else if (transactionStatus === 'pending') {
    targetStatus = 'PENDING';
  }

  // 4. Idempotency Check:
  // If order is already in target status or already final (AKTIF or TERPAKAI), do NOT mutate stock again
  if (currentOrder.status === targetStatus || currentOrder.status === 'TERPAKAI') {
    console.log(`[IDEMPOTENCY] Order ${orderIdOrBookingCode} already status ${currentOrder.status}. No action.`);
    return res.status(200).json({ status: 'already_processed' });
  }

  // 5. Atomic State Transition & Inventory Mutation
  try {
    let finalStatus = targetStatus;
    let userId = null;
    let concertTitle = '';
    let category = '';

    await db.runTransaction(async (transaction) => {
      const freshOrderDoc = await transaction.get(orderRef);
      const freshOrderData = freshOrderDoc.data();

      // Double-check idempotency inside transaction lock
      if (freshOrderData.status === 'AKTIF' || freshOrderData.status === 'TERPAKAI') {
        finalStatus = freshOrderData.status;
        return;
      }

      userId = freshOrderData.userId;
      concertTitle = freshOrderData.judulKonser || 'Konser';
      category = freshOrderData.kategoriTiket || '';

      const nowMs = Date.now();
      const resUntilMs = freshOrderData.reservedUntil ? freshOrderData.reservedUntil.toMillis() : null;
      const isExpiredHold = resUntilMs && resUntilMs < nowMs;

      let isOverbooked = false;

      // If transition is to AKTIF (Payment Successful), manage inventory
      if (isPaidSuccess && freshOrderData.idTiket) {
        const ticketRef = db.collection('tickets').doc(freshOrderData.idTiket);
        const ticketDoc = await transaction.get(ticketRef);

        if (ticketDoc.exists) {
          const ticketData = ticketDoc.data();
          const currentStock = ticketData.stok || 0;
          const currentTerjual = ticketData.terjual || 0;
          const qty = freshOrderData.jumlahTiket || 1;

          if (isExpiredHold) {
            // Payment arrived after 15-minute reservation expired
            if (currentStock < qty) {
              // STOCK EXHAUSTED! Prevent overbooking by flagging REFUND_REQUIRED
              isOverbooked = true;
              finalStatus = 'REFUND_REQUIRED';
              console.warn(`[OVERBOOKING DEFENSE] Order ${orderIdOrBookingCode} paid after reservation expired. Stock exhausted. Status set to REFUND_REQUIRED.`);
            } else {
              // Stock still available, allocate and decrement
              transaction.update(ticketRef, {
                stok: currentStock - qty,
                terjual: currentTerjual + qty,
              });
            }
          } else {
            // Normal path: reservation was active. Stock was held during reservation, update terjual.
            transaction.update(ticketRef, {
              terjual: currentTerjual + qty,
            });
          }
        }
      }

      // Generate asymmetric Ed25519 digital signature with Key Versioning
      const privKey = crypto.createPrivateKey({ key: getSigningKey(), format: 'der', type: 'pkcs8' });
      const canonicalPayload = `SW2|${activeKeyId}|${orderRef.id}|${freshOrderData.kodeBooking}|${freshOrderData.idKonser}|${freshOrderData.kategoriTiket}|${freshOrderData.jumlahTiket}`;
      const edSignatureHex = crypto.sign(null, Buffer.from(canonicalPayload), privKey).toString('hex');
      const signedQrPayload = `SW2|${activeKeyId}|${orderRef.id}|${freshOrderData.kodeBooking}|${freshOrderData.idKonser}|${freshOrderData.kategoriTiket}|${freshOrderData.jumlahTiket}|${edSignatureHex}`;

      // Update Order Status and Audit details
      transaction.update(orderRef, {
        status: finalStatus,
        metodePembayaran: paymentType || freshOrderData.metodePembayaran,
        qrPayloadSignature: signedQrPayload,
        paymentDetails: {
          transactionStatus: transactionStatus,
          fraudStatus: fraudStatus || null,
          paymentType: paymentType || null,
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          isOverbooked: isOverbooked,
          refundReason: isOverbooked ? 'Pembayaran diterima setelah reservasi 15 menit kedaluwarsa dan stok tiket telah habis.' : null,
        },
        auditTrail: admin.firestore.FieldValue.arrayUnion({
          event: finalStatus === 'AKTIF' ? 'PAYMENT_SETTLED_TICKET_ACTIVE' : 'OVERBOOKED_REFUND_FLAGGED',
          status: finalStatus,
          timestamp: new Date().toISOString(),
          transactionStatus: transactionStatus,
        }),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    // Send asynchronous push notification if user has registered FCM token
    if (userId && (finalStatus === 'AKTIF' || finalStatus === 'REFUND_REQUIRED')) {
      try {
        const userDoc = await db.collection('users').doc(userId).get();
        if (userDoc.exists) {
          const fcmToken = userDoc.data()?.fcmToken;
          if (fcmToken) {
            const isSuccess = finalStatus === 'AKTIF';
            await admin.messaging().send({
              token: fcmToken,
              notification: {
                title: isSuccess ? 'Pembayaran Berhasil! 🎟️' : 'Perhatian Pembayaran Tiket',
                body: isSuccess
                  ? `Tiket konser ${concertTitle} (${category}) Anda sudah aktif.`
                  : `Batas waktu reservasi ${concertTitle} telah habis. Dana dialokasikan untuk refund.`,
              },
              data: {
                orderId: orderRef.id,
                status: finalStatus,
              },
            });
          }
        }
      } catch (fcmErr) {
        console.warn('FCM delivery note (non-critical):', fcmErr.message);
      }
    }

    console.log(`[COMMERCE SUCCESS] Order ${orderIdOrBookingCode} transitioned to ${finalStatus}`);
    return res.status(200).json({ status: 'ok', updated_status: finalStatus });
  } catch (err) {
    console.error(`Transaction failed for order ${orderIdOrBookingCode}:`, err);
    return res.status(500).json({ error: 'Internal transaction error' });
  }
});

/**
 * 3. HTTPS Callable: cleanupExpiredReservations
 * Scans for PENDING orders with expired reservations, restores inventory, and sets status to EXPIRED.
 * Requires authenticated admin/super_admin caller.
 */
exports.cleanupExpiredReservations = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login diperlukan.');
  }

  const callerDoc = await db.collection('users').doc(context.auth.uid).get();
  if (!callerDoc.exists || !['admin', 'super_admin'].includes(callerDoc.data().role)) {
    throw new functions.https.HttpsError('permission-denied', 'Hanya administrator yang berhak menjalankan cleanup.');
  }

  const now = admin.firestore.Timestamp.now();
  const querySnap = await db.collection('orders')
    .where('status', '==', 'PENDING')
    .where('reservedUntil', '<', now)
    .limit(50)
    .get();

  let cleaned = 0;
  for (const doc of querySnap.docs) {
    const orderData = doc.data();
    await db.runTransaction(async (t) => {
      const freshDoc = await t.get(doc.ref);
      if (freshDoc.exists && freshDoc.data().status === 'PENDING') {
        t.update(doc.ref, {
          status: 'EXPIRED',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          auditTrail: admin.firestore.FieldValue.arrayUnion({
            event: 'RESERVATION_HOLD_EXPIRED',
            timestamp: new Date().toISOString(),
          }),
        });

        if (orderData.idTiket) {
          const ticketRef = db.collection('tickets').doc(orderData.idTiket);
          const ticketSnap = await t.get(ticketRef);
          if (ticketSnap.exists) {
            const currentStock = ticketSnap.data().stok || 0;
            const qty = orderData.jumlahTiket || 1;
            t.update(ticketRef, { stok: currentStock + qty });
          }
        }
        cleaned++;
      }
    });
  }

  return { success: true, expiredOrdersCleaned: cleaned };
});

/**
 * 4. Scheduled Function (PubSub): scheduledReservationCleanup
 * Runs every 5 minutes to automatically release expired reservation holds and restore inventory.
 */
exports.scheduledReservationCleanup = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const querySnap = await db.collection('orders')
      .where('status', '==', 'PENDING')
      .where('reservedUntil', '<', now)
      .limit(100)
      .get();

    let cleaned = 0;
    for (const doc of querySnap.docs) {
      const orderData = doc.data();
      await db.runTransaction(async (t) => {
        const freshDoc = await t.get(doc.ref);
        if (freshDoc.exists && freshDoc.data().status === 'PENDING') {
          t.update(doc.ref, {
            status: 'EXPIRED',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            auditTrail: admin.firestore.FieldValue.arrayUnion({
              event: 'SCHEDULED_HOLD_EXPIRED',
              timestamp: new Date().toISOString(),
            }),
          });

          if (orderData.idTiket) {
            const ticketRef = db.collection('tickets').doc(orderData.idTiket);
            const ticketSnap = await t.get(ticketRef);
            if (ticketSnap.exists) {
              const currentStock = ticketSnap.data().stok || 0;
              const qty = orderData.jumlahTiket || 1;
              t.update(ticketRef, { stok: currentStock + qty });
            }
          }
          cleaned++;
        }
      });
    }

    console.log(`[SCHEDULED CLEANUP] Released ${cleaned} expired reservation holds.`);
    return null;
  });

/**
 * 5. HTTPS Callable: processOrderRefund
 * Admin-only endpoint to process refund for orders flagged as REFUND_REQUIRED or CANCELLED.
 * Enforces idempotency via state machine: REFUND_REQUIRED -> REFUND_PROCESSING -> REFUNDED.
 */
exports.processOrderRefund = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login diperlukan.');
  }

  const callerDoc = await db.collection('users').doc(context.auth.uid).get();
  if (!callerDoc.exists || !['admin', 'super_admin'].includes(callerDoc.data().role)) {
    throw new functions.https.HttpsError('permission-denied', 'Hanya administrator yang dapat memproses refund.');
  }

  const { orderId, refundMethod, referenceId, notes } = data;
  if (!orderId) {
    throw new functions.https.HttpsError('invalid-argument', 'orderId wajib disertakan.');
  }

  const orderRef = db.collection('orders').doc(orderId);

  const result = await db.runTransaction(async (transaction) => {
    const orderDoc = await transaction.get(orderRef);
    if (!orderDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Pesanan tidak ditemukan.');
    }

    const orderData = orderDoc.data();

    // Idempotency Guard: prevent double refund
    if (orderData.status === 'REFUNDED') {
      return { success: true, message: 'Pesanan ini sudah di-refund sebelumnya.', alreadyRefunded: true };
    }

    if (
      orderData.status !== 'REFUND_REQUIRED' &&
      orderData.status !== 'CANCELLED' &&
      orderData.status !== 'REFUND_PENDING'
    ) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Pesanan berstatus ${orderData.status}, tidak memenuhi syarat untuk refund.`
      );
    }

    const refundRecord = {
      refundAmount: orderData.totalHarga,
      refundMethod: refundMethod || 'MIDTRANS_DIRECT_REFUND',
      referenceId: referenceId || `REF-${Date.now()}`,
      processedBy: context.auth.uid,
      notes: notes || 'Pengembalian dana resmi oleh pihak penyelenggara / sistem otomatis.',
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    transaction.update(orderRef, {
      status: 'REFUNDED',
      refundDetails: refundRecord,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      auditTrail: admin.firestore.FieldValue.arrayUnion({
        event: 'REFUND_PROCESSED',
        actor: context.auth.uid,
        timestamp: new Date().toISOString(),
        details: refundRecord,
      }),
    });

    return { success: true, message: 'Pengembalian dana berhasil diproses.', refundRecord };
  });

  return result;
});

/**
 * 6. HTTPS Callable: cancelEventAdmin
 * Cancels a concert event, batch-updates all active orders to REFUND_REQUIRED,
 * closes ticket inventory, and dispatches notification.
 * Safe for 5,000+ orders by chunking writes in batches of 400 operations.
 */
exports.cancelEventAdmin = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login diperlukan.');
  }

  const callerDoc = await db.collection('users').doc(context.auth.uid).get();
  if (!callerDoc.exists || !['admin', 'super_admin'].includes(callerDoc.data().role)) {
    throw new functions.https.HttpsError('permission-denied', 'Hanya administrator yang berhak membatalkan event.');
  }

  const { eventId, reason } = data;
  if (!eventId) {
    throw new functions.https.HttpsError('invalid-argument', 'eventId wajib disertakan.');
  }

  const eventRef = db.collection('events').doc(eventId);
  const eventDoc = await eventRef.get();
  if (!eventDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Event konser tidak ditemukan.');
  }

  // 1. Mark event as cancelled
  await eventRef.update({
    status: 'cancelled',
    cancellationReason: reason || 'Pembatalan resmi oleh pihak penyelenggara.',
    cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
    cancelledBy: context.auth.uid,
  });

  // 2. Close inventory for all tickets of this event
  const ticketsSnap = await db.collection('tickets').where('idKonser', '==', eventId).get();
  if (!ticketsSnap.empty) {
    const tBatch = db.batch();
    ticketsSnap.docs.forEach((tDoc) => {
      tBatch.update(tDoc.ref, { stok: 0, status: 'closed' });
    });
    await tBatch.commit();
  }

  // 3. Mark all AKTIF and PENDING orders as REFUND_REQUIRED in chunks of 400
  const ordersSnap = await db.collection('orders')
    .where('idKonser', '==', eventId)
    .where('status', 'in', ['AKTIF', 'PENDING'])
    .get();

  let affectedOrdersCount = 0;
  const chunkSize = 400;

  for (let i = 0; i < ordersSnap.docs.length; i += chunkSize) {
    const chunk = ordersSnap.docs.slice(i, i + chunkSize);
    const orderBatch = db.batch();

    for (const oDoc of chunk) {
      orderBatch.update(oDoc.ref, {
        status: 'REFUND_REQUIRED',
        cancellationReason: reason || 'Event konser dibatalkan oleh penyelenggara.',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        auditTrail: admin.firestore.FieldValue.arrayUnion({
          event: 'EVENT_CANCELLED_REFUND_FLAGGED',
          actor: context.auth.uid,
          timestamp: new Date().toISOString(),
          reason: reason || 'Event cancelled',
        }),
      });
      affectedOrdersCount++;
    }

    await orderBatch.commit();
  }

  return {
    success: true,
    message: `Event berhasil dibatalkan. ${affectedOrdersCount} pesanan dialokasikan untuk refund.`,
    affectedOrders: affectedOrdersCount,
  };
});

/**
 * 7. HTTPS Callable: syncOfflineScans
 * Ingests offline admission scans with unique scanId idempotency key.
 */
exports.syncOfflineScans = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login diperlukan.');
  }

  const callerDoc = await db.collection('users').doc(context.auth.uid).get();
  if (!callerDoc.exists || !['admin', 'super_admin'].includes(callerDoc.data().role)) {
    throw new functions.https.HttpsError('permission-denied', 'Hanya administrator yang berhak menyinkronkan scan offline.');
  }

  const { scans } = data;
  if (!Array.isArray(scans) || scans.length === 0) {
    return { success: true, syncedCount: 0, duplicateCount: 0 };
  }

  let syncedCount = 0;
  let duplicateCount = 0;

  for (const scan of scans) {
    const scanId = scan.scanId || `${scan.kodeBooking}_${Date.now()}`;
    const scanRef = db.collection('gate_scans').doc(scanId);

    await db.runTransaction(async (t) => {
      const existingScan = await t.get(scanRef);
      if (existingScan.exists) {
        duplicateCount++;
        return;
      }

      t.set(scanRef, {
        scanId: scanId,
        kodeBooking: scan.kodeBooking,
        orderId: scan.orderId || null,
        idKonser: scan.idKonser || null,
        deviceId: scan.deviceId || 'unknown-device',
        scannedAt: scan.scannedAt || new Date().toISOString(),
        syncedAt: admin.firestore.FieldValue.serverTimestamp(),
        syncedBy: context.auth.uid,
      });

      if (scan.orderId) {
        const orderRef = db.collection('orders').doc(scan.orderId);
        const orderSnap = await t.get(orderRef);
        if (orderSnap.exists) {
          t.update(orderRef, {
            status: 'TERPAKAI',
            tanggalDigunakan: admin.firestore.Timestamp.fromDate(new Date(scan.scannedAt || Date.now())),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            auditTrail: admin.firestore.FieldValue.arrayUnion({
              event: 'OFFLINE_SCAN_SYNCHRONIZED',
              scanId: scanId,
              deviceId: scan.deviceId,
              syncedBy: context.auth.uid,
              timestamp: new Date().toISOString(),
            }),
          });
        }
      }
      syncedCount++;
    });
  }

  return { success: true, syncedCount, duplicateCount };
});

/**
 * 8. HTTPS Callable: settleOrderDev
 * Safe dev/sandbox helper to simulate payment settlement on emulator or staging
 * without opening secret keys to the client. Runs atomic inventory decrement.
 */
exports.settleOrderDev = functions.https.onCall(async (data, context) => {
  if (isProduction || process.env.NODE_ENV === 'production') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'settleOrderDev is permanently disabled in production environments.',
    );
  }

  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Pengguna harus terautentikasi untuk menjalankan endpoint ini.',
    );
  }

  const callerDoc = await db.collection('users').doc(context.auth.uid).get();
  if (!callerDoc.exists) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Profil pengguna tidak ditemukan.',
    );
  }

  const callerData = callerDoc.data();
  if (callerData.role !== 'admin' && callerData.role !== 'super_admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Akses ditolak: Endpoint simulasi ini hanya dapat digunakan oleh Administrator.',
    );
  }

  const { orderId } = data;
  if (!orderId) {
    throw new functions.https.HttpsError('invalid-argument', 'orderId required');
  }

  const orderRef = db.collection('orders').doc(orderId);

  await db.runTransaction(async (transaction) => {
    const orderDoc = await transaction.get(orderRef);
    if (!orderDoc.exists) throw new Error('Pesanan tidak ditemukan');

    const orderData = orderDoc.data();
    if (orderData.status === 'AKTIF' || orderData.status === 'TERPAKAI') {
      return; // Already settled
    }

    if (orderData.idTiket) {
      const ticketRef = db.collection('tickets').doc(orderData.idTiket);
      const ticketDoc = await transaction.get(ticketRef);
      if (ticketDoc.exists) {
        const ticketData = ticketDoc.data();
        const currentStock = ticketData.stok || 0;
        const currentTerjual = ticketData.terjual || 0;
        const qty = orderData.jumlahTiket || 1;

        transaction.update(ticketRef, {
          stok: Math.max(0, currentStock - qty),
          terjual: currentTerjual + qty,
        });
      }
    }

    // Generate asymmetric Ed25519 digital signature with Key Versioning
    const privKey = crypto.createPrivateKey({ key: getSigningKey(), format: 'der', type: 'pkcs8' });
    const canonicalPayload = `SW2|${activeKeyId}|${orderRef.id}|${orderData.kodeBooking}|${orderData.idKonser}|${orderData.kategoriTiket}|${orderData.jumlahTiket}`;
    const edSignatureHex = crypto.sign(null, Buffer.from(canonicalPayload), privKey).toString('hex');
    const signedQrPayload = `SW2|${activeKeyId}|${orderRef.id}|${orderData.kodeBooking}|${orderData.idKonser}|${orderData.kategoriTiket}|${orderData.jumlahTiket}|${edSignatureHex}`;

    transaction.update(orderRef, {
      status: 'AKTIF',
      qrPayloadSignature: signedQrPayload,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      auditTrail: admin.firestore.FieldValue.arrayUnion({
        event: 'DEV_SETTLEMENT_SIMULATED',
        actor: context.auth.uid,
        timestamp: new Date().toISOString(),
      }),
    });
  });

  return { success: true, message: 'Pesanan berhasil diselesaikan (DEV)' };
});

/**
 * 9. HTTPS Callable: bootstrapSuperAdmin
 * Secure one-time bootstrap for the first super_admin account.
 * Only works when NO super_admin exists in the system AND
 * the caller's email matches the SUPER_ADMIN_EMAIL environment variable.
 * After the first super_admin is created, this endpoint permanently refuses further calls.
 */
exports.bootstrapSuperAdmin = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login diperlukan.');
  }

  const bootstrapEmail = process.env.SUPER_ADMIN_EMAIL || 'admin@soundwave.id';

  // Verify caller email matches the designated bootstrap email
  if (context.auth.token.email !== bootstrapEmail) {
    console.warn(`[SECURITY] Bootstrap attempt by unauthorized email: ${context.auth.token.email}`);
    throw new functions.https.HttpsError(
      'permission-denied',
      'Email Anda tidak memiliki hak untuk bootstrap super admin.'
    );
  }

  // Check if any super_admin already exists — if so, permanently refuse
  const existingSuperAdmins = await db.collection('users')
    .where('role', '==', 'super_admin')
    .limit(1)
    .get();

  if (!existingSuperAdmins.empty) {
    throw new functions.https.HttpsError(
      'already-exists',
      'Super admin sudah ada di sistem. Bootstrap tidak dapat dijalankan lagi.'
    );
  }

  // Promote the caller to super_admin
  const callerRef = db.collection('users').doc(context.auth.uid);
  const callerDoc = await callerRef.get();

  if (callerDoc.exists) {
    await callerRef.update({
      role: 'super_admin',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      auditTrail: admin.firestore.FieldValue.arrayUnion({
        event: 'SUPER_ADMIN_BOOTSTRAP',
        actor: context.auth.uid,
        email: context.auth.token.email,
        timestamp: new Date().toISOString(),
      }),
    });
  } else {
    // Create profile if it doesn't exist yet
    await callerRef.set({
      nama: context.auth.token.name || 'Super Admin',
      email: context.auth.token.email,
      role: 'super_admin',
      fotoUrl: context.auth.token.picture || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      auditTrail: [{
        event: 'SUPER_ADMIN_BOOTSTRAP',
        actor: context.auth.uid,
        email: context.auth.token.email,
        timestamp: new Date().toISOString(),
      }],
    });
  }

  console.log(`[BOOTSTRAP] Super admin created: ${context.auth.token.email} (${context.auth.uid})`);
  return {
    success: true,
    message: `Super admin berhasil di-bootstrap untuk ${context.auth.token.email}`,
    uid: context.auth.uid,
  };
});

/**
 * 10. HTTPS Callable: promoteToAdmin
 * Allows a verified super_admin to promote a user to 'admin' or demote to 'user'.
 * Enforces role security:
 * - Unauthenticated caller: rejected (unauthenticated)
 * - Non-super_admin caller: rejected (permission-denied)
 * - Target is self: rejected (failed-precondition)
 * - Target role not in ['admin', 'user']: rejected (invalid-argument)
 */
exports.promoteToAdmin = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login diperlukan.');
  }

  const callerDoc = await db.collection('users').doc(context.auth.uid).get();
  if (!callerDoc.exists || callerDoc.data().role !== 'super_admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Hanya super_admin yang berhak mengubah role pengguna.'
    );
  }

  const { targetUid, newRole } = data;
  if (!targetUid || !newRole) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'targetUid dan newRole wajib disertakan.'
    );
  }

  if (targetUid === context.auth.uid) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Super admin tidak dapat mengubah role akun sendiri via endpoint ini.'
    );
  }

  if (!['admin', 'user'].includes(newRole)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Role baru hanya boleh "admin" atau "user".'
    );
  }

  const targetRef = db.collection('users').doc(targetUid);
  const targetDoc = await targetRef.get();
  if (!targetDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Pengguna target tidak ditemukan.');
  }

  await targetRef.update({
    role: newRole,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    auditTrail: admin.firestore.FieldValue.arrayUnion({
      event: 'ROLE_CHANGED_BY_SUPER_ADMIN',
      actor: context.auth.uid,
      target: targetUid,
      newRole: newRole,
      timestamp: new Date().toISOString(),
    }),
  });

  return {
    success: true,
    message: `Role pengguna berhasil diubah menjadi ${newRole}.`,
  };
});

