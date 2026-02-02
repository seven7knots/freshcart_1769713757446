import 'package:flutter/foundation.dart';
import '../models/merchant_model.dart';
import '../services/merchant_service.dart';

class MerchantProvider extends ChangeNotifier {
  Merchant? _merchant;
  bool _isLoading = false;
  String? _error;

  Merchant? get merchant => _merchant;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load merchant for current user
  Future<void> loadMyMerchant(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _merchant = await MerchantService.getMyMerchant(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('[MERCHANT] error in loadMyMerchant: $e');
    }
  }

  /// Create merchant
  Future<bool> createMerchant(
      String userId, Map<String, dynamic> payload) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _merchant = await MerchantService.createMyMerchant(userId, payload);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('[MERCHANT] error in createMerchant: $e');
      return false;
    }
  }

  /// Update merchant
  Future<bool> updateMerchant(
      String merchantId, Map<String, dynamic> updates) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _merchant = await MerchantService.updateMyMerchant(merchantId, updates);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('[MERCHANT] error in updateMerchant: $e');
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
