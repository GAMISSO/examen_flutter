class Facture {
  final String id;
  final String fournisseur;
  final double montant;
  final String reference;
  final String? dateEcheance;
  bool isSelected;

  Facture({
    required this.id,
    required this.fournisseur,
    required this.montant,
    required this.reference,
    this.dateEcheance,
    this.isSelected = false,
  });

  factory Facture.fromJson(Map<String, dynamic> json) {
    return Facture(
      id: json['id']?.toString() ?? '',
      fournisseur: json['fournisseur'] ?? json['provider'] ?? json['nom'] ?? '',
      montant: (json['montant'] ?? json['amount'] ?? json['prix'] ?? 0)
          .toDouble(),
      reference:
          json['reference'] ?? json['ref'] ?? json['numero'] ?? json['id']?.toString() ?? '',
      dateEcheance: json['dateEcheance']?.toString() ??
          json['dueDate']?.toString() ??
          json['echeance']?.toString(),
    );
  }
}
