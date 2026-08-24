class Installment {
  final String id;
  final String monthName;
  final double amount;
  final double paidAmount;
  final String status;
  final DateTime? paidAt;

  Installment({
    required this.id,
    required this.monthName,
    required this.amount,
    required this.paidAmount,
    required this.status,
    this.paidAt,
  });

  factory Installment.fromJson(Map<String, dynamic> json) {
    return Installment(
      id: json['id'],
      monthName: json['month_name'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      paidAmount: double.tryParse(json['paid_amount'].toString()) ?? 0,
      status: json['status'] ?? 'unpaid',
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'].toString())
          : null,
    );
  }

  bool get isPaid => status == 'paid';

  /// Retourne la date formatée en français : "12 janvier 2025 à 14h30"
  String get formattedPaidAt {
    if (paidAt == null) return '-';
    const months = [
      '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    final d = paidAt!.toLocal();
    return '${d.day} ${months[d.month]} ${d.year} à ${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
  }
}