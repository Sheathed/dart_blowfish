<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

# Dart Blowfish

A pure Dart implementation of the Blowfish encryption algorithm, providing secure and efficient cryptographic operations.

## Features

- 🔒 Full Blowfish cipher implementation
- 🔄 Support for ECB and CBC modes
- 📦 Multiple padding options (PKCS5, OneAndZeros, LastByte, None, Spaces)
- 🎯 Pure Dart implementation
- ⚡ Optimized for performance
- 🧪 Comprehensive test coverage

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  dart_blowfish: ^1.0.0
```

Then run:
```bash
dart pub get
```

## Usage

### Basic Encryption

```dart
import 'package:dart_blowfish/dart_blowfish.dart';

void main() {
  // Initialize cipher
  final cipher = Blowfish(
    key: Encoding.stringToU8('myKey'),
    mode: Mode.cbc,
    padding: Padding.pkcs5,
  );

  // Set IV for CBC mode
  cipher.setIv(Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]));

  // Encrypt data
  final encrypted = cipher.encode(Encoding.stringToU8('Hello World'));
  
  // Decrypt data
  final decrypted = cipher.decode(encrypted, returnType: Type.string);
}
```

### Different Modes

```dart
// ECB Mode
final ecbCipher = Blowfish(
  key: Encoding.stringToU8('myKey'),
  mode: Mode.ecb,
  padding: Padding.pkcs5,
);

// CBC Mode
final cbcCipher = Blowfish(
  key: Encoding.stringToU8('myKey'),
  mode: Mode.cbc,
  padding: Padding.pkcs5,
);
cbcCipher.setIv(myInitializationVector);
```

## API Reference

### Main Classes

- `Blowfish`: Main cipher class
- `Encoding`: String/byte array conversion utilities
- `Helpers`: Utility functions for bitwise operations

### Enums

- `Mode`: Encryption modes (ECB, CBC)
- `Padding`: Padding methods (PKCS5, OneAndZeros, LastByte, None, Spaces)
- `Type`: Return types for decoding (String, UInt8Array)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Security

This implementation follows the standard Blowfish specification. However, for critical security applications, consider using more modern algorithms like AES.
