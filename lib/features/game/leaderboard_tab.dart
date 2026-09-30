import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
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
        data: (rows) => ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'El ranking se actualiza solo cuando termina cada partido.',
                textAlign: TextAlign.center,
              ),
            ),
            for (final r in rows)
              Card(
                color: r.userId == me?.id ? Theme.of(context).colorScheme.primaryContainer : null,
                child: ListTile(
                  leading: CircleAvatar(child: Text('${r.rank}')),
                  title: Text(r.username),
                  subtitle: Text(
                      '${r.exactHits} ${r.exactHits == 1 ? 'exacto' : 'exactos'} · ${r.scored} ${r.scored == 1 ? 'partido' : 'partidos'}'),
                  trailing: Text('${r.points} pts',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
