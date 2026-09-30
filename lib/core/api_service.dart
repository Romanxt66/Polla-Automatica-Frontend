import 'package:dio/dio.dart';

import '../models/models.dart';
import 'api_exception.dart';

/// Envoltorio tipado sobre la API de FastAPI.
class ApiService {
  ApiService(this._dio);
  final Dio _dio;

  Future<T> _call<T>(Future<Response<dynamic>> Function() request, T Function(dynamic) parse) async {
    try {
      final res = await request();
      return parse(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  List<Map<String, dynamic>> _list(dynamic data) => [for (final e in data as List) e as Map<String, dynamic>];

  // --- auth ---
  Future<void> register(String email, String username, String password) => _call(
        () => _dio.post('/auth/register',
            data: {'email': email, 'username': username, 'password': password}),
        (_) {},
      );

  Future<String> login(String email, String password) => _call(
        () => _dio.post('/auth/login', data: {'email': email, 'password': password}),
        (d) => d['access_token'] as String,
      );

  Future<AppUser> me() => _call(() => _dio.get('/auth/me'), (d) => AppUser.fromJson(d));

  // --- competiciones y partidos ---
  Future<List<Competition>> competitions() => _call(
        () => _dio.get('/competitions'),
        (d) => [for (final j in _list(d)) Competition.fromJson(j)],
      );

  Future<List<MatchItem>> matches(String competitionCode) => _call(
        () => _dio.get('/matches', queryParameters: {'competition': competitionCode, 'limit': 200}),
        (d) => [for (final j in _list(d)) MatchItem.fromJson(j)],
      );

  // --- grupos ---
  Future<List<Group>> groups() =>
      _call(() => _dio.get('/groups'), (d) => [for (final j in _list(d)) Group.fromJson(j)]);

  Future<Group> createGroup(String name, String competitionCode) => _call(
        () => _dio.post('/groups', data: {'name': name, 'competition_code': competitionCode}),
        (d) => Group.fromJson(d),
      );

  Future<GroupDetail> groupDetail(int id) =>
      _call(() => _dio.get('/groups/$id'), (d) => GroupDetail.fromJson(d));

  Future<InviteCode> createInvite(int groupId) =>
      _call(() => _dio.post('/groups/$groupId/invites', data: {}), (d) => InviteCode.fromJson(d));

  Future<Group> joinGroup(String code) =>
      _call(() => _dio.post('/groups/join', data: {'code': code}), (d) => Group.fromJson(d));

  Future<List<LeaderboardEntry>> leaderboard(int groupId) => _call(
        () => _dio.get('/groups/$groupId/leaderboard'),
        (d) => [for (final j in _list(d)) LeaderboardEntry.fromJson(j)],
      );

  // --- predicciones ---
  Future<List<Prediction>> predictions(int groupId) => _call(
        () => _dio.get('/groups/$groupId/predictions'),
        (d) => [for (final j in _list(d)) Prediction.fromJson(j)],
      );

  Future<Prediction> savePrediction(int groupId, int matchId, int home, int away) => _call(
        () => _dio.put('/groups/$groupId/predictions/$matchId',
            data: {'home_score': home, 'away_score': away}),
        (d) => Prediction.fromJson(d),
      );
}
