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

  bool _isMockMode = false;
  bool get isMockMode => _isMockMode;
  set isMockMode(bool val) {
    _isMockMode = val;
    _controller.add(currentUser);
  }

  // Check if Firebase is initialized and ready
  bool get isFirebaseAvailable {
    try {
      Firebase.app();
      return !_isMockMode;
    } catch (_) {
      return false;
    }
  }

  UserProfile? _mockUser;
  final _controller = StreamController<UserProfile?>.broadcast();

  void _initMockUser() {
    _mockUser = null;
  }

  Future<void> _initGoogleSignIn() async {
    if (isFirebaseAvailable) {
      try {
        await GoogleSignIn.instance.initialize();
      } catch (e) {
        debugPrint('GoogleSignIn initialization failed: $e');
      }
    }
  }

  // Get current user profile
  UserProfile? get currentUser {
    if (isFirebaseAvailable) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? user.email?.split('@').first ?? 'User',
          photoUrl: user.photoURL,
        );
      }
      return null;
    } else {
      return _mockUser;
    }
  }

  // Stream of auth changes
  Stream<UserProfile?> get authStateChanges {
    if (isFirebaseAvailable) {
      return FirebaseAuth.instance.authStateChanges().map((user) {
        if (user != null) {
          return UserProfile(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? user.email?.split('@').first ?? 'User',
            photoUrl: user.photoURL,
          );
        }
        return null;
      });
    } else {
      return _controller.stream;
    }
  }

  // Sign In with Email/Password
  Future<UserProfile> signInWithEmail(String email, String password) async {
    if (isFirebaseAvailable) {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      return UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? email.split('@').first,
        photoUrl: user.photoURL,
      );
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      _mockUser = UserProfile(
        uid: 'mock_user_123',
        email: email,
        displayName: email.split('@').first,
        photoUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=${email.split('@').first}',
      );
      _controller.add(_mockUser);
      return _mockUser!;
    }
  }

  // Sign Up with Email/Password
  Future<UserProfile> signUpWithEmail(String email, String password, String name) async {
    if (isFirebaseAvailable) {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(name);
      return UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        displayName: name,
        photoUrl: user.photoURL,
      );
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      _mockUser = UserProfile(
        uid: 'mock_user_123',
        email: email,
        displayName: name,
        photoUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=$name',
      );
      _controller.add(_mockUser);
      return _mockUser!;
    }
  }

  // Sign In with Google
  Future<UserProfile> signInWithGoogle() async {
    if (isFirebaseAvailable) {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      
      if (googleUser == null) {
        throw Exception('Sign in aborted by user');
      }
      
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      
      if (idToken == null) {
        throw Exception('Failed to obtain ID Token from Google.');
      }
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );
      
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user!;
      return UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Google User',
        photoUrl: user.photoURL,
      );
    } else {
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
  }

  // Sign Out
  Future<void> signOut() async {
    if (isFirebaseAvailable) {
      await FirebaseAuth.instance.signOut();
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    } else {
      _mockUser = null;
      _controller.add(null);
    }
  }

  void dispose() {
    _controller.close();
  }
}
