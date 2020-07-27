import 'package:flutter_test/flutter_test.dart';
import 'package:stepsperhour/secret.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("can read test Secret", () async {
    Secret secret =
        await SecretLoader(secretPath: 'test/test_secrets.json').load();
    expect(secret.clientId, 'client_id_data');
    expect(secret.clientSecret, 'client_secret_data');
  });
}
