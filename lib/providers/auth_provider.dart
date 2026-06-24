import 'package:flutter/material.dart';
import 'package:tide/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserProfile? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isMockMode => _authService.isMockMode;

  AuthProvider() {
    // Listen to authentication state changes
    _authService.authStateChanges.listen((UserProfile? userProfile) {
      _user = userProfile;
      _errorMessage = null;
      notifyListeners();
    });
  }

  void setMockMode(bool enabled) {
    _authService.isMockMode = enabled;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      _user = await _authService.signInWithEmail(email, password);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUpWithEmail(String email, String password, String name) async {
    _setLoading(true);
    _clearError();
    try {
      _user = await _authService.signUpWithEmail(email, password, name);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      _user = await _authService.signInWithGoogle();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _user = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
