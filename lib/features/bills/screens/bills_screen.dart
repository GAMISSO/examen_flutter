import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bills_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/facture.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final phone = context.read<AuthProvider>().phone;
      if (phone != null) {
        context.read<BillsProvider>().loadFactures(phone);
      }
    });
  }

  Future<void> _paySelected() async {
    final provider = context.read<BillsProvider>();
    final phone = context.read<AuthProvider>().phone!;
    if (provider.selectedFactures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sélectionnez au moins une facture'),
            backgroundColor: AppTheme.error),
      );
      return;
    }

    final formatter = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'XOF', decimalDigits: 0);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmer le paiement',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${provider.selectedFactures.length} facture(s) sélectionnée(s)',
              style: const TextStyle(color: AppTheme.textLight),
            ),
            const SizedBox(height: 8),
            Text(
              'Total : ${formatter.format(provider.totalSelected)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.textDark),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Payer')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await provider.paySelected(phone);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Factures payées avec succès !'),
            backgroundColor: AppTheme.secondary),
      );
    } else if (provider.state == BillsState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.errorMessage ?? 'Erreur de paiement'),
            backgroundColor: AppTheme.error),
      );
    }
  }

  IconData _iconForProvider(String name) {
    switch (name.toLowerCase()) {
      case 'senelec':
        return Icons.electrical_services;
      case 'woyafal':
        return Icons.local_fire_department;
      case 'rapido':
        return Icons.delivery_dining;
      case 'ism':
        return Icons.school;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement de factures'),
        actions: [
          Consumer<BillsProvider>(
            builder: (_, provider, __) {
              if (provider.state != BillsState.loaded ||
                  provider.factures.isEmpty) {
                return const SizedBox();
              }
              final allSelected =
                  provider.factures.every((f) => f.isSelected);
              return TextButton(
                onPressed: () => provider.selectAll(!allSelected),
                child: Text(
                  allSelected ? 'Désélectionner' : 'Tout sélectionner',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<BillsProvider>(
        builder: (context, provider, _) {
          if (provider.state == BillsState.loading) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (provider.state == BillsState.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.error, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage ?? 'Erreur de connexion',
                      style: const TextStyle(color: AppTheme.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => provider.loadFactures(
                          context.read<AuthProvider>().phone!),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.factures.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      color: AppTheme.secondary, size: 72),
                  SizedBox(height: 16),
                  Text('Aucune facture impayée',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  SizedBox(height: 6),
                  Text('Vous êtes à jour !',
                      style:
                          TextStyle(fontSize: 13, color: AppTheme.textLight)),
                ],
              ),
            );
          }

          final formatter = NumberFormat.currency(
              locale: 'fr_FR', symbol: 'XOF', decimalDigits: 0);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.factures.length,
                  itemBuilder: (_, i) {
                    final facture = provider.factures[i];
                    return _FactureTile(
                      facture: facture,
                      icon: _iconForProvider(facture.fournisseur),
                      formatter: formatter,
                      onTap: () => provider.toggleSelection(facture.id),
                    );
                  },
                ),
              ),
              // Barre de paiement
              if (provider.selectedFactures.isNotEmpty)
                _PaymentBar(
                  provider: provider,
                  formatter: formatter,
                  onPay: _paySelected,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FactureTile extends StatelessWidget {
  final Facture facture;
  final IconData icon;
  final NumberFormat formatter;
  final VoidCallback onTap;

  const _FactureTile({
    required this.facture,
    required this.icon,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: facture.isSelected ? AppTheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    facture.fournisseur,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textDark),
                  ),
                  Text(
                    'Réf : ${facture.reference}',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textLight),
                  ),
                  if (facture.dateEcheance != null)
                    Text(
                      'Échéance : ${facture.dateEcheance}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.error),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatter.format(facture.montant),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textDark),
                ),
                const SizedBox(height: 4),
                Checkbox(
                  value: facture.isSelected,
                  onChanged: (_) => onTap(),
                  activeColor: AppTheme.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentBar extends StatelessWidget {
  final BillsProvider provider;
  final NumberFormat formatter;
  final VoidCallback onPay;

  const _PaymentBar(
      {required this.provider,
      required this.formatter,
      required this.onPay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${provider.selectedFactures.length} facture(s)',
                style:
                    const TextStyle(color: AppTheme.textLight, fontSize: 13),
              ),
              Text(
                formatter.format(provider.totalSelected),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed:
                  provider.state == BillsState.paying ? null : onPay,
              icon: provider.state == BillsState.paying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Icon(Icons.payment),
              label: Text(
                  'Payer ${formatter.format(provider.totalSelected)}'),
            ),
          ),
        ],
      ),
    );
  }
}
