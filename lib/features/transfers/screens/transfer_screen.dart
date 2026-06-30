import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/services/wallet_service.dart';
import '../../../core/theme/app_theme.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _receiverController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _amount = '0';
  bool _isLoading = false;

  void _appendDigit(String digit) {
    setState(() {
      if (digit == '000' && _amount == '0') return;
      if (_amount == '0') {
        _amount = digit;
      } else {
        _amount += digit;
      }
    });
  }

  void _deleteDigit() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final parsedAmount = double.tryParse(_amount) ?? 0;
    if (parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Entrez un montant valide'),
            backgroundColor: AppTheme.error),
      );
      return;
    }

    final phone = context.read<AuthProvider>().phone!;
    final receiver = _receiverController.text.trim();
    final formatter = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'XOF', decimalDigits: 0);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmer le transfert',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ConfirmRow(
                label: 'De', value: phone, icon: Icons.person_outline),
            const SizedBox(height: 12),
            _ConfirmRow(
                label: 'À', value: receiver, icon: Icons.person),
            const SizedBox(height: 12),
            _ConfirmRow(
                label: 'Montant',
                value: formatter.format(parsedAmount),
                icon: Icons.payments_outlined),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmer')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await WalletService().transfer(
        senderPhone: phone,
        receiverPhone: receiver,
        amount: parsedAmount,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Transfert effectué avec succès !'),
            backgroundColor: AppTheme.secondary),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _receiverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'XOF', decimalDigits: 0);
    final parsedAmount = double.tryParse(_amount) ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text("Transfert d'argent")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Affichage du montant
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 28, horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, Color(0xFF0D47A1)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text('Montant à envoyer',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 10),
                          Text(
                            formatter.format(parsedAmount),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Champ destinataire
                    TextFormField(
                      controller: _receiverController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Numéro du destinataire',
                        hintText: '771234567',
                        prefixIcon: Icon(Icons.person),
                        prefixText: '+221 ',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Entrez le numéro du destinataire';
                        }
                        if (v.length < 9) return 'Numéro invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Pavé numérique
                    _buildNumpad(),
                  ],
                ),
              ),
            ),
          ),
          // Bouton envoyer
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2))
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Icon(Icons.send),
                label: const Text('Envoyer'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpad() {
    final keys = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '000', '0', '⌫',
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: keys.length,
      itemBuilder: (_, i) {
        final key = keys[i];
        final isDelete = key == '⌫';
        return GestureDetector(
          onTap: () => isDelete ? _deleteDigit() : _appendDigit(key),
          child: Container(
            decoration: BoxDecoration(
              color: isDelete
                  ? AppTheme.error.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDelete ? AppTheme.error.withValues(alpha: 0.3) : AppTheme.cardBorder),
            ),
            child: Center(
              child: isDelete
                  ? const Icon(Icons.backspace_outlined,
                      color: AppTheme.error, size: 22)
                  : Text(key,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
            ),
          ),
        );
      },
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ConfirmRow(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textLight),
        const SizedBox(width: 8),
        Text('$label : ',
            style: const TextStyle(color: AppTheme.textLight, fontSize: 13)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
