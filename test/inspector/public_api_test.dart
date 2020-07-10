import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:morpheus_sdk/inspector/public_api.dart';
import 'package:morpheus_sdk/src/io.dart';
import 'package:morpheus_sdk/ssi/io.dart';
import 'package:test/test.dart';

import '../util.dart';

final scenariosResponse = '''
{
  "scenarios": [
    "cjuFURvWkcd-82J83erY_dEUhlRf9Yn8OiWWl7SxVpBvf4"
  ]
}
''';

class MockApiConfig extends Mock implements ApiConfig {}

class MockClient extends Mock implements Client {}

void main() {
  final client = MockClient();
  final config = MockApiConfig();
  when(config.client).thenReturn(client);
  when(config.host).thenReturn('http://host');
  when(config.port).thenReturn(80);
  final api = InspectorPublicApi(config);
  final baseUrl = 'http://host:80';

  group('InspectorPublicApi', () {
    test('listScenarios', () async {
      when(
        client.get('$baseUrl/scenarios', headers: anyNamed('headers')),
      ).thenAnswer((_) => Future.value(resp(scenariosResponse)));

      final r = await api.listScenarios();
      expect(r.length, 1);
      expect(r[0], ContentId('cjuFURvWkcd-82J83erY_dEUhlRf9Yn8OiWWl7SxVpBvf4'));
    });

    test('listScenarios - not http200', () async {
      when(
        client.get('$baseUrl/scenarios', headers: anyNamed('headers')),
      ).thenAnswer((_) => Future.value(resp('', code: 500)));

      expect(
        api.listScenarios(),
        throwsA(const TypeMatcher<HttpResponseError>()),
      );
    });

    test('getPublicBlob', () async {
      final id = ContentId('contentId');
      when(
        client.get('$baseUrl/blob/${id.value}', headers: anyNamed('headers')),
      ).thenAnswer((_) => Future.value(resp('BLOB')));

      final r = await api.getPublicBlob(id);
      expect(r.isPresent, true);
      expect(r.value, 'BLOB');
    });

    test('getPublicBlob - http404', () async {
      final id = ContentId('contentId');
      when(
        client.get('$baseUrl/blob/${id.value}', headers: anyNamed('headers')),
      ).thenAnswer((_) => Future.value(resp('', code: 404)));

      final r = await api.getPublicBlob(id);
      expect(r.isPresent, false);
    });

    test('getPublicBlob - not http200/404', () async {
      final id = ContentId('contentId');
      when(
        client.get('$baseUrl/blob/${id.value}', headers: anyNamed('headers')),
      ).thenAnswer((_) => Future.value(resp('', code: 500)));

      expect(
        api.getPublicBlob(id),
        throwsA(const TypeMatcher<HttpResponseError>()),
      );
    });

    test('uploadPresentation', () async {
      when(client.post(
        '$baseUrl/presentation',
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
            (_) => Future.value(resp('contentId', code: 202)),
      );

      // TODO: finish, when we can create Signed<Presentation>
      // final r = await api.uploadPresentation(presentation);
    });

    test('uploadPresentation - not http202', () async {
      when(client.post(
        '$baseUrl/presentation',
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
            (_) => Future.value(resp('', code: 500)),
      );

      // TODO: finish, when we can create Signed<Presentation>
      //final r = await api.uploadPresentation(presentation);
    });
  });
}