import 'package:calcetto_tracker/widgets/add_action_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _plusKey = Key('plus');

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final _anchor = GlobalKey();
  AddAction? result;
  bool closed = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: const SizedBox.expand(),
        bottomNavigationBar: SizedBox(
          height: 64,
          child: Center(
            child: GestureDetector(
              key: _plusKey,
              onTap: () async {
                final r = await showAddActionMenu(context, anchorKey: _anchor);
                setState(() {
                  result = r;
                  closed = true;
                });
              },
              child: Container(
                key: _anchor,
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                    color: Colors.green, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
      );
}

void main() {
  Future<_HostState> open(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: _Host()));
    await tester.tap(find.byKey(_plusKey));
    await tester.pumpAndSettle();
    return tester.state<_HostState>(find.byType(_Host));
  }

  testWidgets('the + shows the two bubbles', (tester) async {
    await open(tester);

    expect(find.text('Partita'), findsOneWidget);
    expect(find.text('Allenamento'), findsOneWidget);
  });

  testWidgets('bubbles sit above the +, match left and training right',
      (tester) async {
    await open(tester);

    final plus = tester.getCenter(find.byKey(_plusKey));
    final match =
        tester.getCenter(find.byKey(const ValueKey('add_action_match')));
    final training =
        tester.getCenter(find.byKey(const ValueKey('add_action_training')));
    expect(match.dy, lessThan(plus.dy));
    expect(training.dy, lessThan(plus.dy));
    expect(match.dx, lessThan(plus.dx));
    expect(training.dx, greaterThan(plus.dx));
  });

  testWidgets('tapping Allenamento returns training and closes',
      (tester) async {
    final host = await open(tester);

    await tester.tap(find.text('Allenamento'));
    await tester.pumpAndSettle();

    expect(host.result, AddAction.training);
    expect(find.text('Allenamento'), findsNothing);
  });

  testWidgets('tapping Partita returns match', (tester) async {
    final host = await open(tester);

    await tester.tap(find.byKey(const ValueKey('add_action_match')));
    await tester.pumpAndSettle();

    expect(host.result, AddAction.match);
  });

  testWidgets('tapping the backdrop closes without a choice', (tester) async {
    final host = await open(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(host.closed, isTrue);
    expect(host.result, isNull);
    expect(find.text('Partita'), findsNothing);
  });

  testWidgets('the close button closes without a choice', (tester) async {
    final host = await open(tester);

    await tester.tap(find.byTooltip('Chiudi'));
    await tester.pumpAndSettle();

    expect(host.closed, isTrue);
    expect(host.result, isNull);
  });

  testWidgets('bubbles stay on screen at 320x568 with text scale 1.3',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await open(tester);

    expect(tester.takeException(), isNull);
    const screen = Rect.fromLTWH(0, 0, 320, 568);
    for (final text in ['Partita', 'Allenamento']) {
      final r = tester.getRect(find.text(text));
      expect(
          screen.contains(r.topLeft) && screen.contains(r.bottomRight), isTrue,
          reason: '$text esce dallo schermo: $r');
    }
  });
}
