import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'auth_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  bool get isFirebaseAvailable => AuthService().isFirebaseAvailable;

  // Upload task image and return the download URL
  Future<String> uploadTaskImage({
    required String taskId,
    required String userId,
    required dynamic imageFile, // Expecting XFile from image_picker
    required Uint8List? webImageBytes, // Bytes for web upload
  }) async {
    if (isFirebaseAvailable) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(userId)
          .child('tasks')
          .child(taskId)
          .child('photo.jpg');

      if (kIsWeb) {
        if (webImageBytes == null) {
          throw Exception('Web image bytes are required for web upload.');
        }
        // Upload bytes
        final uploadTask = storageRef.putData(
          webImageBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      } else {
        // Upload file (mobile/desktop)
        final uploadTask = storageRef.putFile(File(imageFile.path));
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      }
    } else {
      // Mock Storage Upload Delay
      await Future.delayed(const Duration(seconds: 1));
      // Return a premium random image based on taskId seed
      return 'https://picsum.photos/seed/$taskId/800/600';
    }
  }
}
