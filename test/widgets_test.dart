import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:polla_app/core/api_service.dart';
import 'package:polla_app/core/providers.dart';
import 'package:polla_app/core/theme.dart';
import 'package:polla_app/features/game/leaderboard_tab.dart';
import 'package:polla_app/features/game/matches_tab.dart';
import 'package:polla_app/main.dart';
import 'package:polla_app/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApi extends Mock implements ApiService {}

Group group({int id = 1}) => Group(
  id: id,
  name: 'Parceros',
  competitionCode: 'PL',
  ownerId: 1,
  memberCount: 2,
);

MatchItem match({
  int id = 1,
  String status = 'SCHEDULED',
  int hours = 24,
  int? home,
  int? away,
}) => MatchItem(
  id: id,
  competitionCode: 'PL',
  homeTeam: 'Arsenal',
  awayTeam: 'Chelsea',
  kickoff: DateTime.now().toUtc().add(Duration(hours: hours)),
  status: status,
  homeScore: home,
  awayScore: away,
);

Future<void> pumpApp(
  WidgetTester tester,
  MockApi api, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(sp),
        apiProvider.overrideWithValue(api),
      ],
      child: const PollaApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pumpWidgetIn(
  WidgetTester tester,
  MockApi api,
  Widget child,
) async {
  SharedPreferences.setMockInitialValues({});
  final sp = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(sp),
        apiProvider.overrideWithValue(api),
      ],
      child: MaterialApp(theme: buildTheme(Brightness.dark), home: Scaffold(body: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('sin sesión muestra el login y valida campos vacíos', (
    tester,
  ) async {
    await pumpApp(tester, MockApi());
    expect(find.text('Entrar'), findsOneWidget);

    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Ingresa un email válido'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });

  testWidgets('login correcto lleva a Mis grupos y guarda el token', (
    tester,
  ) async {
    final api = MockApi();
    when(() => api.login('ana@x.com', 'clave12345'))
        .thenAnswer((_) async => 'tok');
    when(() => api.me()).thenAnswer(
      (_) async => AppUser(id: 1, email: 'ana@x.com', username: 'ana'),
    );
    when(() => api.groups()).thenAnswer((_) async => [group()]);

    await pumpApp(tester, api);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'ana@x.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'clave12345',
    );
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Mis grupos'), findsOneWidget);
    expect(find.text('Parceros'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('access_token'),
      'tok',
    );
  });

  testWidgets('con token guardado entra directo a Mis grupos', (tester) async {
    final api = MockApi();
    when(() => api.me()).thenAnswer(
      (_) async => AppUser(id: 1, email: 'a@x.com', username: 'ana'),
    );
    when(() => api.groups()).thenAnswer((_) async => []);
    await pumpApp(tester, api, prefs: {'access_token': 'tok'});
    expect(find.text('Mis grupos'), findsOneWidget);
    expect(find.textContaining('Aún no estás en ningún grupo'), findsOneWidget);
  });

  testWidgets(
    'partido abierto: guarda el pronóstico con los marcadores escritos',
    (tester) async {
      final api = MockApi();
      when(() => api.matches('PL')).thenAnswer((_) async => [match()]);
      when(() => api.predictions(1)).thenAnswer((_) async => []);
      when(() => api.savePrediction(1, 1, 2, 1))
          .thenAnswer((_) async => Prediction(matchId: 1, home: 2, away: 1));

      await pumpWidgetIn(
        tester,
        api,
        const MatchesTab(groupId: 1, competitionCode: 'PL'),
      );
      await tester.enterText(find.byKey(const Key('home')), '2');
      await tester.enterText(find.byKey(const Key('away')), '1');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      verify(() => api.savePrediction(1, 1, 2, 1)).called(1);
    },
  );

  testWidgets('partido abierto sin marcadores no ofrece guardar', (
    tester,
  ) async {
    final api = MockApi();
    when(() => api.matches('PL')).thenAnswer((_) async => [match()]);
    when(() => api.predictions(1)).thenAnswer((_) async => []);

    await pumpWidgetIn(
      tester,
      api,
      const MatchesTab(groupId: 1, competitionCode: 'PL'),
    );
    expect(find.text('Guardar'), findsNothing);

    await tester.enterText(find.byKey(const Key('home')), '2');
    await tester.pump();
    expect(find.text('Guardar'), findsNothing);
    verifyNever(() => api.savePrediction(any(), any(), any(), any()));
  });

  testWidgets(
    'pronóstico guardado muestra ✓ Guardado y el botón vuelve al editar',
    (tester) async {
      final api = MockApi();
      when(() => api.matches('PL')).thenAnswer((_) async => [match()]);
      when(() => api.predictions(1))
          .thenAnswer((_) async => [Prediction(matchId: 1, home: 2, away: 1)]);

      await pumpWidgetIn(
        tester,
        api,
        const MatchesTab(groupId: 1, competitionCode: 'PL'),
      );
      expect(find.text('✓ Guardado'), findsOneWidget);
      expect(find.text('Guardar'), findsNothing);

      await tester.enterText(find.byKey(const Key('home')), '3');
      await tester.pump();
      expect(find.text('Cambios sin guardar'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
    },
  );

  testWidgets(
    'partido cerrado no deja editar y muestra tu pronóstico y el resultado',
    (tester) async {
      final api = MockApi();
      when(() => api.matches('PL')).thenAnswer(
        (_) async => [match(status: 'FINISHED', hours: -48, home: 3, away: 1)],
      );
      when(() => api.predictions(1))
          .thenAnswer((_) async => [Prediction(matchId: 1, home: 2, away: 1)]);

      await pumpWidgetIn(
        tester,
        api,
        const MatchesTab(groupId: 1, competitionCode: 'PL'),
      );
      expect(find.text('Guardar'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Tu pronóstico: 2 – 1'), findsOneWidget);
      expect(find.text('Terminado'), findsOneWidget);
    },
  );

  testWidgets('partido que ya empezó (aunque siga programado) queda cerrado', (
    tester,
  ) async {
    final api = MockApi();
    when(() => api.matches('PL')).thenAnswer((_) async => [match(hours: -1)]);
    when(() => api.predictions(1)).thenAnswer((_) async => []);

    await pumpWidgetIn(
      tester,
      api,
      const MatchesTab(groupId: 1, competitionCode: 'PL'),
    );
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Sin pronóstico'), findsOneWidget);
  });

  testWidgets('ranking muestra posiciones y puntos', (tester) async {
    final api = MockApi();
    when(() => api.me()).thenAnswer(
      (_) async => AppUser(id: 2, email: 'b@x.com', username: 'beto'),
    );
    when(() => api.leaderboard(1)).thenAnswer(
      (_) async => [
        LeaderboardEntry(
          rank: 1,
          userId: 2,
          username: 'beto',
          points: 8,
          exactHits: 1,
          scored: 2,
        ),
        LeaderboardEntry(
          rank: 2,
          userId: 1,
          username: 'ana',
          points: 3,
          exactHits: 0,
          scored: 2,
        ),
      ],
    );

    await pumpWidgetIn(tester, api, const LeaderboardTab(groupId: 1));
    expect(find.text('beto'), findsOneWidget);
    expect(find.text('8 pts'), findsOneWidget);
    expect(find.text('3 pts'), findsOneWidget);
    expect(find.text('1 exacto · 2 partidos'), findsOneWidget);
  });
}
