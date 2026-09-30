/// Interpreta la fecha como UTC aunque el servidor no mande zona horaria.
DateTime parseUtc(String value) {
  final hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(value);
  return DateTime.parse(hasZone ? value : '${value}Z').toUtc();
}

class AppUser {
  AppUser({required this.id, required this.email, required this.username});
  final int id;
  final String email;
  final String username;

  factory AppUser.fromJson(Map<String, dynamic> j) =>
      AppUser(id: j['id'], email: j['email'], username: j['username']);
}

class Competition {
  Competition({required this.code, required this.name, this.country});
  final String code;
  final String name;
  final String? country;

  factory Competition.fromJson(Map<String, dynamic> j) =>
      Competition(code: j['code'], name: j['name'], country: j['country']);
}

class Group {
  Group({
    required this.id,
    required this.name,
    required this.competitionCode,
    required this.ownerId,
    required this.memberCount,
  });
  final int id;
  final String name;
  final String competitionCode;
  final int ownerId;
  final int memberCount;

  factory Group.fromJson(Map<String, dynamic> j) => Group(
        id: j['id'],
        name: j['name'],
        competitionCode: j['competition_code'],
        ownerId: j['owner_id'],
        memberCount: j['member_count'],
      );
}

class Member {
  Member({required this.userId, required this.username});
  final int userId;
  final String username;

  factory Member.fromJson(Map<String, dynamic> j) =>
      Member(userId: j['user_id'], username: j['username']);
}

class GroupDetail {
  GroupDetail({required this.group, required this.members});
  final Group group;
  final List<Member> members;

  factory GroupDetail.fromJson(Map<String, dynamic> j) => GroupDetail(
        group: Group.fromJson(j),
        members: [for (final m in j['members']) Member.fromJson(m)],
      );
}

class MatchItem {
  MatchItem({
    required this.id,
    required this.competitionCode,
    required this.homeTeam,
    required this.awayTeam,
    required this.kickoff,
    required this.status,
    this.homeScore,
    this.awayScore,
  });
  final int id;
  final String competitionCode;
  final String homeTeam;
  final String awayTeam;
  final DateTime kickoff;
  final String status; // SCHEDULED | LIVE | FINISHED | POSTPONED
  final int? homeScore;
  final int? awayScore;

  factory MatchItem.fromJson(Map<String, dynamic> j) => MatchItem(
        id: j['id'],
        competitionCode: j['competition_code'],
        homeTeam: j['home_team'],
        awayTeam: j['away_team'],
        kickoff: parseUtc(j['kickoff_at']),
        status: j['status'],
        homeScore: j['home_score'],
        awayScore: j['away_score'],
      );

  /// Se puede pronosticar solo antes del inicio (el servidor lo valida igual).
  bool isOpen([DateTime? now]) =>
      status == 'SCHEDULED' && kickoff.isAfter((now ?? DateTime.now()).toUtc());
  bool get isFinished => status == 'FINISHED';
}

class Prediction {
  Prediction({required this.matchId, required this.home, required this.away});
  final int matchId;
  final int home;
  final int away;

  factory Prediction.fromJson(Map<String, dynamic> j) =>
      Prediction(matchId: j['match_id'], home: j['home_score'], away: j['away_score']);
}

class LeaderboardEntry {
  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.points,
    required this.exactHits,
    required this.scored,
  });
  final int rank;
  final int userId;
  final String username;
  final int points;
  final int exactHits;
  final int scored;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        rank: j['rank'],
        userId: j['user_id'],
        username: j['username'],
        points: j['points'],
        exactHits: j['exact_hits'],
        scored: j['scored_predictions'],
      );
}

class InviteCode {
  InviteCode({required this.code, this.expiresAt});
  final String code;
  final DateTime? expiresAt;

  factory InviteCode.fromJson(Map<String, dynamic> j) => InviteCode(
        code: j['code'],
        expiresAt: j['expires_at'] == null ? null : parseUtc(j['expires_at']),
      );
}
