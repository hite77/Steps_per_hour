import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stepsperhour/fitbit_api.dart';
import 'package:stepsperhour/secret.dart';
import 'package:stepsperhour/token.dart';
import 'package:stepsperhour/utilities.dart';

// Create a MockClient using the Mock class provided by the Mockito package.
// Create new instances of this class in each test.
class MockClient extends Mock implements http.Client {}

class MockFlutterAuth extends Mock implements FlutterWebAuthWrapper {}

class MockToken extends Mock implements token {}

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  Secret secret;
  MockClient client;
  MockFlutterAuth flutterWebAuth;
  MockToken token;
  String base64Str;
  final redirectUri = "com.test.app://oauth2redirect";
  final code = 'verification_code';

  setup() async {
    secret = await SecretLoader(secretPath: "secrets.json").load();
    client = MockClient();
    flutterWebAuth = MockFlutterAuth();
    token = MockToken();

    String secretsText = "${secret.clientId}:${secret.clientSecret}";
    List encodedText = utf8.encode(secretsText);
    base64Str = base64.encode(encodedText);
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
    when(client.get(
            'https://api.fitbit.com/1/user/-/activities/date/today.json',
            headers: {'Authorization': 'Bearer ' + 'actual_access_token'}))
        .thenAnswer((_) => Future.value(http.Response("foo", 200)));
  }

  group("authorizeAndGetTokens", () {
    test("returns the access token and refresh token", () async {
      await setup();
      var result = await FitbitApi(client, flutterWebAuth, token)
          .authorizeAndGetTokens(secret, base64Str);
      expect(result[0], "actual_access_token");
      expect(result[1], "actual_refresh_token");
    });

    test("calls token with code from flutterWebAuth", () async {
      await setup();
      await FitbitApi(client, flutterWebAuth, token)
          .authorizeAndGetTokens(secret, base64Str);
      verify(client.post('https://api.fitbit.com/oauth2/token', headers: {
        'Authorization': 'Basic ' + base64Str
      }, body: {
        'client_id': secret.clientId,
        'grant_type': 'authorization_code',
        'redirect_uri': redirectUri,
        'code': code
      }));
    });

    test("persist tokens", () async {
      await setup();
      await FitbitApi(client, flutterWebAuth, token)
          .authorizeAndGetTokens(secret, base64Str);
      verify(
          token.persistTokens("actual_access_token", "actual_refresh_token"));
    });
  });

  group("getTokens", () {
    test("AccessToken is returned from shared preferences", () async {
      await setup();
      final expectedAccessToken = 'token stored';
      SharedPreferences.setMockInitialValues(
          {'flutter.accessToken': expectedAccessToken});

      when(client.get(
              'https://api.fitbit.com/1/user/-/activities/date/today.json',
              headers: {'Authorization': 'Bearer ' + expectedAccessToken}))
          .thenAnswer((_) => Future.value(http.Response("foo", 200)));

      final accessToken =
          await FitbitApi(client, flutterWebAuth, token).getTokens();
      expect(accessToken, expectedAccessToken);
    });

    test("AccessToken not set will pull a new token and persist", () async {
      await setup();
      SharedPreferences.setMockInitialValues({});

      final accessToken =
          await FitbitApi(client, flutterWebAuth, token).getTokens();

      verify(
          token.persistTokens("actual_access_token", "actual_refresh_token"));
      expect(accessToken, "actual_access_token");
    });

    test("AccessToken is used to try and get today's activities", () async {
      await setup();
      SharedPreferences.setMockInitialValues({});

      await FitbitApi(client, flutterWebAuth, token).getTokens();

      verify(client.get(
          'https://api.fitbit.com/1/user/-/activities/date/today.json',
          headers: {'Authorization': 'Bearer ' + 'actual_access_token'}));
    });

    test(
        "if today's activities fail to update retry again and update accessToken and refreshToken",
        () async {
      await setup();
      SharedPreferences.setMockInitialValues({});

      when(client.get(
              'https://api.fitbit.com/1/user/-/activities/date/today.json',
              headers: {'Authorization': 'Bearer ' + 'actual_access_token'}))
          .thenAnswer((_) => Future.value(http.Response("failed", 400)));
      when(client.post("https://api.fitbit.com/oauth2/token", body: {
        'client_id': secret.clientId,
        'grant_type': 'refresh_token',
        'refresh_token': 'actual_refresh_token',
      }, headers: {
        'Authorization': 'Basic ' + base64Str
      })).thenAnswer((_) => Future.value(http.Response(
          "{\"access_token\": \"newest_access_token\", \"refresh_token\": \"newest_refresh_token\"}",
          200)));
      final accessToken =
          await FitbitApi(client, flutterWebAuth, token).getTokens();
      verify(
          token.persistTokens("newest_access_token", "newest_refresh_token"));
      expect(accessToken, "newest_access_token");
    });

    test("if refresh fails then try and get tokens again", () async {
      await setup();
      SharedPreferences.setMockInitialValues({});

      var answers = [
        Future.value(http.Response("failed", 400)),
        Future.value(http.Response("good", 200))
      ];

      when(client.get(
              'https://api.fitbit.com/1/user/-/activities/date/today.json',
              headers: {'Authorization': 'Bearer ' + 'actual_access_token'}))
          .thenAnswer((_) => answers.removeAt(0));
      when(client.post("https://api.fitbit.com/oauth2/token", body: {
        'client_id': secret.clientId,
        'grant_type': 'refresh_token',
        'refresh_token': 'actual_refresh_token',
      }, headers: {
        'Authorization': 'Basic ' + base64Str
      })).thenAnswer((_) => Future.value(http.Response("failure", 400)));
      await FitbitApi(client, flutterWebAuth, token).getTokens();

      verifyInOrder([
        flutterWebAuth.authenticate(any, any),
        client.post('https://api.fitbit.com/oauth2/token',
            body: anyNamed('body'), headers: anyNamed('headers')),
        token.persistTokens(any, any),
        client.get('https://api.fitbit.com/1/user/-/activities/date/today.json',
            headers: anyNamed('headers')),
        client.post('https://api.fitbit.com/oauth2/token',
            body: anyNamed('body'), headers: anyNamed('headers')),
        flutterWebAuth.authenticate(any, any),
        client.post('https://api.fitbit.com/oauth2/token',
            body: anyNamed('body'), headers: anyNamed('headers')),
        token.persistTokens(any, any),
        client.get('https://api.fitbit.com/1/user/-/activities/date/today.json',
            headers: anyNamed('headers')),
      ]);
    });

    test(
        "refresh fails and getting activity fails then remove tokens, and return error refresh token",
        () async {
      await setup();
      SharedPreferences.setMockInitialValues({
        'flutter.accessToken': 'actual_access_token',
        'flutter.refreshToken': 'actual_refresh_token'
      });

      when(client.get(
              'https://api.fitbit.com/1/user/-/activities/date/today.json',
              headers: {'Authorization': 'Bearer ' + 'actual_access_token'}))
          .thenAnswer((_) => Future.value(http.Response("failed", 400)));
      when(client.post("https://api.fitbit.com/oauth2/token", body: {
        'client_id': secret.clientId,
        'grant_type': 'refresh_token',
        'refresh_token': 'actual_refresh_token',
      }, headers: {
        'Authorization': 'Basic ' + base64Str
      })).thenAnswer((_) => Future.value(http.Response("failure", 400)));

      SharedPreferences prefs = await SharedPreferences.getInstance();

      expect(prefs.getString('accessToken'), 'actual_access_token');
      expect(prefs.getString('refreshToken'), 'actual_refresh_token');

      final result = await FitbitApi(client, flutterWebAuth, token).getTokens();

      expect(result, "error refresh token");
      expect(prefs.getString('accessToken'), null);
      expect(prefs.getString('refreshToken'), null);
    });
  });
}
