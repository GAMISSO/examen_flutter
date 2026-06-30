import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage;
  String? _phone;

  AuthProvider(this._storage);

  String? get phone => _phone;
  bool get isLoggedIn => _phone != null && _phone!.isNotEmpty;

  Future<void> loadSavedPhone() async {
    _phone = await _storage.read(key: AppConstants.phoneKey);
    notifyListeners();
  }

  Future<void> login(String phone) async {
    await _storage.write(key: AppConstants.phoneKey, value: phone);
    _phone = phone;
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.phoneKey);
    _phone = null;
    notifyListeners();
  }
}
