import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  static Future<Uint8List> compressForVision(Uint8List rawBytes) async {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(rawBytes);
    } on Object catch (error) {
      throw FormatException('Failed to decode captured image.', error);
    }
    if (decoded == null) {
      throw const FormatException('Failed to decode captured image.');
    }

    var resized = decoded;
    if (decoded.width > 1024 || decoded.height > 1024) {
      resized = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? 1024 : null,
        height: decoded.height > decoded.width ? 1024 : null,
        interpolation: img.Interpolation.average,
      );
    }
    return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
  }

  /// Preprocesses camera pictures to enforce maximum dimension boundaries (1024x1024),
  /// capping Gemini token consumption while maintaining OCR text legibility (Doc_08).
  static Future<File> compressForGemini(File rawFile) async {
    final compressedBytes =
        await compressForVision(await rawFile.readAsBytes());
    final tempDir = await getTemporaryDirectory();
    final targetFile = File(
      '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await targetFile.writeAsBytes(compressedBytes);
    return targetFile;
  }
}
