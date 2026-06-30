import 'package:flutter/foundation.dart';
import '../services/wallet_service.dart';
import '../../../models/wallet_balance.dart';
import '../../../models/transaction.dart';

enum WalletState { initial, loading, loaded, error }

class WalletProvider extends ChangeNotifier {
  final WalletService _service = WalletService();

  WalletState _state = WalletState.initial;
  WalletBalance? _balance;
  List<Transaction> _transactions = [];
  String? _errorMessage;
  bool _balanceVisible = true;

  WalletState get state => _state;
  WalletBalance? get balance => _balance;
  List<Transaction> get transactions => _transactions;
  List<Transaction> get recentTransactions => _transactions.take(5).toList();
  String? get errorMessage => _errorMessage;
  bool get balanceVisible => _balanceVisible;

  void toggleBalanceVisibility() {
    _balanceVisible = !_balanceVisible;
    notifyListeners();
  }

  Future<void> loadData(String phone) async {
    _state = WalletState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getBalance(phone),
        _service.getTransactions(phone),
      ]);
      _balance = results[0] as WalletBalance;
      _transactions = results[1] as List<Transaction>;
      _state = WalletState.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _state = WalletState.error;
    }
    notifyListeners();
  }

  Future<void> refresh(String phone) => loadData(phone);

  void reset() {
    _state = WalletState.initial;
    _balance = null;
    _transactions = [];
    _errorMessage = null;
    notifyListeners();
  }
}
