import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:aahar_ai/core/utils/image_compressor.dart';

void main() {
  test('downscales an image to a maximum 1024px edge', () async {
    final original = img.Image(width: 2000, height: 1500);
    img.fill(original, color: img.ColorRgb8(100, 150, 200));
    final rawBytes = Uint8List.fromList(img.encodeJpg(original));

    final compressed = await ImageCompressor.compressForVision(rawBytes);
    final decoded = img.decodeImage(compressed);

    expect(decoded, isNotNull);
    expect(decoded!.width, 1024);
    expect(decoded.height, 768);
  });

  test('rejects undecodable bytes', () async {
    expect(
      () => ImageCompressor.compressForVision(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<FormatException>()),
    );
  });
}
