import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class AgoraTokenRole {
  static const int publisher = 1;
  static const int subscriber = 2;
}

class AgoraTokenBuilder {
  static String buildTokenWithUid(
    String appId,
    String appCertificate,
    String channelName,
    int uid,
    int role,
    int tokenExpire,
    int privilegeExpire,
  ) {
    return _buildTokenWithUserAccount(
      appId,
      appCertificate,
      channelName,
      uid == 0 ? '' : uid.toString(),
      role,
      tokenExpire,
      privilegeExpire,
    );
  }

  static String _buildTokenWithUserAccount(
    String appId,
    String appCertificate,
    String channelName,
    String account,
    int role,
    int tokenExpire,
    int privilegeExpire,
  ) {
    final token = AccessToken2(appId, appCertificate, 0, tokenExpire);
    final serviceRtc = ServiceRtc(channelName, account);
    serviceRtc.addPrivilege(ServiceRtc.kPrivilegeJoinChannel, privilegeExpire);
    if (role == AgoraTokenRole.publisher) {
      serviceRtc.addPrivilege(
          ServiceRtc.kPrivilegePublishAudioStream, privilegeExpire);
      serviceRtc.addPrivilege(
          ServiceRtc.kPrivilegePublishVideoStream, privilegeExpire);
      serviceRtc.addPrivilege(
          ServiceRtc.kPrivilegePublishDataStream, privilegeExpire);
    }
    token.addService(serviceRtc);
    return token.build();
  }
}

class AccessToken2 {
  static const int appIdLength = 32;

  final String appId;
  final String appCertificate;
  final int issueTs;
  final int expire;
  final int salt;
  final Map<int, Service> services = {};

  AccessToken2(this.appId, this.appCertificate, int issueTs, this.expire)
      : issueTs = issueTs > 0
            ? issueTs
            : DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
        salt = Random().nextInt(99999998) + 1;

  void addService(Service service) {
    services[service.serviceType()] = service;
  }

  String build() {
    if (!_buildCheck()) return '';

    final signing = _signing();
    final signingInfo = _buildSigningInfo();
    final signature = _hmacSha256(signing, signingInfo);
    final content =
        ByteBuf().putStringBytes(signature).putBytes(signingInfo).pack();
    final compressed = ZLibCodec().encode(content);
    return '${_version()}${base64.encode(compressed)}';
  }

  bool _buildCheck() {
    return _isHex32(appId) && _isHex32(appCertificate) && services.isNotEmpty;
  }

  Uint8List _buildSigningInfo() {
    final buf = ByteBuf()
        .putString(appId)
        .putUint32(issueTs)
        .putUint32(expire)
        .putUint32(salt)
        .putUint16(services.length);

    for (final service in services.values) {
      buf.putBytes(service.pack());
    }
    return buf.pack();
  }

  Uint8List _signing() {
    final first = _hmacSha256(
      Uint8List.fromList(utf8.encode(appCertificate)),
      ByteBuf().putUint32(issueTs).pack(),
    );
    return _hmacSha256(first, ByteBuf().putUint32(salt).pack());
  }

  Uint8List _hmacSha256(Uint8List key, Uint8List message) {
    final hmac = Hmac(sha256, key);
    return Uint8List.fromList(hmac.convert(message).bytes);
  }

  bool _isHex32(String value) {
    if (value.length != appIdLength) return false;
    final regex = RegExp(r'^[0-9a-fA-F]+$');
    return regex.hasMatch(value);
  }

  String _version() => '007';
}

class Service {
  final int type;
  final Map<int, int> privileges = {};

  Service(this.type);

  void addPrivilege(int privilege, int expire) {
    privileges[privilege] = expire;
  }

  Uint8List pack() {
    final buf = ByteBuf().putUint16(type).putTreeMapUInt32(privileges);
    return buf.pack();
  }

  int serviceType() => type;
}

class ServiceRtc extends Service {
  final String channelName;
  final String uid;

  ServiceRtc(this.channelName, this.uid) : super(1);

  @override
  Uint8List pack() {
    final buf = ByteBuf().putString(channelName).putString(uid);
    final base = super.pack();
    return ByteBuf().putBytes(base).putBytes(buf.pack()).pack();
  }

  static const int kPrivilegeJoinChannel = 1;
  static const int kPrivilegePublishAudioStream = 2;
  static const int kPrivilegePublishVideoStream = 3;
  static const int kPrivilegePublishDataStream = 4;
}

class ByteBuf {
  final BytesBuilder _builder = BytesBuilder();

  ByteBuf putUint16(int value) {
    final data = ByteData(2)..setUint16(0, value, Endian.little);
    _builder.add(data.buffer.asUint8List());
    return this;
  }

  ByteBuf putUint32(int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.little);
    _builder.add(data.buffer.asUint8List());
    return this;
  }

  ByteBuf putBytes(Uint8List bytes) {
    _builder.add(bytes);
    return this;
  }

  ByteBuf putString(String value) {
    final data = utf8.encode(value);
    putUint16(data.length);
    _builder.add(data);
    return this;
  }

  ByteBuf putStringBytes(Uint8List bytes) {
    putUint16(bytes.length);
    _builder.add(bytes);
    return this;
  }

  ByteBuf putTreeMapUInt32(Map<int, int> map) {
    putUint16(map.length);
    for (final entry in map.entries) {
      putUint16(entry.key);
      putUint32(entry.value);
    }
    return this;
  }

  Uint8List pack() => _builder.toBytes();
}
