import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tide/firebase_options.dart';
import 'package:tide/providers/auth_provider.dart';
import 'package:tide/providers/task_provider.dart';
import 'package:tide/services/auth_service.dart';
import 'package:tide/theme/app_theme.dart';
import 'package:tide/views/auth/auth_screen.dart';
import 'package:tide/views/dashboard/dashboard_screen.dart';
import 'package:tide/views/task/shared_task_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool firebaseSuccess = false;
  try {
    final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
    if (!apiKey.startsWith('PLACEHOLDER')) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseSuccess = true;
      debugPrint("Firebase initialized successfully.");
    }
  } catch (e) {
    debugPrint("Firebase init check failed: $e");
  }

  if (!firebaseSuccess) {
    debugPrint("Defaulting to Tide Offline Mock Mode.");
    AuthService().isMockMode = true;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: const TideApp(),
    ),
  );
}

class TideApp extends StatelessWidget {
  const TideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    // Check if the URL contains a task share token (taskId)
    final uri = Uri.base;
    String? sharedTaskId;

    if (uri.queryParameters.containsKey('taskId')) {
      sharedTaskId = uri.queryParameters['taskId'];
    } else {
      final fragment = uri.fragment;
      if (fragment.contains('taskId=')) {
        final parts = fragment.split('taskId=');
        if (parts.length > 1) {
          sharedTaskId = parts[1].split('&').first;
        }
      }
    }

    if (sharedTaskId != null && sharedTaskId.isNotEmpty) {
      return SharedTaskScreen(taskId: sharedTaskId);
    }
    
    if (auth.isAuthenticated) {
      return const DashboardScreen();
    } else {
      return const AuthScreen();
    }
  }
}
