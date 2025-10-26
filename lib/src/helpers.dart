import 'dart:typed_data';
import 'encoding.dart';
import 'constants.dart';

/// Helper functions for the Blowfish implementation
///
/// Provides utility methods for bit manipulation, type conversion,
/// and other operations needed by the Blowfish algorithm.
abstract class Helpers {
  /// Converts a signed 32-bit integer to its unsigned equivalent
  static int signedToUnsigned(int signed) => signed.toUnsigned(32);

  /// Performs a bitwise XOR operation on two integers and returns unsigned 32-bit result
  static int xor(int a, int b) => (a ^ b).toUnsigned(32);

  /// Adds two integers and returns the result modulo 2^32
  static int sumMod32(int a, int b) => (a + b) & 0xffffffff;

  /// Packs four bytes into a single 32-bit unsigned integer
  ///
  /// The bytes are packed in big-endian order (most significant byte first)
  static int packFourBytes(int byte1, int byte2, int byte3, int byte4) =>
      ((byte1 << 24) | (byte2 << 16) | (byte3 << 8) | byte4).toUnsigned(32);

  /// Unpacks a 32-bit integer into four bytes
  ///
  /// Returns a list of 4 bytes in big-endian order
  static List<int> unpackFourBytes(int pack) => [
        (pack >> 24) & 0xFF,
        (pack >> 16) & 0xFF,
        (pack >> 8) & 0xFF,
        pack & 0xFF
      ];

  /// Checks if the value is a String
  static bool isString(dynamic val) => val is String;

  /// Checks if the value is a buffer (List<int> or Uint8List)
  static bool isBuffer(dynamic val) => val is List<int> || val is Uint8List;

  /// Checks if the value is either a String or a buffer
  static bool isStringOrBuffer(dynamic val) => isString(val) || isBuffer(val);

  /// Checks if a map contains a specific value
  static bool includes(Map<dynamic, dynamic> obj, dynamic val) =>
      obj.containsValue(val);

  /// Converts various input types to a Uint8List
  ///
  /// Supports String, Uint8List, and List<int> inputs
  /// Throws an exception for unsupported types
  static Uint8List toUint8Array(dynamic val) {
    if (val is String) return Encoding.stringToU8(val);
    if (val is Uint8List) return val;
    if (val is List<int>) return Uint8List.fromList(val);
    throw Exception('Unsupported type');
  }

  /// Expands a key to the required length (72 bytes) for Blowfish
  ///
  /// If the key is already 72 bytes or longer, returns it unchanged
  /// Otherwise, repeats the key until it reaches the required length
  static Uint8List expandKey(Uint8List key) {
    if (key.length >= 72) return key;

    final resultLength = ((72 + key.length - 1) ~/ key.length) * key.length;
    final result = Uint8List(resultLength);
    for (var i = 0; i < resultLength; i += key.length) {
      result.setRange(i, i + key.length, key);
    }
    return result.sublist(0, 72);
  }

  /// Adds padding to a byte array according to the specified padding method
  ///
  /// Supports PKCS5, OneAndZeros, Spaces, LastByte, and None padding methods
  /// Returns a new byte array with the appropriate padding added
  static Uint8List pad(Uint8List bytes, Padding padding) {
    final count = 8 - bytes.length % 8;
    if (count == 8 && bytes.isNotEmpty && padding != Padding.pkcs5) {
      return bytes;
    }
    final writer = Uint8List(bytes.length + count);
    final newBytes = <int>[];
    var remaining = count;
    var padChar = 0;

    switch (padding) {
      case Padding.pkcs5:
        {
          padChar = count;
          break;
        }
      case Padding.oneAndZeros:
        {
          newBytes.add(0x80);
          remaining--;
          break;
        }
      case Padding.spaces:
        {
          padChar = 0x20;
          break;
        }
      case Padding.lastByte:
        break;
      case Padding.none:
        break;
    }

    while (remaining > 0) {
      if (padding == Padding.lastByte && remaining == 1) {
        newBytes.add(count);
        break;
      }
      newBytes.add(padChar);
      remaining--;
    }

    writer.setRange(0, bytes.length, bytes);
    writer.setRange(bytes.length, writer.length, newBytes);
    return writer;
  }

  /// Removes padding from a byte array according to the specified padding method
  ///
  /// Supports PKCS5, OneAndZeros, Spaces, LastByte, and None padding methods
  /// Returns a new byte array with the padding removed
  static Uint8List unpad(Uint8List bytes, Padding padding) {
    int cutLength = 0;
    switch (padding) {
      case Padding.lastByte:
        break;
      case Padding.pkcs5:
        {
          int lastChar = bytes[bytes.length - 1];
          if (lastChar <= 8) {
            cutLength = lastChar;
          }
        }
        break;
      case Padding.oneAndZeros:
        {
          int i = 1;
          while (i <= 8) {
            int char = bytes[bytes.length - i];
            if (char == 0x80) {
              cutLength = i;
              break;
            }
            if (char != 0) {
              break;
            }
            i++;
          }
        }
        break;
      case Padding.none:
        break;
      case Padding.spaces:
        {
          int padChar = (padding == Padding.spaces) ? 0x20 : 0;
          int i = 1;
          while (i <= 8) {
            int char = bytes[bytes.length - i];
            if (char != padChar) {
              cutLength = i - 1;
              break;
            }
            i++;
          }
        }
        break;
    }
    return bytes.sublist(0, bytes.length - cutLength);
  }
}
