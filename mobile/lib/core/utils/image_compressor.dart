import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  /// Preprocesses camera pictures to enforce maximum dimension boundaries (1024x1024),
  /// capping Gemini token consumption while maintaining OCR text legibility (Doc_08).
  static Future<File> compressForGemini(File rawFile) async {
    final bytes = await rawFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return rawFile;

    // Constrain resolution boundaries to 1024px maximum edge
    img.Image resized = decoded;
    if (decoded.width > 1024 || decoded.height > 1024) {
      resized = img.copyResize(
        decoded,
        width: decoded.width > decoded.height ? 1024 : null,
        height: decoded.height >= decoded.width ? 1024 : null,
        interpolation: img.Interpolation.average,
      );
    }

    final compressedBytes = img.encodeJpg(resized, quality: 80);
    final tempDir = await getTemporaryDirectory();
    final targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(compressedBytes);

    return targetFile;
  }
}
