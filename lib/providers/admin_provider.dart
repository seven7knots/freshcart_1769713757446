import 'package:flutter/foundation.dart';

import '../services/admin_service.dart';
import '../services/analytics_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  bool _isAdmin = false;
  bool _isLoading = false;
  String? _error;

  bool _isEditMode = false;

  Map<String, dynamic>? _dashboardStats;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _recentOrders = [];

  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isEditMode => _isEditMode;

  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  List<Map<String, dynamic>> get users => _users;
  List<Map<String, dynamic>> get recentOrders => _recentOrders;

  void setEditMode(bool value) {
    if (_isEditMode == value) return;
    if (!_isAdmin && value) return;
    _isEditMode = value;
    notifyListeners();
  }

  void toggleEditMode() {
    if (!_isAdmin) return;
    _isEditMode = !_isEditMode;
    notifyListeners();
  }

  Future<void> checkAdminStatus() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _isAdmin = await _adminService.isAdmin();

      if (!_isAdmin) {
        _isEditMode = false;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isAdmin = false;
      _isEditMode = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDashboardStats() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _dashboardStats = await _adminService.getDashboardStats();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers({
    String? searchQuery,
    String? filterRole,
    bool? filterStatus,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _users = await _adminService.getUsers(
        searchQuery: searchQuery,
        filterRole: filterRole,
        filterStatus: filterStatus,
        limit: limit,
        offset: offset,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecentOrders({int limit = 10}) async {
    try {
      _recentOrders = await _adminService.getRecentOrders(limit: limit);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load recent orders: $e');
    }
  }

  Future<bool> adjustWalletBalance({
    required String userId,
    required double amount,
    required String reason,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _adminService.adjustWalletBalance(
        userId: userId,
        amount: amount,
        reason: reason,
      );

      if (success) {
        await AnalyticsService.logAdminWalletAdjustment(
          userId: userId,
          amount: amount,
          reason: reason,
        );
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _adminService.updateUserStatus(
        userId: userId,
        isActive: isActive,
      );

      if (success) {
        await AnalyticsService.logAdminUserManagement(
          action: isActive ? 'activate_user' : 'deactivate_user',
          targetUserId: userId,
        );
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserTransactions(String userId) async {
    try {
      return await _adminService.getUserTransactions(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      return await _adminService.getUserOrders(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
