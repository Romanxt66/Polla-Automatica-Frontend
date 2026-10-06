import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';

class LeaderboardTab extends ConsumerWidget {
  const LeaderboardTab({super.key, required this.groupId});
  final int groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(leaderboardProvider(groupId));
    final me = ref.watch(authProvider).value;
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(leaderboardProvider(groupId).future),
      child: AsyncBody(
        value: board,
        onRetry: () => ref.invalidate(leaderboardProvider(groupId)),
        data: (rows) {
          final c = context.colors;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text(
                  'El ranking se actualiza solo cuando termina cada partido.',
                  style: TextStyle(fontSize: 13, color: c.inkMuted),
                ),
              ),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0) Divider(color: c.line),
                      Container(
                        color: rows[i].userId == me?.id ? c.brandSoft : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${rows[i].rank}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: rows[i].rank == 1
                                      ? c.brandStrong
                                      : c.inkMuted,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rows[i].username,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${rows[i].exactHits} ${rows[i].exactHits == 1 ? 'exacto' : 'exactos'} · ${rows[i].scored} ${rows[i].scored == 1 ? 'partido' : 'partidos'}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: c.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${rows[i].points} pts',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
