import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

// ignore_for_file: constant_identifier_names
// AccessToken2 (version 007) — tương thích Agora SDK >= 4.x
// Dùng cho development/testing — không để App Certificate trong production

class AgoraToken {
  /// Tạo RTC token (AccessToken2) cho 1 channel
  static String buildTokenWithUid({
    required String appId,
    required String appCertificate,
    required String channelName,
    int uid = 0,
    int expireSeconds = 3600,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final tokenExpire = now + expireSeconds;
    final privilegeExpire = now + expireSeconds;

    final token = _AccessToken2(
      appId: appId,
      appCertificate: appCertificate,
      channelName: channelName,
      uid: uid,
      tokenExpire: tokenExpire,
      privilegeExpire: privilegeExpire,
    );
    return token.build();
  }
}

// ─── AccessToken2 (007) implementation ───────────────────────────────────────

const int _kServiceRtc = 1;
const int _kPrivilegeJoinChannel = 1;
const int _kPrivilegePublishAudioStream = 2;
const int _kPrivilegePublishVideoStream = 3;
const int _kPrivilegePublishDataStream = 4;

class _AccessToken2 {
  final String appId;
  final String appCertificate;
  final String channelName;
  final int uid;
  final int tokenExpire;
  final int privilegeExpire;

  _AccessToken2({
    required this.appId,
    required this.appCertificate,
    required this.channelName,
    required this.uid,
    required this.tokenExpire,
    required this.privilegeExpire,
  });

  String build() {
    final salt = Random.secure().nextInt(0xFFFFFFFF);
    final issueTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final uidStr = uid == 0 ? '' : uid.toString();

    // ── Service payload ──────────────────────────────────────────
    // privileges: { type(uint16) → expire(uint32) }
    final privileges = {
      _kPrivilegeJoinChannel: privilegeExpire,
      _kPrivilegePublishAudioStream: privilegeExpire,
      _kPrivilegePublishVideoStream: privilegeExpire,
      _kPrivilegePublishDataStream: privilegeExpire,
    };

    final servicePayload = _packUint16(_kServiceRtc) +
        _packString(utf8.encode(channelName)) +
        _packString(utf8.encode(uidStr)) +
        _packUint16(privileges.length) +
        privileges.entries.fold<List<int>>([], (acc, e) {
          return acc + _packUint16(e.key) + _packUint32(e.value);
        });

    // ── Main body ────────────────────────────────────────────────
    final body = _packUint32(salt) +
        _packUint32(issueTs) +
        _packUint32(tokenExpire) +
        servicePayload;

    // ── HMAC-SHA256 signature ────────────────────────────────────
    final signMsg = utf8.encode(appId) +
        _packUint32(issueTs) +
        _packUint32(salt) +
        body;
    final sig = Hmac(sha256, utf8.encode(appCertificate))
        .convert(signMsg)
        .bytes;

    // ── Final pack ───────────────────────────────────────────────
    final content =
        _packString(Uint8List.fromList(sig)) + _packString(Uint8List.fromList(body));

    return '007$appId${base64Url.encode(content)}';
  }

  // ── Pack helpers (little-endian) ─────────────────────────────────

  static List<int> _packUint16(int v) {
    final b = ByteData(2)..setUint16(0, v, Endian.little);
    return b.buffer.asUint8List();
  }

  static List<int> _packUint32(int v) {
    final b = ByteData(4)..setUint32(0, v, Endian.little);
    return b.buffer.asUint8List();
  }

  static List<int> _packString(List<int> data) {
    return _packUint16(data.length) + data;
  }
}