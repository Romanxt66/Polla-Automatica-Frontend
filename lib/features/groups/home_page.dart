import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/ui.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _join(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unirme a un grupo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Código de invitación'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Unirme')),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.trim().isEmpty || !context.mounted) return;
    try {
      final group = await ref.read(apiProvider).joinGroup(code.trim());
      ref.invalidate(groupsProvider);
      if (context.mounted) context.push('/groups/${group.id}');
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);
    final user = ref.watch(authProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis grupos'),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: Text(user.username)),
            ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/groups/new'),
        icon: const Icon(Icons.add),
        label: const Text('Crear grupo'),
      ),
      body: Centered(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(groupsProvider.future),
          child: AsyncBody(
            value: groups,
            onRetry: () => ref.invalidate(groupsProvider),
            data: (list) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                OutlinedButton.icon(
                  onPressed: () => _join(context, ref),
                  icon: const Icon(Icons.group_add),
                  label: const Text('Tengo un código de invitación'),
                ),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Aún no estás en ningún grupo.\nCrea uno e invita a tus amigos.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final g in list)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.emoji_events_outlined),
                      title: Text(g.name),
                      subtitle: Text(
                          '${competitionNames[g.competitionCode] ?? g.competitionCode} · ${g.memberCount} ${g.memberCount == 1 ? 'miembro' : 'miembros'}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/groups/${g.id}'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
