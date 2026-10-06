import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
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
      child: Builder(
        builder: (context) {
          final tabs = DefaultTabController.of(context);
          return Scaffold(
            appBar: AppBar(
              toolbarHeight: 64,
              title: Text(detail.value?.group.name ?? 'Grupo'),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Centered(
                  maxWidth: 420,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SegmentedTabs(
                      controller: tabs,
                      labels: const ['Partidos', 'Ranking', 'Miembros'],
                    ),
                  ),
                ),
              ),
            ),
            body: AsyncBody(
              value: detail,
              onRetry: () => ref.invalidate(groupDetailProvider(groupId)),
              data: (d) => Centered(
                child: TabBarView(
                  children: [
                    MatchesTab(
                      groupId: groupId,
                      competitionCode: d.group.competitionCode,
                    ),
                    LeaderboardTab(groupId: groupId),
                    MembersTab(detail: d),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
