import 'dart:convert';
import 'package:arbenn_auth/arbenn_auth.dart';
import 'package:http/http.dart' as http;

const root = "127.0.0.1:8080";

Future<String?> unsafeGet(String path) async {
  var url = Uri.http(root, path);
  var headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  var response = await http.get(url, headers: headers);
  if (response.statusCode != 200) {
    return null;
  }
  return response.body;
}

Future<String?> unsafePost(String path, {required dynamic body}) async {
  var url = Uri.http(root, path);
  var headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  var response =
      await http.post(url, headers: headers, body: json.encode(body));
  if (response.statusCode != 200) {
    return null;
  }
  return response.body;
}

Future<String?> get(String path, {required Credentials creds}) async {
  var url = Uri.http(root, path);
  var headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization':
        'Bearer {"userid": ${creds.userId}, "token": "${creds.token}"}'
  };
  var response = await http.get(url, headers: headers);
  if (response.statusCode != 200) {
    return null;
  }
  return response.body;
}
