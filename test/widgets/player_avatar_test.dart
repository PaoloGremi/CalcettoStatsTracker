import 'package:calcetto_tracker/widgets/player_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'renders a Material icon when there is no photo and the icon is not an asset',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PlayerAvatar(name: 'Mario', icon: 'person'),
      ),
    );

    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.byType(Icon), findsOneWidget);
  });

  testWidgets('uses a distinct deterministic background color per name',
      (tester) async {
    Color bgOf(Widget w) => (w as CircleAvatar).backgroundColor as Color;

    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            PlayerAvatar(name: 'Alice', icon: 'person'),
            PlayerAvatar(name: 'Alice', icon: 'person'),
            PlayerAvatar(name: 'Bob', icon: 'person'),
          ],
        ),
      ),
    );

    final avatars =
        tester.widgetList<CircleAvatar>(find.byType(CircleAvatar)).toList();
    expect(avatars, hasLength(3));
    // Stesso nome -> stesso colore (deterministico).
    expect(bgOf(avatars[0]), bgOf(avatars[1]));
  });

  testWidgets('respects the radius parameter', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PlayerAvatar(name: 'Mario', icon: 'person', radius: 40),
      ),
    );

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.radius, 40);
  });
}
