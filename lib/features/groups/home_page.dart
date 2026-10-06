import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Unirme'),
          ),
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
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 16,
        title: const Text('Mis grupos'),
        actions: [
          if (user != null)
            Text(
              user.username,
              style: TextStyle(color: c.inkMuted, fontSize: 13),
            ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Centered(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(groupsProvider.future),
          child: AsyncBody(
            value: groups,
            onRetry: () => ref.invalidate(groupsProvider),
            data: (list) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.push('/groups/new'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Crear grupo'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _join(context, ref),
                      icon: const Icon(Icons.group_add_outlined, size: 18),
                      label: const Text('Tengo un código de invitación'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Aún no estás en ningún grupo.\nCrea uno e invita a tus amigos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.inkMuted),
                    ),
                  )
                else
                  CardGrid(
                    children: [
                      for (final g in list)
                        InkWell(
                          borderRadius: BorderRadius.circular(radiusMd),
                          onTap: () => context.push('/groups/${g.id}'),
                          child: GlassCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        g.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${competitionNames[g.competitionCode] ?? g.competitionCode} · ${g.memberCount} ${g.memberCount == 1 ? 'miembro' : 'miembros'}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: c.inkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: c.inkMuted),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
