import '../../../core/network/api_client.dart';
import '../../../models/wallet_balance.dart';
import '../../../models/transaction.dart';

class WalletService {
  final ApiClient _client = ApiClient();

  Future<WalletBalance> getBalance(String phone) async {
    final data = await _client.get('/api/wallets/$phone/balance');
    return WalletBalance.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Transaction>> getTransactions(String phone) async {
    final data = await _client.get('/api/wallets/$phone/transactions');
    if (data is List) {
      return data
          .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> transfer({
    required String senderPhone,
    required String receiverPhone,
    required double amount,
  }) async {
    await _client.post('/api/wallets/transfer', {
      'senderPhone': senderPhone,
      'receiverPhone': receiverPhone,
      'amount': amount,
    });
  }
}
