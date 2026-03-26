import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';

/// RSA 密钥解析与签名，与 alipay_kit 逻辑一致
class RsaKeyParser {
  const RsaKeyParser._();

  static RSAPrivateKey parsePrivate(String key) {
    final List<String> rows = key.split('\n');
    final String header = rows.first.trim();
    if (header == '-----BEGIN RSA PRIVATE KEY-----') {
      return _parsePrivate(_parseSequence(rows));
    }
    if (header == '-----BEGIN PRIVATE KEY-----') {
      return _parsePrivate(_pkcs8PrivateSequence(_parseSequence(rows)));
    }
    throw UnsupportedError('PEMKey($header) is unsupported');
  }

  static ASN1Sequence _parseSequence(List<String> rows) {
    final String keyText = rows
        .skipWhile((String row) => row.trim().startsWith('-----BEGIN'))
        .takeWhile((String row) => !row.trim().startsWith('-----END'))
        .map((String row) => row.trim())
        .join('');
    final Uint8List keyBytes = Uint8List.fromList(base64.decode(keyText));
    final ASN1Parser asn1Parser = ASN1Parser(keyBytes);
    return asn1Parser.nextObject() as ASN1Sequence;
  }

  static RSAPrivateKey _parsePrivate(ASN1Sequence sequence) {
    final BigInt modulus = (sequence.elements![1] as ASN1Integer).integer!;
    final BigInt exponent = (sequence.elements![3] as ASN1Integer).integer!;
    final BigInt? p = (sequence.elements?[4] as ASN1Integer?)?.integer;
    final BigInt? q = (sequence.elements?[5] as ASN1Integer?)?.integer;
    return RSAPrivateKey(modulus, exponent, p, q);
  }

  static ASN1Sequence _pkcs8PrivateSequence(ASN1Sequence sequence) {
    final ASN1Object object = sequence.elements![2];
    final Uint8List bytes = object.valueBytes!;
    final ASN1Parser parser = ASN1Parser(bytes);
    return parser.nextObject() as ASN1Sequence;
  }
}

/// RSA 签名器
class RsaSigner {
  RsaSigner(this._rsaSigner, this._privateKey);

  final RSASigner _rsaSigner;
  final RSAPrivateKey _privateKey;

  List<int> sign(List<int> message) {
    _rsaSigner
      ..reset()
      ..init(true, PrivateKeyParameter<RSAPrivateKey>(_privateKey));
    final RSASignature signature =
        _rsaSigner.generateSignature(Uint8List.fromList(message));
    return signature.bytes;
  }

  static RsaSigner sha1Rsa(String privateKey) {
    return RsaSigner(
      Signer('SHA-1/RSA') as RSASigner,
      RsaKeyParser.parsePrivate(privateKey),
    );
  }

  static RsaSigner sha256Rsa(String privateKey) {
    return RsaSigner(
      Signer('SHA-256/RSA') as RSASigner,
      RsaKeyParser.parsePrivate(privateKey),
    );
  }
}
