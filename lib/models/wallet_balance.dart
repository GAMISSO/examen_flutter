class WalletBalance {
  final String phone;
  final double balance;
  final String currency;

  WalletBalance({
    required this.phone,
    required this.balance,
    required this.currency,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      phone: json['phone']?.toString() ?? '',
      balance: (json['balance'] ?? json['solde'] ?? 0).toDouble(),
      currency: json['currency'] ?? json['devise'] ?? 'XOF',
    );
  }
}
