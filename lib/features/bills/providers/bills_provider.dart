import 'package:flutter/foundation.dart';
import '../services/bills_service.dart';
import '../../../models/facture.dart';

enum BillsState { initial, loading, loaded, error, paying }

class BillsProvider extends ChangeNotifier {
  final BillsService _service = BillsService();

  BillsState _state = BillsState.initial;
  List<Facture> _factures = [];
  String? _errorMessage;

  BillsState get state => _state;
  List<Facture> get factures => _factures;
  String? get errorMessage => _errorMessage;
  List<Facture> get selectedFactures =>
      _factures.where((f) => f.isSelected).toList();
  double get totalSelected =>
      selectedFactures.fold(0, (sum, f) => sum + f.montant);

  Future<void> loadFactures(String phone) async {
    _state = BillsState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _factures = await _service.getFactures(phone);
      _state = BillsState.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _state = BillsState.error;
    }
    notifyListeners();
  }

  void toggleSelection(String id) {
    final index = _factures.indexWhere((f) => f.id == id);
    if (index != -1) {
      _factures[index].isSelected = !_factures[index].isSelected;
      notifyListeners();
    }
  }

  void selectAll(bool select) {
    for (final f in _factures) {
      f.isSelected = select;
    }
    notifyListeners();
  }

  Future<bool> paySelected(String phone) async {
    if (selectedFactures.isEmpty) return false;
    _state = BillsState.paying;
    notifyListeners();
    try {
      await _service.payFactures(
        phone: phone,
        factureIds: selectedFactures.map((f) => f.id).toList(),
      );
      await loadFactures(phone);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _state = BillsState.error;
      notifyListeners();
      return false;
    }
  }
}
