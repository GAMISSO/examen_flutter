import '../../../core/network/api_client.dart';
import '../../../models/facture.dart';

class BillsService {
  final ApiClient _client = ApiClient();

  Future<List<Facture>> getFactures(String phone) async {
    final data = await _client.get('/api/external/factures/$phone');
    if (data is List) {
      return data
          .map((json) => Facture.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> payFactures({
    required String phone,
    required List<String> factureIds,
  }) async {
    await _client.post('/api/wallets/pay-factures', {
      'phone': phone,
      'factureIds': factureIds,
    });
  }
}
