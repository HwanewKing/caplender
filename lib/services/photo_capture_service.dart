import 'dart:math';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Wraps `image_picker` so the rest of the app uses a stable API.
///
/// We use the system camera/gallery picker (rather than the `camera` package)
/// for Phase 2 — fewer permissions to manage, more familiar UI for 40-50대
/// users, and zero in-app viewfinder code to maintain.
class PhotoCaptureService {
  PhotoCaptureService();

  final ImagePicker _picker = ImagePicker();

  /// Open the native camera. Returns null if the user cancels.
  Future<CapturedPhoto?> captureFromCamera() async {
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 2400,
    );
    return x == null ? null : CapturedPhoto._fromXFile(x);
  }

  /// Open the gallery picker. Returns null if the user cancels.
  Future<CapturedPhoto?> pickFromGallery() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2400,
    );
    return x == null ? null : CapturedPhoto._fromXFile(x);
  }
}

/// Captured image bytes + metadata, decoupled from `XFile` so callers don't
/// depend on the picker package directly.
class CapturedPhoto {
  final Uint8List bytes;
  final String mimeType;
  final String extension;

  const CapturedPhoto({
    required this.bytes,
    required this.mimeType,
    required this.extension,
  });

  static Future<CapturedPhoto> _fromXFile(XFile x) async {
    final bytes = await x.readAsBytes();
    final ext = _extFromPath(x.path);
    return CapturedPhoto(
      bytes: bytes,
      mimeType: _mimeFromExt(ext),
      extension: ext,
    );
  }
}

String _extFromPath(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0) return 'jpg';
  return path.substring(dot + 1).toLowerCase();
}

String _mimeFromExt(String ext) {
  switch (ext) {
    case 'png':
      return 'image/png';
    case 'heic':
    case 'heif':
      return 'image/heic';
    case 'webp':
      return 'image/webp';
    default:
      return 'image/jpeg';
  }
}

/// Generates a 32-char hex string for use as a storage filename. We avoid the
/// `uuid` package since cryptographic randomness is sufficient and a single
/// dependency saved isn't a bad thing.
String newPhotoId() {
  final r = Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
