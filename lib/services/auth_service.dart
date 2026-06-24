import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initMockUser();
    _initGoogleSignIn();
  }

  bool _isMockMode = true; // FORCE MOCK MODE TO BYPASS FIREBASE AUTH ERRORS
  bool get isMockMode => _isMockMode;
  set isMockMode(bool val) {
    _isMockMode = val;
    _controller.add(currentUser);
  }

  // Check if Firebase is initialized and ready
  bool get isFirebaseAvailable => false; // FORCE FALSE TO USE MOCK AUTH

  UserProfile? _mockUser;
  final _controller = StreamController<UserProfile?>.broadcast();

  void _initMockUser() {
    _mockUser = null;
  }

  Future<void> _initGoogleSignIn() async {}

  // Get current user profile
  UserProfile? get currentUser {
    return _mockUser;
  }

  // Stream of auth changes
  Stream<UserProfile?> get authStateChanges {
    return _controller.stream;
  }

  // Sign In with Email/Password
  Future<UserProfile> signInWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _mockUser = UserProfile(
      uid: email, // Use email as unique deterministic ID for Firestore
      email: email,
      displayName: email.split('@').first,
      photoUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=${email.split('@').first}',
    );
    _controller.add(_mockUser);
    return _mockUser!;
  }

  // Sign Up with Email/Password
  Future<UserProfile> signUpWithEmail(String email, String password, String name) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _mockUser = UserProfile(
      uid: email, // Use email as unique deterministic ID
      email: email,
      displayName: name,
      photoUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=$name',
    );
    _controller.add(_mockUser);
    return _mockUser!;
  }

  // Sign In with Google
  Future<UserProfile> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 800));
    _mockUser = UserProfile(
      uid: 'mock_google_user',
      email: 'Tide.user@gmail.com',
      displayName: 'Tide Premium User',
      photoUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=Tide',
    );
    _controller.add(_mockUser);
    return _mockUser!;
  }

  // Sign Out
  Future<void> signOut() async {
    _mockUser = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}
