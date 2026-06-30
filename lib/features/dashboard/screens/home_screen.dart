import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/wallet_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../transfers/screens/transfer_screen.dart';
import '../../bills/screens/bills_screen.dart';
import '../../history/screens/history_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/transaction.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final phone = context.read<AuthProvider>().phone;
      if (phone != null) {
        context.read<WalletProvider>().loadData(phone);
      }
    });
  }

  Future<void> _logout() async {
    context.read<WalletProvider>().reset();
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => wallet.refresh(auth.phone!),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(auth, wallet),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildQuickActions(auth, wallet),
                    const SizedBox(height: 24),
                    _buildRecentTransactionsHeader(context),
                    const SizedBox(height: 12),
                    _buildTransactionsList(wallet),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(AuthProvider auth, WalletProvider wallet) {
    final formatter = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'XOF', decimalDigits: 0);

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppTheme.primary,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          tooltip: 'Déconnexion',
          onPressed: _logout,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primary, Color(0xFF0D47A1)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bonjour 👋',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          Text(
                            auth.phone ?? '',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text('Solde disponible',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildBalanceText(wallet, formatter),
                      ),
                      GestureDetector(
                        onTap: wallet.toggleBalanceVisibility,
                        child: Icon(
                          wallet.balanceVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white70,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceText(WalletProvider wallet, NumberFormat formatter) {
    if (wallet.state == WalletState.loading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2),
      );
    }
    if (wallet.state == WalletState.error) {
      return const Text('Erreur de chargement',
          style: TextStyle(color: Colors.white60, fontSize: 14));
    }
    final amount = wallet.balance?.balance ?? 0;
    return Text(
      wallet.balanceVisible ? formatter.format(amount) : '••••••',
      style: const TextStyle(
          color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildQuickActions(AuthProvider auth, WalletProvider wallet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _QuickActionButton(
          icon: Icons.send_rounded,
          label: 'Transférer',
          color: AppTheme.primary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransferScreen()),
          ).then((_) {
            if (auth.phone != null) wallet.refresh(auth.phone!);
          }),
        ),
        _QuickActionButton(
          icon: Icons.receipt_long_rounded,
          label: 'Payer',
          color: AppTheme.secondary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BillsScreen()),
          ).then((_) {
            if (auth.phone != null) wallet.refresh(auth.phone!);
          }),
        ),
        _QuickActionButton(
          icon: Icons.history_rounded,
          label: 'Historique',
          color: const Color(0xFFFF6D00),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Dernières transactions',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark),
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          ),
          child: const Text('Voir tout',
              style: TextStyle(color: AppTheme.primary, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(WalletProvider wallet) {
    if (wallet.state == WalletState.loading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(color: AppTheme.primary),
      ));
    }
    if (wallet.state == WalletState.error) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                wallet.errorMessage ?? 'Erreur de connexion',
                style: const TextStyle(color: AppTheme.error, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    if (wallet.state == WalletState.initial ||
        wallet.recentTransactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Aucune transaction',
              style: TextStyle(color: AppTheme.textLight, fontSize: 14)),
        ),
      );
    }
    return Column(
      children: wallet.recentTransactions
          .map((t) => TransactionTile(transaction: t))
          .toList(),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final color = isCredit ? AppTheme.secondary : AppTheme.error;
    final formatter = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'XOF', decimalDigits: 0);

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
