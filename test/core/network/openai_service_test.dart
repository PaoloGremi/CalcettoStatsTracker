import 'dart:async';
import 'dart:convert';

import 'package:calcetto_tracker/core/network/openai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('validateApiKey', () {
    test('returns true on 200 (chiave valida)', () async {
      final client = MockClient((request) async => http.Response('{}', 200));
      final service = OpenAiService(client: client);

      expect(await service.validateApiKey('sk-test'), isTrue);
    });

    test('returns false on 401 (autenticazione fallita)', () async {
      final client =
          MockClient((request) async => http.Response('{"error":{}}', 401));
      final service = OpenAiService(client: client);

      expect(await service.validateApiKey('sk-test'), isFalse);
    });

    test('returns true on 429 (quota) — comportamento preservato', () async {
      final client =
          MockClient((request) async => http.Response('{"error":{}}', 429));
      final service = OpenAiService(client: client);

      expect(await service.validateApiKey('sk-test'), isTrue);
    });

    test('returns true on 400 — comportamento preservato', () async {
      final client =
          MockClient((request) async => http.Response('{"error":{}}', 400));
      final service = OpenAiService(client: client);

      expect(await service.validateApiKey('sk-test'), isTrue);
    });

    test('returns true on network error — comportamento preservato', () async {
      final client =
          MockClient((request) async => throw const SocketExceptionStub());
      final service = OpenAiService(client: client);

      expect(await service.validateApiKey('sk-test'), isTrue);
    });
  });

  group('chatCompletion', () {
    test('returns the message content on 200', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'ciao squadra'}
              }
            ]
          }),
          200,
        );
      });
      final service = OpenAiService(client: client);

      final content = await service.chatCompletion(
        apiKey: 'sk-test',
        messages: [
          {'role': 'user', 'content': 'ping'}
        ],
      );

      expect(content, 'ciao squadra');
    });

    test('sends model/maxTokens/temperature in the request body', () async {
      late Map<String, dynamic> sentBody;
      final client = MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'ok'}
              }
            ]
          }),
          200,
        );
      });
      final service = OpenAiService(client: client);

      await service.chatCompletion(
        apiKey: 'sk-test',
        model: 'gpt-4o-mini',
        maxTokens: 1200,
        temperature: 0.85,
        messages: [
          {'role': 'user', 'content': 'ping'}
        ],
      );

      expect(sentBody['model'], 'gpt-4o-mini');
      expect(sentBody['max_tokens'], 1200);
      expect(sentBody['temperature'], 0.85);
    });

    test('throws OpenAiException with statusCode on non-200', () async {
      final client =
          MockClient((request) async => http.Response('{"error":{}}', 500));
      final service = OpenAiService(client: client);

      await expectLater(
        () => service.chatCompletion(
          apiKey: 'sk-test',
          messages: [
            {'role': 'user', 'content': 'ping'}
          ],
        ),
        throwsA(
          isA<OpenAiException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', 'Errore API: 500'),
        ),
      );
    });

    test('throws a TimeoutException when the request exceeds the given timeout',
        () async {
      final client = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response('{}', 200);
      });
      final service = OpenAiService(client: client);

      await expectLater(
        () => service.chatCompletion(
          apiKey: 'sk-test',
          timeout: const Duration(milliseconds: 5),
          messages: [
            {'role': 'user', 'content': 'ping'}
          ],
        ),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  group('chatCompletionStream', () {
    List<int> sse(List<String> events) =>
        utf8.encode(events.map((e) => 'data: $e\n').join());

    test('yields text deltas parsed from SSE chunks', () async {
      final client = MockClient.streaming((request, bodyStream) async {
        final body = sse([
          jsonEncode({
            'choices': [
              {
                'delta': {'content': 'ciao '}
              }
            ]
          }),
          jsonEncode({
            'choices': [
              {
                'delta': {'content': 'squadra'}
              }
            ]
          }),
          '[DONE]',
        ]);
        return http.StreamedResponse(Stream.value(body), 200);
      });
      final service = OpenAiService(client: client);

      final deltas = await service.chatCompletionStream(
        apiKey: 'sk-test',
        messages: [
          {'role': 'user', 'content': 'ping'}
        ],
      ).toList();

      expect(deltas.join(), 'ciao squadra');
    });

    test('ignores malformed SSE lines instead of throwing', () async {
      final client = MockClient.streaming((request, bodyStream) async {
        final body = utf8.encode(
          'data: not-json\n'
          'data: ${jsonEncode({
                'choices': [
                  {
                    'delta': {'content': 'ok'}
                  }
                ]
              })}\n'
          'data: [DONE]\n',
        );
        return http.StreamedResponse(Stream.value(body), 200);
      });
      final service = OpenAiService(client: client);

      final deltas = await service.chatCompletionStream(
        apiKey: 'sk-test',
        messages: [
          {'role': 'user', 'content': 'ping'}
        ],
      ).toList();

      expect(deltas, ['ok']);
    });

    test('throws OpenAiException when the initial status is not 200', () async {
      final client = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(const Stream.empty(), 500);
      });
      final service = OpenAiService(client: client);

      final stream = service.chatCompletionStream(
        apiKey: 'sk-test',
        messages: [
          {'role': 'user', 'content': 'ping'}
        ],
      );

      await expectLater(
        stream.toList,
        throwsA(isA<OpenAiException>()
            .having((e) => e.statusCode, 'statusCode', 500)),
      );
    });
  });

  group('generateImageBase64', () {
    test('returns the base64 payload on 200', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              {'b64_json': 'AAAA'}
            ]
          }),
          200,
        );
      });
      final service = OpenAiService(client: client);

      final base64 =
          await service.generateImageBase64(apiKey: 'sk-test', prompt: 'cover');

      expect(base64, 'AAAA');
    });

    test(
        'throws OpenAiException with the message returned by OpenAI on non-200',
        () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'message': 'billing hard limit reached'}
          }),
          402,
        );
      });
      final service = OpenAiService(client: client);

      await expectLater(
        () => service.generateImageBase64(apiKey: 'sk-test', prompt: 'cover'),
        throwsA(
          isA<OpenAiException>()
              .having((e) => e.statusCode, 'statusCode', 402)
              .having(
                  (e) => e.message, 'message', 'billing hard limit reached'),
        ),
      );
    });

    test('falls back to a generic message when the body has no error message',
        () async {
      final client = MockClient((request) async => http.Response('{}', 500));
      final service = OpenAiService(client: client);

      await expectLater(
        () => service.generateImageBase64(apiKey: 'sk-test', prompt: 'cover'),
        throwsA(
          isA<OpenAiException>().having(
              (e) => e.message, 'message', 'Errore OpenAI (Status: 500)'),
        ),
      );
    });

    test('throws OpenAiException when base64Image is missing despite 200',
        () async {
      final client = MockClient(
          (request) async => http.Response(jsonEncode({'data': []}), 200));
      final service = OpenAiService(client: client);

      await expectLater(
        () => service.generateImageBase64(apiKey: 'sk-test', prompt: 'cover'),
        throwsA(
          isA<OpenAiException>().having((e) => e.message, 'message',
              'Risposta API inattesa: base64Image mancante'),
        ),
      );
    });
  });
}

/// Piccolo stub per simulare un errore di rete senza dipendere da dart:io
/// (che non è disponibile/necessario in questo contesto di test).
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();

  @override
  String toString() => 'SocketExceptionStub: network unreachable';
}
