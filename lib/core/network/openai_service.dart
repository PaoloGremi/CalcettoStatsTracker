import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Errore restituito dalle chiamate a OpenAI. [statusCode] è presente
/// solo quando l'API ha risposto con uno status diverso da 200 (assente
/// per errori di rete/timeout/parsing).
class OpenAiException implements Exception {
  OpenAiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Centralizza l'accesso all'API OpenAI (chat completions, streaming,
/// generazione immagini) e la chiave API salvata in modo sicuro sul
/// dispositivo. Prima di questo servizio la stessa logica era duplicata
/// in 4 screen diversi, ognuno con la propria copia della chiave di
/// storage e senza timeout uniforme.
class OpenAiService {
  OpenAiService({FlutterSecureStorage? storage, http.Client? client})
      : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  static const _storageKey = 'openai_api_key';
  static const _defaultTimeout = Duration(seconds: 12);
  static const _baseUrl = 'https://api.openai.com/v1';

  final FlutterSecureStorage _storage;
  final http.Client _client;

  Future<String?> readApiKey() => _storage.read(key: _storageKey);

  Future<void> writeApiKey(String key) =>
      _storage.write(key: _storageKey, value: key);

  Future<void> deleteApiKey() => _storage.delete(key: _storageKey);

  /// Verifica che [key] sia una chiave OpenAI valida con una chiamata di
  /// test a costo minimo (`max_tokens: 1`).
  ///
  /// Comportamento preservato intenzionalmente da `api_key_setup_page.dart`:
  /// solo un 401 (autenticazione fallita) invalida la chiave; quota/billing
  /// (429/400), altri status ed errori di rete vengono trattati come
  /// "chiave valida" per evitare falsi negativi. È una scelta discutibile
  /// (un errore di rete non dovrebbe validare una chiave mai testata con
  /// successo) ma cambiarla è fuori dal vincolo "nessun cambio di
  /// comportamento" di questa fase — vedi roadmap nel piano di refactoring.
  Future<bool> validateApiKey(String key) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/chat/completions'),
            headers: _headers(key),
            body: jsonEncode({
              'model': 'gpt-4o-mini',
              'messages': [
                {'role': 'user', 'content': 'ping'}
              ],
              'max_tokens': 1,
            }),
          )
          .timeout(_defaultTimeout);

      if (response.statusCode == 200) return true;
      if (response.statusCode == 401) return false;
      // Quota/billing (429/400) o altri status inattesi: chiave valida
      // ma problema diverso, come nel comportamento originale.
      return true;
    } catch (_) {
      // Errore di rete/timeout: non invalidare la chiave.
      return true;
    }
  }

  /// Chat completion non in streaming. Ritorna il testo generato o solleva
  /// [OpenAiException] se la risposta non è 200.
  Future<String> chatCompletion({
    required String apiKey,
    required List<Map<String, String>> messages,
    String model = 'gpt-4o-mini',
    int? maxTokens,
    double? temperature,
    Duration timeout = _defaultTimeout,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/chat/completions'),
          headers: _headers(apiKey),
          body: jsonEncode({
            'model': model,
            'messages': messages,
            if (maxTokens != null) 'max_tokens': maxTokens,
            if (temperature != null) 'temperature': temperature,
          }),
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw OpenAiException(
        'Errore API: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    return (choices?.firstOrNull?['message']?['content'] as String?) ?? '';
  }

  /// Chat completion in streaming (Server-Sent Events). Emette i delta di
  /// testo man mano che arrivano; solleva [OpenAiException] se lo status
  /// iniziale non è 200. I chunk SSE malformati/parziali vengono ignorati,
  /// come nel comportamento originale.
  Stream<String> chatCompletionStream({
    required String apiKey,
    required List<Map<String, String>> messages,
    String model = 'gpt-4.1-mini',
    double? temperature,
  }) async* {
    final request =
        http.Request('POST', Uri.parse('$_baseUrl/chat/completions'));
    request.headers.addAll(_headers(apiKey));
    request.body = jsonEncode({
      'model': model,
      'messages': messages,
      if (temperature != null) 'temperature': temperature,
      'stream': true,
    });

    final streamedResponse =
        await _client.send(request).timeout(_defaultTimeout);
    if (streamedResponse.statusCode != 200) {
      throw OpenAiException(
        'Errore API: ${streamedResponse.statusCode}',
        statusCode: streamedResponse.statusCode,
      );
    }

    var lineBuffer = '';
    await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
      lineBuffer += chunk;
      while (lineBuffer.contains('\n')) {
        final newlineIndex = lineBuffer.indexOf('\n');
        final line = lineBuffer.substring(0, newlineIndex).trim();
        lineBuffer = lineBuffer.substring(newlineIndex + 1);
        if (!line.startsWith('data: ')) continue;
        final jsonStr = line.substring(6);
        if (jsonStr == '[DONE]') return;
        try {
          final data = jsonDecode(jsonStr);
          final delta = data['choices'][0]['delta']['content'] as String? ?? '';
          if (delta.isNotEmpty) yield delta;
        } catch (_) {
          // Chunk SSE malformato/parziale: ignorato.
        }
      }
    }
  }

  /// Genera un'immagine e ritorna i dati in base64. Solleva
  /// [OpenAiException] (con il messaggio d'errore restituito da OpenAI,
  /// quando disponibile) se la risposta non è 200.
  Future<String> generateImageBase64({
    required String apiKey,
    required String prompt,
    String model = 'gpt-image-1',
    String size = '1024x1536',
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/images/generations'),
          headers: _headers(apiKey),
          body: jsonEncode({
            'model': model,
            'prompt': prompt,
            'n': 1,
            'size': size,
          }),
        )
        .timeout(_defaultTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final message =
          (data['error'] as Map<String, dynamic>?)?['message'] as String? ??
              'Errore OpenAI (Status: ${response.statusCode})';
      throw OpenAiException(message, statusCode: response.statusCode);
    }

    final base64Image =
        (data['data'] as List?)?.firstOrNull?['b64_json'] as String?;
    if (base64Image == null) {
      throw OpenAiException('Risposta API inattesa: base64Image mancante');
    }
    return base64Image;
  }

  Map<String, String> _headers(String apiKey) => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };
}
