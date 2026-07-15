import 'package:flutter/material.dart';
import '../core/network/openai_service.dart';
import 'ai_coach_page.dart';

class ApiKeySetupPage extends StatefulWidget {
  const ApiKeySetupPage({super.key});

  @override
  State<ApiKeySetupPage> createState() => _ApiKeySetupPageState();
}

class _ApiKeySetupPageState extends State<ApiKeySetupPage> {
  final _openAiService = OpenAiService();
  final _keyController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _savedKey;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadKey() async {
    final key = await _openAiService.readApiKey();
    setState(() => _savedKey = key);
  }

  Future<void> _saveKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;

    setState(() => _loading = true);

    // Valida la chiave con chiamata di test
    final isValid = await _openAiService.validateApiKey(key);

    if (!isValid) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chiave API non valida. Controllala e riprova.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await _openAiService.writeApiKey(key);
    setState(() {
      _savedKey = key;
      _loading = false;
    });

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiCoachPage()),
      );
    }
  }

  Future<void> _deleteKey() async {
    await _openAiService.deleteApiKey();
    setState(() => _savedKey = null);
    _keyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coach AI — Setup')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Come funziona',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  const Text(
                    'Il Coach AI usa la tua chiave API OpenAI personale. '
                    'I costi vengono addebitati direttamente al tuo account OpenAI. '
                    'La chiave è salvata in modo sicuro solo sul tuo dispositivo.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (_savedKey != null) ...[
              // Chiave già configurata
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chiave configurata',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                          Text(
                            '${_savedKey!.substring(0, 8)}••••••••',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _deleteKey,
                      child: const Text('Rimuovi'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiCoachPage()),
                  ),
                  icon: const Icon(Icons.sports_soccer),
                  label: const Text('Apri Coach AI'),
                ),
              ),
            ] else ...[
              // Inserimento chiave
              const Text(
                'Inserisci la tua chiave API OpenAI',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ottienila su platform.openai.com/api-keys',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _keyController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'sk-proj-...',
                  prefixIcon: const Icon(Icons.key),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _saveKey,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Salva e continua'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
