library arbenn_auth;

import 'dart:convert';
import 'package:arbenn_auth/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dargon2_flutter/dargon2_flutter.dart';

class Credentials {
  final int userId;
  final String token;
  final bool verified;
  final bool hasData;

  Credentials({
    required this.userId,
    required this.token,
    this.hasData = false,
    this.verified = true,
  });

  Future<void> forgotPassword() async {}
  Future<void> sendEmailVerification() async {}
  Future<void> reload() async {}

  static Credentials ofJson(Map<String, dynamic> infos) {
    return Credentials(
        userId: infos["userId"],
        token: infos["token"],
        verified: true, // Should be recovered from server
        hasData: true);
  }

  @override
  String toString() {
    return '{"userId": $userId, "token": "$token"}';
  }

  static Future<Credentials?> hasStoredToken() async {
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: "auth_arbenn");
    if (token == null) return null;
    Map<String, dynamic> infos = jsonDecode(token);
    return ofJson(infos);
  }

  Future<void> saveTokenLocally() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: "auth_arbenn", value: toString());
  }

  static Future<void> deleteLocalToken() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: "auth_arbenn");
  }

  static Future<Credentials?> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    String? salt = await unsafeGet("/a/getSalt/$email");
    if (salt == null) {
      return null;
    }
    DArgon2Result hash = await argon2.hashPasswordString(password,
        salt: Salt(salt.split(',').map((s) => int.parse(s)).toList()));
    var body = {
      "email": email,
      "password_hash": hash.encodedString,
      "salt": salt
    };
    String? token = await unsafePost("/a/getToken", body: body);
    if (token != null) {
      Map<String, dynamic> infos = jsonDecode(token);
      return Credentials(
          userId: infos["userid"],
          token: infos["token"],
          verified: infos["verified"],
          hasData: infos["has_data"]);
    } else {
      return null;
    }
  }

  static Credentials dummy({userId = 1, token = "a@a.a", verified = true}) {
    return Credentials(
      userId: userId,
      token: token,
      verified: verified,
    );
  }

  static Future<Credentials?> createUserWithEmailAndPassword(
      {required String email, required String password}) async {
    Salt salt = Salt.newSalt();
    DArgon2Result hash = await argon2.hashPasswordString(password, salt: salt);
    var body = {
      "email": email,
      "password_hash": hash.encodedString,
      "salt": salt.bytes.join(",")
    };
    String? token = await unsafePost("/a/createCredentials", body: body);
    if (token != null) {
      Map<String, dynamic> infos = jsonDecode(token);
      return Credentials(
          userId: infos["userid"],
          token: infos["token"],
          verified: true,
          hasData: false);
    } else {
      return null;
    }
  }

  Future<bool> emailIsVerified() async {
    String? _ = await get("/u/checkVerified", creds: this);
    return true;
  }
}

class CredentialsNotifier extends ChangeNotifier {
  Credentials? _creds;

  CredentialsNotifier({Credentials? creds}) {
    _creds = creds;
  }

  String? get token => _creds?.token;
  int? get userId => _creds?.userId;
  bool? get verified => _creds?.verified;
  bool? get hasData => _creds?.hasData;

  set value(Credentials? newCreds) {
    _creds = newCreds;
    notifyListeners();
  }

  Credentials? get value => _creds;

  set email(String? newEmail) {
    if (_creds != null && newEmail != null) {
      _creds = Credentials(
          userId: _creds!.userId,
          token: newEmail,
          hasData: _creds!.hasData,
          verified: _creds!.verified);
      notifyListeners();
    }
  }

  set userId(int? newUserId) {
    if (_creds != null && newUserId != null) {
      _creds = Credentials(
          userId: newUserId,
          token: _creds!.token,
          hasData: _creds!.hasData,
          verified: _creds!.verified);
      notifyListeners();
    }
  }

  set hasData(bool? hd) {
    if (_creds != null && hd != null) {
      _creds = Credentials(
          userId: _creds!.userId,
          token: _creds!.token,
          hasData: hd,
          verified: _creds!.verified);
      notifyListeners();
    }
  }

  set emailVerified(bool? verified) {
    if (_creds != null && verified != null) {
      _creds = Credentials(
          userId: _creds!.userId,
          token: _creds!.token,
          hasData: _creds!.hasData,
          verified: verified);
      notifyListeners();
    }
  }
}
