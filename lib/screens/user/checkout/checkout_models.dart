import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Satu opsi metode pembayaran yang ditampilkan pada langkah pertama.
///
/// Dulu bernama `_PaymentMethod` dan bersarang di `checkout_screen.dart`.
class PaymentMethod {
  final String id;
  final String title;
  final IconData icon;
  final String subtitle;

  const PaymentMethod(this.id, this.title, this.icon, this.subtitle);
}

/// Format nomor kartu menjadi grup 4 digit: `1234 5678 9012 3456`.
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 16) digits = digits.substring(0, 16);
    final groups = <String>[];
    for (var i = 0; i < digits.length; i += 4) {
      var end = i + 4;
      if (end > digits.length) end = digits.length;
      groups.add(digits.substring(i, end));
    }
    final formatted = groups.join(' ');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Format masa berlaku kartu menjadi `MM/YY`.
class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    String text;
    if (digits.length <= 2) {
      text = digits;
    } else {
      text = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Daftar metode pembayaran yang didukung, sesuai urutan tampil.
const List<PaymentMethod> kPaymentMethods = [
  PaymentMethod(
      'va', 'Transfer Bank', Icons.account_balance, 'BCA, BNI, Mandiri'),
  PaymentMethod(
      'card', 'Kartu Kredit/Debit', Icons.credit_card, 'Visa, Mastercard'),
  PaymentMethod('gopay', 'GoPay', Icons.wallet, 'Bayar dengan GoPay'),
  PaymentMethod('qris', 'QRIS', Icons.qr_code, 'Scan untuk bayar'),
];
