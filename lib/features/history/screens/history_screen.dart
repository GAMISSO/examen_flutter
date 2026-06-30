import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../dashboard/providers/wallet_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/transaction.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final phone = context.read<AuthProvider>().phone;
      final wallet = context.read<WalletProvider>();
      if (phone != null && wallet.state == WalletState.initial) {
        wallet.loadData(phone);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          Consumer<WalletProvider>(
            builder: (_, wallet, __) => IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualiser',
              onPressed: () {
                final phone = context.read<AuthProvider>().phone;
                if (phone != null) wallet.refresh(phone);
              },
            ),
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          if (wallet.state == WalletState.loading) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (wallet.state == WalletState.error) {
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
                      wallet.errorMessage ?? 'Erreur de connexion',
                      style: const TextStyle(color: AppTheme.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        final phone = context.read<AuthProvider>().phone;
                        if (phone != null) wallet.refresh(phone);
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (wallet.transactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 72, color: AppTheme.textLight),
                  SizedBox(height: 16),
                  Text('Aucune transaction',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark)),
                ],
              ),
            );
          }

          final formatter = NumberFormat.currency(
              locale: 'fr_FR', symbol: 'XOF', decimalDigits: 0);

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () =>
                wallet.refresh(context.read<AuthProvider>().phone!),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wallet.transactions.length,
              itemBuilder: (_, i) {
                final t = wallet.transactions[i];
                return _HistoryTile(transaction: t, formatter: formatter);
              },
            ),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Transaction transaction;
  final NumberFormat formatter;

  const _HistoryTile(
      {required this.transaction, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final color = isCredit ? AppTheme.secondary : AppTheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description.isNotEmpty
                      ? transaction.description
                      : transaction.type,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (transaction.date.isNotEmpty)
                  Text(
                    transaction.date,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textLight),
                  ),
                if (transaction.senderPhone != null ||
                    transaction.receiverPhone != null)
                  Text(
                    isCredit
                        ? 'De : ${transaction.senderPhone ?? 'N/A'}'
                        : 'À : ${transaction.receiverPhone ?? 'N/A'}',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textLight),
                  ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}${formatter.format(transaction.amount)}',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
