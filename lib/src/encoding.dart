import 'dart:typed_data';

/// Provides encoding utilities for converting between strings and byte arrays
/// 
/// Contains static methods for UTF-8 encoding and decoding operations
abstract class Encoding {
  /// Converts a string to a UTF-8 encoded byte array
  /// 
  /// Takes a [String] input and returns a [Uint8List] containing the UTF-8 encoded bytes.
  /// Handles surrogate pairs and multi-byte characters correctly.
  /// 
  /// Example:
  /// ```dart
  /// final bytes = Encoding.stringToU8('Hello');
  /// print(bytes); // [72, 101, 108, 108, 111]
  /// ```
  static Uint8List stringToU8(String s) {
    // Calculate exact length first
    var length = 0;
    for (var ci = 0; ci < s.length; ci++) {
      var c = s.codeUnitAt(ci);
      if (c < 128) length++;
      else if (c < 2048) length += 2;
      else if (c > 0xd7ff && c < 0xdc00) {
        if (++ci >= s.length) break;
        final c2 = s.codeUnitAt(ci);
        if (c2 < 0xdc00 || c2 > 0xdfff) continue;
        length += 4;
      } else length += 3;
    }
    
    final bytes = Uint8List(length);
    var i = 0;
    for (var ci = 0; ci != s.length; ci++) {
      var c = s.codeUnitAt(ci);
      if (c < 128) {
        bytes[i++] = c;
        continue;
      }
      if (c < 2048) {
        bytes[i++] = c >> 6 | 192;
      } else {
        if (c > 0xd7ff && c < 0xdc00) {
          if (++ci >= s.length) {
            print('Incomplete surrogate pair');
            return bytes.sublist(0, i);
          }
          final c2 = s.codeUnitAt(ci);
          if (c2 < 0xdc00 || c2 > 0xdfff) {
            print(
                'Second surrogate character 0x${c2.toRadixString(16)} at index $ci out of range');
            return bytes.sublist(0, i);
          }
          c = 0x10000 + ((c & 0x03ff) << 10) + (c2 & 0x03ff);
          bytes[i++] = c >> 18 | 240;
          bytes[i++] = c >> 12 & 63 | 128;
        } else {
          bytes[i++] = c >> 12 | 224;
        }
        bytes[i++] = c >> 6 & 63 | 128;
      }
      bytes[i++] = c & 63 | 128;
    }
    return bytes.sublist(0, i);
  }

  /// Converts a UTF-8 encoded byte array back to a string
  /// 
  /// Takes a [Uint8List] containing UTF-8 encoded bytes and returns the decoded [String].
  /// Handles incomplete sequences and invalid encodings gracefully with error messages.
  /// 
  /// Example:
  /// ```dart
  /// final text = Encoding.u8ToString(Uint8List.fromList([72, 101, 108, 108, 111]));
  /// print(text); // "Hello"
  /// ```
  /// 
  /// Throws:
  /// - Prints error messages for malformed UTF-8 sequences but does not throw exceptions
  /// - Returns partial results up to the point of error
  static String u8ToString(Uint8List bytes) {
    int i = 0;
    final buffer = StringBuffer();
    while (i < bytes.length) {
      int c = bytes[i++];
      if (c > 127) {
        if (c > 191 && c < 224) {
          if (i >= bytes.length) {
            print('Incomplete 2-byte sequence');
            return buffer.toString();
          }
          c = (c & 31) << 6 | bytes[i++] & 63;
        } else if (c > 223 && c < 240) {
          if (i + 1 >= bytes.length) {
            print('Incomplete 3-byte sequence');
            return buffer.toString();
          }
          c = (c & 15) << 12 | (bytes[i++] & 63) << 6 | bytes[i++] & 63;
        } else if (c > 239 && c < 248) {
          if (i + 2 >= bytes.length) {
            print('Incomplete 4-byte sequence');
            return buffer.toString();
          }
          c = (c & 7) << 18 |
              (bytes[i++] & 63) << 12 |
              (bytes[i++] & 63) << 6 |
              bytes[i++] & 63;
        } else {
          print(
              'Unknown multibyte start 0x${c.toRadixString(16)} at index ${i - 1}');
          return buffer.toString();
        }
      }
      if (c <= 0xffff) {
        buffer.write(String.fromCharCode(c));
      } else if (c <= 0x10ffff) {
        c -= 0x10000;
        buffer.write(String.fromCharCode(c >> 10 | 0xd800));
        buffer.write(String.fromCharCode(c & 0x3FF | 0xdc00));
      } else {
        print('Code point 0x${c.toRadixString(16)} exceeds UTF-16 reach');
        return buffer.toString();
      }
    }
    return buffer.toString();
  }
}
