import 'dart:typed_data';

/// Default no-op implementation (used on unexpected platforms)
Future<bool> savePngImpl(Uint8List bytes, String filename) async => false;
