import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'image_share_impl.dart'
    if (dart.library.html) 'image_share_web.dart'
    if (dart.library.io) 'image_share_io.dart';

class ImageShareService {
  /// Captures a widget wrapped in RepaintBoundary to PNG bytes
  static Future<Uint8List?> capturePng(GlobalKey boundaryKey) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing PNG: $e');
      return null;
    }
  }

  /// Web: triggers a browser PNG download / Native: opens the share sheet
  static Future<bool> saveOrDownloadPng(Uint8List bytes, String filename) {
    return savePngImpl(bytes, filename);
  }
}
