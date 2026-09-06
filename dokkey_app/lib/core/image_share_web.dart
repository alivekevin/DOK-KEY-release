// ignore_for_file: deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// Web implementation: triggers a browser download (9:16 PNG)
Future<bool> savePngImpl(Uint8List bytes, String filename) async {
  try {
    final blob = html.Blob([bytes], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    return true;
  } catch (_) {
    return false;
  }
}
