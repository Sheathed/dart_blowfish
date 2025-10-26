import 'dart:typed_data';
import 'package:dart_blowfish/src/constants.dart';
import 'package:dart_blowfish/src/encoding.dart';
import 'package:dart_blowfish/src/helpers.dart';

/// Implements the Blowfish encryption algorithm
/// 
/// Provides methods for encrypting and decrypting data using the Blowfish cipher
/// in both ECB and CBC modes with various padding options.
/// 
/// Example:
/// ```dart
/// final cipher = Blowfish(
///   key: Encoding.stringToU8('myKey'),
///   mode: Mode.cbc,
///   padding: Padding.pkcs5
/// );
/// ```
class Blowfish {
  /// The encryption mode (ECB or CBC)
  final Mode mode;

  /// The padding method to use
  final Padding padding;

  /// Initialization vector for CBC mode
  Uint8List? iv;

  /// P-array for the Blowfish algorithm
  late List<int> p;

  /// S-boxes for the Blowfish algorithm
  late List<List<int>> s;

  /// Creates a new Blowfish cipher instance
  /// 
  /// [key] The encryption key as a byte array
  /// [mode] The encryption mode (ECB or CBC)
  /// [padding] The padding method to use
  /// 
  /// Throws:
  /// - Exception if the key is invalid
  Blowfish({required Uint8List key, required this.mode, required this.padding}) {
    // Optimize list initialization
    p = Uint32List(18)..setAll(0, Blocks.P);
    s = List.generate(4, (i) {
      final sBlock = Uint32List(256);
      switch(i) {
        case 0: sBlock.setAll(0, Blocks.S0); break;
        case 1: sBlock.setAll(0, Blocks.S1); break;
        case 2: sBlock.setAll(0, Blocks.S2); break;
        case 3: sBlock.setAll(0, Blocks.S3); break;
      }
      return sBlock;
    });

    Uint8List nKey = Helpers.expandKey(key);

    for (int i = 0, j = 0; i < 18; i++, j += 4) {
      final n =
          Helpers.packFourBytes(nKey[j], nKey[j + 1], nKey[j + 2], nKey[j + 3]);
      p[i] = Helpers.xor(p[i], n);
    }

    int l = 0;
    int r = 0;
    for (int i = 0; i < 18; i += 2) {
      var result = _encryptBlock(l, r);
      l = result[0];
      r = result[1];
      p[i] = l;
      p[i + 1] = r;
    }
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 256; j += 2) {
        var result = _encryptBlock(l, r);
        l = result[0];
        r = result[1];
        s[i][j] = l;
        s[i][j + 1] = r;
      }
    }
  }

  /// Sets the initialization vector for CBC mode
  /// 
  /// [value] An 8-byte initialization vector
  /// 
  /// Throws:
  /// - Exception if the IV length is not 8 bytes
  void setIv(Uint8List value) {
    if (value.length != 8) {
      throw Exception('IV should be 8 byte length');
    }
    iv = value;
  }

  /// Internal F-function for the Blowfish algorithm
  /// 
  /// [x] The input value to process
  /// Returns the processed value
  int _f(int x) {
    int a = (x >> 24) & 0xFF;
    int b = (x >> 16) & 0xFF;
    int c = (x >> 8) & 0xFF;
    int d = x & 0xFF;

    int res = Helpers.sumMod32(s[0][a], s[1][b]);
    res = Helpers.xor(res, s[2][c]);
    return Helpers.sumMod32(res, s[3][d]);
  }

  /// Encrypts a single block using the Blowfish algorithm
  /// 
  /// [l] Left half of the block
  /// [r] Right half of the block
  /// Returns the encrypted block as [left, right] pair
  List<int> _encryptBlock(int l, int r) {
    int temp;
    for (int i = 0; i < 16; i++) {
      l = Helpers.xor(l, p[i]);
      r = Helpers.xor(r, _f(l));
      // Optimize swap without list creation
      temp = r;
      r = l;
      l = temp;
    }
    // Final swap and XOR
    temp = r;
    r = Helpers.xor(l, p[17]);
    l = Helpers.xor(temp, p[16]);
    return [l, r];
  }

  /// Encodes data using the configured mode and padding
  /// 
  /// [data] The data to encode as a byte array
  /// Returns the encoded data
  /// 
  /// Throws:
  /// - Exception if IV is not set for CBC mode
  Uint8List encode(Uint8List data) {
    if (mode == Mode.cbc && iv == null) {
      throw Exception('IV is not set');
    }
    data = Helpers.pad(data, padding);
    if (mode == Mode.cbc) {
      return _encodeCBC(data);
    } else if (mode == Mode.ecb) {
      return _encodeECB(data);
    }
    return Uint8List(0);
  }

  /// Decodes data using the configured mode and padding
  /// 
  /// [data] The data to decode
  /// [returnType] The desired return type (string or byte array)
  /// Returns the decoded data in the specified format
  /// 
  /// Throws:
  /// - Exception if input is invalid
  /// - Exception if IV is not set for CBC mode
  /// - Exception if data length is not multiple of 8
  dynamic decode(data, {Type returnType = Type.string}) {
    if (!Helpers.isStringOrBuffer(data)) {
      throw Exception(
          'Decode data should be a string or an ArrayBuffer / Buffer');
    }
    if (mode != Mode.ecb && iv == null) {
      throw Exception('IV is not set');
    }
    data = Helpers.toUint8Array(data);

    if (data.length % 8 != 0) {
      throw Exception('Decoded data should be multiple of 8 bytes');
    }

    switch (mode) {
      case Mode.ecb:
        {
          data = _decodeECB(data);
          break;
        }
      case Mode.cbc:
        {
          data = _decodeCBC(data);
          break;
        }
    }

    data = Helpers.unpad(data, padding);

    switch (returnType) {
      case Type.uInt8Array:
        {
          return data;
        }
      case Type.string:
        {
          return Encoding.u8ToString(data);
        }
      default:
        {
          throw Exception('Unsupported return type');
        }
    }
  }

  /// Encodes data using CBC mode
  /// 
  /// [bytes] The data to encode
  /// Returns the encoded data
  Uint8List _encodeCBC(Uint8List bytes) {
    final encoded = Uint8List(bytes.length);
    var prevL = Helpers.packFourBytes(iv![0], iv![1], iv![2], iv![3]);
    var prevR = Helpers.packFourBytes(iv![4], iv![5], iv![6], iv![7]);
    
    for (int i = 0; i < bytes.length; i += 8) {
      final l = Helpers.xor(prevL, 
          Helpers.packFourBytes(bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3]));
      final r = Helpers.xor(prevR,
          Helpers.packFourBytes(bytes[i + 4], bytes[i + 5], bytes[i + 6], bytes[i + 7]));
      
      final encrypted = _encryptBlock(l, r);
      prevL = encrypted[0];
      prevR = encrypted[1];
      
      encoded.setRange(i, i + 4, Helpers.unpackFourBytes(encrypted[0]));
      encoded.setRange(i + 4, i + 8, Helpers.unpackFourBytes(encrypted[1]));
    }
    return encoded;
  }

  /// Encodes data using ECB mode
  /// 
  /// [bytes] The data to encode
  /// Returns the encoded data
  Uint8List _encodeECB(Uint8List bytes) {
    Uint8List encoded = Uint8List(bytes.length);
    for (int i = 0; i < bytes.length; i += 8) {
      int l = Helpers.packFourBytes(
          bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3]);
      int r = Helpers.packFourBytes(
          bytes[i + 4], bytes[i + 5], bytes[i + 6], bytes[i + 7]);
      List<int> result = _encryptBlock(l, r);
      l = result[0];
      r = result[1];
      encoded.setRange(i, i + 4, Helpers.unpackFourBytes(l));
      encoded.setRange(i + 4, i + 8, Helpers.unpackFourBytes(r));
    }
    return encoded;
  }

  /// Decrypts a single block using the Blowfish algorithm
  /// 
  /// [l] Left half of the block
  /// [r] Right half of the block
  /// Returns the decrypted block as [left, right] pair
  List<int> _decryptBlock(int l, int r) {
    for (int i = 17; i > 1; i--) {
      l = Helpers.xor(l, p[i]);
      r = Helpers.xor(r, _f(l));
      List<int> temp = [r, l];
      l = temp[0];
      r = temp[1];
    }
    List<int> temp = [r, l];
    l = temp[0];
    r = temp[1];
    r = Helpers.xor(r, p[1]);
    l = Helpers.xor(l, p[0]);
    return [l, r];
  }

  /// Decodes data using ECB mode
  /// 
  /// [bytes] The data to decode
  /// Returns the decoded data
  Uint8List _decodeECB(Uint8List bytes) {
    final decoded = Uint8List(bytes.length);
    for (var i = 0; i < bytes.length; i += 8) {
      final l = Helpers.packFourBytes(
          bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3]);
      final r = Helpers.packFourBytes(
          bytes[i + 4], bytes[i + 5], bytes[i + 6], bytes[i + 7]);
      final decrypted = _decryptBlock(l, r);
      decoded.setRange(i, i + 4, Helpers.unpackFourBytes(decrypted[0]));
      decoded.setRange(i + 4, i + 8, Helpers.unpackFourBytes(decrypted[1]));
    }
    return decoded;
  }

  /// Decodes data using CBC mode
  /// 
  /// [bytes] The data to decode
  /// Returns the decoded data
  Uint8List _decodeCBC(Uint8List bytes) {
    final decoded = Uint8List(bytes.length);
    var prevL = Helpers.packFourBytes(iv![0], iv![1], iv![2], iv![3]);
    var prevR = Helpers.packFourBytes(iv![4], iv![5], iv![6], iv![7]);
    int prevLTmp, prevRTmp;
    for (var i = 0; i < bytes.length; i += 8) {
      final l = Helpers.packFourBytes(
          bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3]);
      final r = Helpers.packFourBytes(
          bytes[i + 4], bytes[i + 5], bytes[i + 6], bytes[i + 7]);
      prevLTmp = l;
      prevRTmp = r;
      final decrypted = _decryptBlock(l, r);
      final xoredL = Helpers.xor(prevL, decrypted[0]);
      final xoredR = Helpers.xor(prevR, decrypted[1]);
      prevL = prevLTmp;
      prevR = prevRTmp;
      decoded.setRange(i, i + 4, Helpers.unpackFourBytes(xoredL));
      decoded.setRange(i + 4, i + 8, Helpers.unpackFourBytes(xoredR));
    }
    return decoded;
  }
}
