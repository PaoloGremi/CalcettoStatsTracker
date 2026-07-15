import 'package:calcetto_tracker/core/error/result.dart';
import 'package:calcetto_tracker/features/players/domain/entities/player.dart';
import 'package:calcetto_tracker/features/players/domain/usecases/add_player.dart';
import 'package:calcetto_tracker/features/players/domain/usecases/delete_player.dart';
import 'package:calcetto_tracker/features/players/domain/usecases/get_all_players.dart';
import 'package:calcetto_tracker/features/players/domain/usecases/update_player.dart';
import 'package:calcetto_tracker/features/players/presentation/controllers/players_controller.dart';
import 'package:calcetto_tracker/features/players/presentation/pages/players_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockGetAllPlayers extends Mock implements GetAllPlayers {}

class MockAddPlayer extends Mock implements AddPlayer {}

class MockUpdatePlayer extends Mock implements UpdatePlayer {}

class MockDeletePlayer extends Mock implements DeletePlayer {}

const _mario = Player(id: 'p1', name: 'Mario', role: 'A', icon: 'star');
const _luigi = Player(id: 'p2', name: 'Luigi', role: 'D', icon: 'person');

void main() {
  late MockGetAllPlayers getAllPlayers;
  late MockAddPlayer addPlayer;
  late MockUpdatePlayer updatePlayer;
  late MockDeletePlayer deletePlayer;
  late PlayersController controller;

  setUpAll(() {
    registerFallbackValue(_mario);
  });

  setUp(() {
    getAllPlayers = MockGetAllPlayers();
    addPlayer = MockAddPlayer();
    updatePlayer = MockUpdatePlayer();
    deletePlayer = MockDeletePlayer();
    controller = PlayersController(
      getAllPlayers: getAllPlayers,
      addPlayer: addPlayer,
      updatePlayer: updatePlayer,
      deletePlayer: deletePlayer,
    );
  });

  Widget wrap(Widget child) => MaterialApp(
        home: ChangeNotifierProvider<PlayersController>.value(
          value: controller,
          child: child,
        ),
      );

  testWidgets('shows the empty state when there are no players',
      (tester) async {
    when(() => getAllPlayers())
        .thenAnswer((_) async => Result.success(const []));
    await controller.load();

    await tester.pumpWidget(wrap(const PlayersView()));

    expect(find.text('NESSUN GIOCATORE'), findsOneWidget);
  });

  testWidgets('renders one row per player, sorted by name, with role badges',
      (tester) async {
    when(() => getAllPlayers())
        .thenAnswer((_) async => Result.success(const [_mario, _luigi]));
    await controller.load();

    await tester.pumpWidget(wrap(const PlayersView()));

    expect(find.text('MARIO'), findsOneWidget);
    expect(find.text('LUIGI'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
    expect(find.byIcon(Icons.edit_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.delete_outline_rounded), findsNWidgets(2));
  });

  testWidgets('tapping the FAB opens the "new player" form', (tester) async {
    when(() => getAllPlayers())
        .thenAnswer((_) async => Result.success(const []));
    await controller.load();

    await tester.pumpWidget(wrap(const PlayersView()));
    await tester.tap(find.byIcon(Icons.person_add_rounded));
    await tester.pumpAndSettle();

    expect(find.text('NUOVO GIOCATORE'), findsOneWidget);
    expect(find.text('AGGIUNGI'), findsOneWidget);
  });

  testWidgets(
      'filling the "new player" form and confirming calls controller.add with the expected values',
      (tester) async {
    when(() => getAllPlayers())
        .thenAnswer((_) async => Result.success(const []));
    when(() => addPlayer(
          name: any(named: 'name'),
          icon: any(named: 'icon'),
          role: any(named: 'role'),
          imagePath: any(named: 'imagePath'),
        )).thenAnswer((_) async => Result.success(_mario));
    await controller.load();

    await tester.pumpWidget(wrap(const PlayersView()));
    await tester.tap(find.byIcon(Icons.person_add_rounded));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Nuovo Giocatore Test');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A — Attaccante').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('AGGIUNGI'));
    await tester.pumpAndSettle();

    final captured = verify(() => addPlayer(
          name: captureAny(named: 'name'),
          icon: captureAny(named: 'icon'),
          role: captureAny(named: 'role'),
          imagePath: captureAny(named: 'imagePath'),
        )).captured;
    expect(captured[0], 'Nuovo Giocatore Test');
    expect(captured[2], 'A');
  });
}
