import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/ui.dart';
import 'leaderboard_tab.dart';
import 'members_tab.dart';
import 'matches_tab.dart';

class GroupPage extends ConsumerWidget {
  const GroupPage({super.key, required this.groupId});
  final int groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(groupDetailProvider(groupId));
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(detail.value?.group.name ?? 'Grupo'),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.sports_soccer), text: 'Partidos'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Ranking'),
            Tab(icon: Icon(Icons.group), text: 'Miembros'),
          ]),
        ),
        body: AsyncBody(
          value: detail,
          onRetry: () => ref.invalidate(groupDetailProvider(groupId)),
          data: (d) => Centered(
            child: TabBarView(children: [
              MatchesTab(groupId: groupId, competitionCode: d.group.competitionCode),
              LeaderboardTab(groupId: groupId),
              MembersTab(detail: d),
            ]),
          ),
        ),
      ),
    );
  }
}
