import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:stepsperhour/fitbit_api.dart';
import 'package:stepsperhour/secret.dart';
import 'package:stepsperhour/utilities.dart';

// Create a MockClient using the Mock class provided by the Mockito package.
// Create new instances of this class in each test.
class MockClient extends Mock implements http.Client {}

class MockFlutterAuth extends Mock implements FlutterWebAuthWrapper {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test("authorizeAndGetTokens returns the access token and refresh token",
      () async {
    final client = MockClient();
    final flutterWebAuth = MockFlutterAuth();
    Secret secret = await SecretLoader(secretPath: "secrets.json").load();
    String secretsText = "${secret.clientId}:${secret.clientSecret}";
    List encodedText = utf8.encode(secretsText);
    String base64Str = base64.encode(encodedText);
    final code = 'verification_code';
    final redirectUri = "com.test.app://oauth2redirect";
    when(flutterWebAuth.authenticate(any, any)).thenAnswer((_) =>
        Future.value("com.test.app://oauth2redirect?code=" + code + "#_=_"));
    final response = http.Response(
        "{\"access_token\": \"actual_access_token\", \"refresh_token\": \"actual_refresh_token\"}",
        200);
    when(client.post(any, body: {
      'client_id': secret.clientId,
      'grant_type': 'authorization_code',
      'redirect_uri': redirectUri,
      'code': code,
    }, headers: {
      'Authorization': 'Basic ' + base64Str
    })).thenAnswer((_) => Future.value(response));

    var result = await FitbitApi(client, flutterWebAuth)
        .authorizeAndGetTokens(secret, base64Str);
    expect(result[0], "actual_access_token");
    expect(result[1], "actual_refresh_token");
  });

  //todo: write a test verifying this....
//  verify(client.post('https://api.fitbit.com/oauth2/token', headers: {
//    'Authorization': 'Basic ' + base64Str
//  }, body: {
//    'client_id': secret.clientId,
//    'grant_type': 'authorization_code',
//    'redirect_uri': redirectUri,
//    'code': code
//  }));

// todo: mock out persistTokens (possibly put it in class)
}
