class Transaction {
  final String id;
  final String type;
  final double amount;
  final String description;
  final String date;
  final String? senderPhone;
  final String? receiverPhone;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.senderPhone,
    this.receiverPhone,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      amount: (json['amount'] ?? json['montant'] ?? 0).toDouble(),
      description: json['description'] ?? json['libelle'] ?? '',
      date: json['date'] ?? json['createdAt'] ?? json['dateTransaction'] ?? '',
      senderPhone: json['senderPhone']?.toString() ??
          json['expediteur']?.toString() ??
          json['sender']?.toString(),
      receiverPhone: json['receiverPhone']?.toString() ??
          json['destinataire']?.toString() ??
          json['receiver']?.toString(),
    );
  }

  bool get isCredit {
    final t = type.toLowerCase();
    return t.contains('depot') ||
        t.contains('credit') ||
        t.contains('recu') ||
        t.contains('received') ||
        t.contains('receive') ||
        t.contains('in') ||
        t == 'deposit';
  }
}
