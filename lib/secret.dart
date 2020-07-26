import 'dart:convert';

import 'package:flutter/services.dart';

class Secret {
  final String clientId;
  final String clientSecret;
  Secret({this.clientId = "", this.clientSecret = ""});
  factory Secret.fromJson(Map<String, dynamic> jsonMap) {
    return new Secret(
        clientId: jsonMap["client_id"], clientSecret: jsonMap["client_secret"]);
  }
}

class SecretLoader {
  final String secretPath;

  SecretLoader({this.secretPath});
  Future<Secret> load() {
    return rootBundle.loadStructuredData<Secret>(this.secretPath,
        (jsonStr) async {
      final secret = Secret.fromJson(json.decode(jsonStr));
      return secret;
    });
  }
}
