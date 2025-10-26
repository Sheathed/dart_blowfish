import 'dart:typed_data';

import 'package:dart_blowfish/src/constants.dart';
import 'package:dart_blowfish/src/dart_blowfish_base.dart';
import 'package:dart_blowfish/src/encoding.dart';

/// Test implementation of Blowfish encryption/decryption
void main() {
  // Test parameters
  const String key = 'test';
  final iv = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7]);
  final testData = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7]);

  // Initialize Blowfish cipher
  final cipher = Blowfish(
    key: Encoding.stringToU8(key),
    mode: Mode.cbc,
    padding: Padding.none,
  );

  // Set initialization vector
  cipher.setIv(iv);

  // Perform decryption
  final decrypted = cipher.decode(
    testData,
    returnType: Type.uInt8Array,
  );

  // Output results
  print('Original data: $testData');
  print('Decrypted data: $decrypted');
}
