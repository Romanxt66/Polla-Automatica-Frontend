import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polla_app/core/api_exception.dart';
import 'package:polla_app/models/models.dart';

Map<String, dynamic> matchJson({String status = 'SCHEDULED', String kickoff = '2030-01-01T15:00:00Z'}) => {
      'id': 1,
      'competition_code': 'PL',
      'home_team': 'Arsenal',
      'away_team': 'Chelsea',
      'kickoff_at': kickoff,
      'status': status,
      'home_score': null,
      'away_score': null,
    };

void main() {
  group('MatchItem', () {
    test('parsea y deja marcadores nulos', () {
      final m = MatchItem.fromJson(matchJson());
      expect(m.homeTeam, 'Arsenal');
      expect(m.homeScore, isNull);
      expect(m.kickoff.isUtc, isTrue);
    });

    test('isOpen solo si está programado y no ha empezado', () {
      final future = MatchItem.fromJson(matchJson());
      expect(future.isOpen(DateTime.utc(2029)), isTrue);
      expect(future.isOpen(DateTime.utc(2030, 1, 1, 15, 0, 1)), isFalse);
      expect(MatchItem.fromJson(matchJson(status: 'LIVE')).isOpen(DateTime.utc(2029)), isFalse);
      expect(MatchItem.fromJson(matchJson(status: 'FINISHED')).isOpen(DateTime.utc(2029)), isFalse);
    });

    test('kickoff sin zona horaria se interpreta como UTC', () {
      final m = MatchItem.fromJson(matchJson(kickoff: '2026-09-28T15:00:00'));
      expect(m.kickoff, DateTime.utc(2026, 9, 28, 15));
    });

    test('kickoff con zona horaria se normaliza a UTC', () {
      final m = MatchItem.fromJson(matchJson(kickoff: '2030-01-01T10:00:00-05:00'));
      expect(m.kickoff, DateTime.utc(2030, 1, 1, 15));
    });
  });

  test('Group, GroupDetail y LeaderboardEntry parsean la respuesta de la API', () {
    final detail = GroupDetail.fromJson({
      'id': 3,
      'name': 'Parceros',
      'competition_code': 'UCL',
      'owner_id': 7,
      'member_count': 2,
      'created_at': '2026-10-01T00:00:00Z',
      'members': [
        {'user_id': 7, 'username': 'ana', 'joined_at': '2026-10-01T00:00:00Z'},
        {'user_id': 8, 'username': 'beto', 'joined_at': '2026-10-01T00:00:00Z'},
      ],
    });
    expect(detail.group.competitionCode, 'UCL');
    expect(detail.members.map((m) => m.username), ['ana', 'beto']);

    final row = LeaderboardEntry.fromJson({
      'rank': 1,
      'user_id': 7,
      'username': 'ana',
      'points': 8,
      'exact_hits': 1,
      'scored_predictions': 2,
    });
    expect((row.rank, row.points, row.exactHits, row.scored), (1, 8, 1, 2));
  });

  group('ApiException', () {
    DioException err(dynamic data, {int status = 400, DioExceptionType type = DioExceptionType.badResponse}) =>
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: type,
          response: Response(requestOptions: RequestOptions(path: '/x'), statusCode: status, data: data),
        );

    test('usa detail cuando es texto', () {
      final e = ApiException.fromDio(err({'detail': 'Email o usuario ya registrado'}, status: 409));
      expect(e.message, 'Email o usuario ya registrado');
      expect(e.statusCode, 409);
    });

    test('toma el primer mensaje de validación de FastAPI', () {
      final e = ApiException.fromDio(err({
        'detail': [
          {'loc': ['body', 'password'], 'msg': 'String should have at least 8 characters'}
        ]
      }, status: 422));
      expect(e.message, contains('at least 8'));
    });

    test('error de conexión da mensaje claro', () {
      final e = ApiException.fromDio(DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      ));
      expect(e.message, 'No se pudo conectar con el servidor');
    });
  });
}
