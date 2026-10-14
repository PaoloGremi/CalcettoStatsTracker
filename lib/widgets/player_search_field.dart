import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Barra di ricerca giocatori condivisa tra Rosa e Statistiche.
/// Notifica ogni modifica del testo tramite [onChanged]; il pulsante "x"
/// svuota il campo e notifica una query vuota.
class PlayerSearchField extends StatefulWidget {
  const PlayerSearchField({
    super.key,
    required this.onChanged,
    this.hintText = 'Cerca giocatore...',
  });

  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  State<PlayerSearchField> createState() => _PlayerSearchFieldState();
}

class _PlayerSearchFieldState extends State<PlayerSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('player_search_field'),
      controller: _controller,
      onChanged: (v) {
        widget.onChanged(v);
        setState(() {});
      },
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded,
            color: AppTheme.textSecondary, size: 20),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Cancella ricerca',
                icon: const Icon(Icons.close_rounded,
                    color: AppTheme.textSecondary, size: 18),
                onPressed: _clear,
              ),
      ),
    );
  }
}
