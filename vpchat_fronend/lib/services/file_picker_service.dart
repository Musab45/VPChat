import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FilePickerService {
  final ImagePicker _imagePicker = ImagePicker();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final AudioRecorder _audioRecorder = AudioRecorder();

  // Audio recording methods
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String?> startRecording() async {
    try {
      if (!await hasMicrophonePermission()) {
        throw Exception('Microphone permission denied');
      }

      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final fileName =
            'voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final filePath = path.join(directory.path, fileName);

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );

        return filePath;
      } else {
        throw Exception('Audio recording permission denied');
      }
    } catch (e) {
      print('Error starting recording: $e');
      throw Exception('Failed to start recording: $e');
    }
  }

  Future<File?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final file = File(path);
        if (await file.exists() && await file.length() > 0) {
          return file;
        }
      }
      return null;
    } catch (e) {
      print('Error stopping recording: $e');
      throw Exception('Failed to stop recording: $e');
    }
  }

  Future<bool> isRecording() async {
    return await _audioRecorder.isRecording();
  }

  Future<void> cancelRecording() async {
    try {
      await _audioRecorder.cancel();
    } catch (e) {
      print('Error canceling recording: $e');
    }
  }

  // Check if device is running Android 13 or higher
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;

    try {
      AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.version.sdkInt >= 33; // Android 13 is API 33
    } catch (e) {
      // If we can't get device info, assume older Android for safety
      return false;
    }
  }

  // Check if running on any simulator
  Future<bool> _isSimulator() async {
    if (Platform.isIOS) {
      return await _isIOSSimulator();
    }
    // Android emulators don't have the same limitations for gallery access
    // but camera might not work
    return false;
  }

  // Check if running on iOS simulator
  Future<bool> _isIOSSimulator() async {
    if (!Platform.isIOS) return false;

    try {
      IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
      // iOS simulators have specific model identifiers
      final isSimulator =
          iosInfo.model.contains('Simulator') ||
          iosInfo.model.contains('iPhone Simulator') ||
          iosInfo.model.contains('iPad Simulator');
      print(
        'iOS device info - Model: ${iosInfo.model}, Is Simulator: $isSimulator',
      );
      return isSimulator;
    } catch (e) {
      // If we can't get device info, check for common simulator indicators
      final isSimulator =
          Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') ||
          Platform.environment.containsKey('SIMULATOR_MODEL_IDENTIFIER');
      print(
        'iOS simulator detection fallback - Is Simulator: $isSimulator, Error: $e',
      );
      return isSimulator;
    }
  }

  // Pre-request permissions to ensure they're available when needed
  Future<void> ensurePermissions() async {
    try {
      // Skip gallery permissions on iOS simulator
      final isSimulator = await _isSimulator();

      if (Platform.isAndroid) {
        if (await _isAndroid13OrHigher()) {
          // For Android 13+, request photos permission
          await Permission.photos.request();
        } else {
          // For older Android, request storage permission
          await Permission.storage.request();
        }
      } else if (!isSimulator) {
        // For iOS (not simulator), request photos permission
        await Permission.photos.request();
      }

      // Always request camera permission (not available on simulator anyway)
      if (!isSimulator) {
        await Permission.camera.request();
      }
    } catch (e) {
      print('Error ensuring permissions: $e');
    }
  }

  // Check if we can access gallery without explicit permission request
  // This is a fallback for cases where permission dialog doesn't show
  Future<bool> canAccessGallery() async {
    try {
      if (Platform.isAndroid) {
        if (await _isAndroid13OrHigher()) {
          return await Permission.photos.isGranted;
        } else {
          return await Permission.storage.isGranted;
        }
      } else {
        return await Permission.photos.isGranted;
      }
    } catch (e) {
      print('Error checking gallery access: $e');
      return false;
    }
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      // Check if running on simulator
      if (await _isSimulator()) {
        throw Exception(
          'Camera access is not available on Simulator. Please test camera functionality on a physical device.',
        );
      }

      final permission = await Permission.camera.request();
      if (!permission.isGranted) {
        throw Exception('Camera permission denied');
      }

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      throw Exception('Failed to pick image from camera: $e');
    }
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      // Check if running on simulator
      if (await _isSimulator()) {
        throw Exception(
          'Gallery access is not available on Simulator. Please test file sharing on a physical device.',
        );
      }

      PermissionStatus permission;

      if (Platform.isAndroid) {
        // For Android 13+, use photos permission
        // For older Android versions, use storage permission
        if (await _isAndroid13OrHigher()) {
          print('Android 13+ detected, using photos permission');
          permission = await Permission.photos.status;
          print('Photos permission status: $permission');
          if (!permission.isGranted) {
            permission = await Permission.photos.request();
            print('Photos permission after request: $permission');
          }
          // If photos permission is denied, try storage as fallback
          if (!permission.isGranted) {
            print('Photos permission denied, trying storage permission');
            permission = await Permission.storage.status;
            print('Storage permission status: $permission');
            if (!permission.isGranted) {
              permission = await Permission.storage.request();
              print('Storage permission after request: $permission');
            }
          }
        } else {
          print('Android 12 or below detected, using storage permission');
          // For Android 12 and below, use storage permission
          permission = await Permission.storage.status;
          print('Storage permission status: $permission');
          if (!permission.isGranted) {
            permission = await Permission.storage.request();
            print('Storage permission after request: $permission');
          }
        }
      } else {
        print('iOS detected, using photos permission');
        // For iOS and others
        permission = await Permission.photos.status;
        print('Photos permission status: $permission');
        if (!permission.isGranted) {
          permission = await Permission.photos.request();
          print('Photos permission after request: $permission');
        }
      }

      if (permission.isPermanentlyDenied) {
        print('Permission is permanently denied');
        throw Exception(
          'Gallery permission permanently denied. Please enable it in app settings.',
        );
      }

      if (!permission.isGranted) {
        print('Permission not granted');
        throw Exception('Gallery permission denied');
      }

      print('Permission granted, proceeding with image picker');

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  // Pick video from gallery
  Future<File?> pickVideoFromGallery() async {
    try {
      // Check if running on simulator
      if (await _isSimulator()) {
        throw Exception(
          'Gallery access is not available on Simulator. Please test file sharing on a physical device.',
        );
      }

      PermissionStatus permission;

      if (Platform.isAndroid) {
        // For Android 13+, use photos permission
        // For older Android versions, use storage permission
        if (await _isAndroid13OrHigher()) {
          permission = await Permission.photos.status;
          if (!permission.isGranted) {
            permission = await Permission.photos.request();
          }
          // If photos permission is denied, try storage as fallback
          if (!permission.isGranted) {
            permission = await Permission.storage.status;
            if (!permission.isGranted) {
              permission = await Permission.storage.request();
            }
          }
        } else {
          // For Android 12 and below, use storage permission
          permission = await Permission.storage.status;
          if (!permission.isGranted) {
            permission = await Permission.storage.request();
          }
        }
      } else {
        // For iOS and others
        permission = await Permission.photos.status;
        if (!permission.isGranted) {
          permission = await Permission.photos.request();
        }
      }

      if (permission.isPermanentlyDenied) {
        throw Exception(
          'Gallery permission permanently denied. Please enable it in app settings.',
        );
      }

      if (!permission.isGranted) {
        throw Exception('Gallery permission denied');
      }

      final pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      throw Exception('Failed to pick video from gallery: $e');
    }
  }

  // Pick any file
  Future<File?> pickFile() async {
    try {
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        throw Exception('Storage permission denied');
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick file: $e');
    }
  }

  // Get file size in human readable format
  String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Check if file is an image
  bool isImageFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }

  // Check if file is a video
  bool isVideoFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return ['mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv'].contains(extension);
  }

  // Check if file is an audio file
  bool isAudioFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return ['mp3', 'wav', 'aac', 'ogg', 'flac', 'm4a'].contains(extension);
  }
}
