import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/csv_service.dart';
import '../services/data_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final CsvService _csvService = CsvService();
  bool _isLoading = false;

  // ── Helpers UI ────────────────────────────────────────────────

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _isLoading = true);
    try {
      await action();
    } catch (e) {
      if (mounted) _showError('Errore: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) => _showSnack(message, isError: true);

  Future<void> _showImportResult(ImportResult result, String label) async {
    if (result.cancelled) return;
    if (!result.success) {
      _showError(result.errorMessage ?? 'Errore sconosciuto');
      return;
    }
    _showSnack('$label importati: ${result.imported}  •  saltati: ${result.skipped}');
    // Forza rebuild del provider
    if (mounted) {
      Provider.of<DataService>(context, listen: false).notifyListeners();
    }
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Ripristino')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── EXPORT ──────────────────────────────────────────
              _SectionHeader(
                icon: Icons.upload_rounded,
                title: 'Esporta dati',
                color: Colors.green,
              ),
              const SizedBox(height: 8),
              _ActionCard(
                icon: Icons.file_download_rounded,
                title: 'Esporta tutto',
                subtitle: 'Genera tutti e 4 i CSV e condividili',
                color: Colors.green,
                onTap: () => _run(() => _csvService.exportAll()),
              ),
              const Divider(height: 32),
              _ActionCard(
                icon: Icons.people_rounded,
                title: 'Esporta Giocatori',
                subtitle: 'players.csv — nome, ruolo, icona',
                color: Colors.blue,
                onTap: () => _run(() async {
                  final f = await _csvService.exportPlayers();
                  _showSnack('✅ Salvato: ${f.path.split('/').last}');
                }),
              ),
              const SizedBox(height: 10),
              _ActionCard(
                icon: Icons.sports_soccer_rounded,
                title: 'Esporta Partite',
                subtitle: 'matches.csv — data, campo, punteggi, squadre',
                color: Colors.blue,
                onTap: () => _run(() async {
                  final f = await _csvService.exportMatches();
                  _showSnack('✅ Salvato: ${f.path.split('/').last}');
                }),
              ),
              const SizedBox(height: 10),
              _ActionCard(
                icon: Icons.star_rounded,
                title: 'Esporta Voti & Commenti',
                subtitle: 'votes_comments.csv — voti e commenti per partita',
                color: Colors.blue,
                onTap: () => _run(() async {
                  final f = await _csvService.exportVotes();
                  _showSnack('✅ Salvato: ${f.path.split('/').last}');
                }),
              ),
              const SizedBox(height: 10),
              _ActionCard(
                icon: Icons.bar_chart_rounded,
                title: 'Esporta Statistiche',
                subtitle: 'stats.csv — medie, best/worst voto per giocatore',
                color: Colors.blue,
                onTap: () => _run(() async {
                  final f = await _csvService.exportStats();
                  _showSnack('✅ Salvato: ${f.path.split('/').last}');
                }),
              ),

              const SizedBox(height: 32),

              // ── IMPORT ──────────────────────────────────────────
              _SectionHeader(
                icon: Icons.download_rounded,
                title: 'Importa dati',
                color: Colors.orange,
              ),
              const SizedBox(height: 4),
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'I dati importati sovrascrivono quelli esistenti con lo stesso ID.',
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              _ActionCard(
                icon: Icons.people_alt_rounded,
                title: 'Importa Giocatori',
                subtitle: 'Seleziona players.csv dal tuo dispositivo',
                color: Colors.orange,
                onTap: () => _run(() async {
                  final result = await _csvService.importPlayers();
                  await _showImportResult(result, 'Giocatori');
                }),
              ),
              const SizedBox(height: 10),
              _ActionCard(
                icon: Icons.emoji_events_rounded,
                title: 'Importa Partite',
                subtitle: 'Seleziona matches.csv dal tuo dispositivo',
                color: Colors.orange,
                onTap: () => _run(() async {
                  final result = await _csvService.importMatches();
                  await _showImportResult(result, 'Partite');
                }),
              ),
              const SizedBox(height: 10),
              _ActionCard(
                icon: Icons.rate_review_rounded,
                title: 'Importa Voti & Commenti',
                subtitle: 'Seleziona votes_comments.csv — richiede le partite già importate',
                color: Colors.orange,
                onTap: () => _run(() async {
                  final result = await _csvService.importVotes();
                  await _showImportResult(result, 'Voti');
                }),
              ),
            ],
          ),

          // ── Loading overlay ────────────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Elaborazione in corso...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Widgets locali
// ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}
