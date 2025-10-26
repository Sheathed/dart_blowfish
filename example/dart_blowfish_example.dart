import 'dart:typed_data';

import 'package:dart_blowfish/src/constants.dart';
import 'package:dart_blowfish/src/encoding.dart';
import 'package:dart_blowfish/src/helpers.dart';

/// Example implementation demonstrating Blowfish helper functions
void main() {
  testBitwiseOperations();
  testByteOperations();
  testTypeChecks();
  testKeyOperations();
  testPaddingOperations();
}

/// Test bitwise operations
void testBitwiseOperations() {
  print('\n=== Bitwise Operations ===');
  
  // Test signedToUnsigned
  final int signed = -1;
  final int unsigned = Helpers.signedToUnsigned(signed);
  print('Signed to Unsigned: $signed → $unsigned');

  // Test XOR operation
  final int a = 1, b = 2;
  final int xorResult = Helpers.xor(a, b);
  print('XOR: $a ⊕ $b = $xorResult');

  // Test sum modulo 32
  final int sum = Helpers.sumMod32(a, b);
  print('Sum Mod32: $a + $b = $sum');
}

/// Test byte packing operations
void testByteOperations() {
  print('\n=== Byte Operations ===');
  
  // Test byte packing
  final int byte1 = 1, byte2 = 2, byte3 = 3, byte4 = 4;
  final int packed = Helpers.packFourBytes(byte1, byte2, byte3, byte4);
  print('Pack bytes: [$byte1,$byte2,$byte3,$byte4] → $packed');

  // Test byte unpacking
  final List<int> unpacked = Helpers.unpackFourBytes(packed);
  print('Unpack bytes: $packed → $unpacked');
}

/// Test type checking functions
void testTypeChecks() {
  print('\n=== Type Checks ===');
  
  final String testStr = 'test';
  final List<int> testBuffer = [1, 2, 3, 4];
  final Map<String, int> testMap = {'a': 1, 'b': 2, 'c': 3};

  print('String check: "$testStr" is string? ${Helpers.isString(testStr)}');
  print('Buffer check: $testBuffer is buffer? ${Helpers.isBuffer(testBuffer)}');
  print('Map includes: $testMap contains 2? ${Helpers.includes(testMap, 2)}');
}

/// Test key operations
void testKeyOperations() {
  print('\n=== Key Operations ===');
  
  final String key = 'test';
  final Uint8List keyBytes = Encoding.stringToU8(key);
  final Uint8List expandedKey = Helpers.expandKey(keyBytes);
  
  print('Original key: "$key"');
  print('Key bytes: $keyBytes');
  print('Expanded key: $expandedKey (length: ${expandedKey.length})');
}

/// Test padding operations
void testPaddingOperations() {
  print('\n=== Padding Operations ===');
  
  final String input = 'test';
  final Uint8List inputBytes = Encoding.stringToU8(input);

  // Test different padding methods
  testPadding('PKCS5', inputBytes, Padding.pkcs5);
  testPadding('OneAndZeros', inputBytes, Padding.oneAndZeros);
  testPadding('LastByte', inputBytes, Padding.lastByte);
  testPadding('None', inputBytes, Padding.none);
  testPadding('Spaces', inputBytes, Padding.spaces);

  // Test unpadding
  final paddedData = Helpers.pad(inputBytes, Padding.spaces);
  final unpaddedData = Helpers.unpad(paddedData, Padding.spaces);
  print('\nUnpad test:');
  print('Original → Padded → Unpadded');
  print('$inputBytes → $paddedData → $unpaddedData');
}

/// Helper function to test padding methods
void testPadding(String name, Uint8List data, Padding method) {
  final padded = Helpers.pad(data, method);
  print('\n$name padding:');
  print('Original: $data (${data.length} bytes)');
  print('Padded: $padded (${padded.length} bytes)');
}
