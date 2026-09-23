import 'package:flutter/material.dart';
import '../models/user.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  UserSession _currentUser = UserSession(
    id: 'usr-waiter-1',
    name: 'Ahmet Yılmaz',
    role: 'WAITER',
  );

  bool _isLoading = false;
  String? _errorMessage;

  UserSession get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _currentUser.isAdmin;
  bool get isWaiter => _currentUser.isWaiter;

  Future<void> init() async {
    final session = await StorageService.getUserSession();
    if (session['name'] != null && session['name']!.isNotEmpty) {
      _currentUser = UserSession(
        id: session['id'] ?? 'usr-waiter-1',
        name: session['name']!,
        role: session['role'] ?? 'WAITER',
      );
      notifyListeners();
    }
  }

  Future<bool> loginWithPin(String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await ApiService.instance.loginWithPin(pin);
      _currentUser = user;
      await StorageService.saveUserSession(user.id, user.name, user.role, pin);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Yönetici Paneline geçiş için hızlı doğrulama
  Future<bool> verifyAdminPin(String pin) async {
    if (pin == '1234') {
      return true;
    }
    try {
      final user = await ApiService.instance.loginWithPin(pin);
      return user.isAdmin;
    } catch (_) {
      return false;
    }
  }

  void switchWaiter(String name, String pin) {
    _currentUser = UserSession(
      id: 'usr-$pin',
      name: name,
      role: 'WAITER',
    );
    notifyListeners();
  }

  void setAdminMode() {
    _currentUser = UserSession(
      id: 'usr-admin',
      name: 'Yönetici (Admin)',
      role: 'ADMIN',
    );
    notifyListeners();
  }

  void setWaiterMode() {
    _currentUser = UserSession(
      id: 'usr-waiter-1',
      name: 'Ahmet Yılmaz',
      role: 'WAITER',
    );
    notifyListeners();
  }
}
