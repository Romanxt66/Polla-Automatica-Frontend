import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/ui.dart';
import '../../models/models.dart';

class MembersTab extends ConsumerStatefulWidget {
  const MembersTab({super.key, required this.detail});
  final GroupDetail detail;

  @override
  ConsumerState<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends ConsumerState<MembersTab> {
  InviteCode? _invite;
  bool _loading = false;

  Future<void> _createInvite() async {
    setState(() => _loading = true);
    try {
      final invite = await ref.read(apiProvider).createInvite(widget.detail.group.id);
      if (mounted) setState(() => _invite = invite);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Invita a tus amigos', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                    '${competitionNames[detail.group.competitionCode] ?? detail.group.competitionCode}. Comparte el código y se unen desde "Tengo un código de invitación".'),
                const SizedBox(height: 12),
                if (_invite != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SelectableText(_invite!.code,
                          style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 4)),
                      IconButton(
                        tooltip: 'Copiar',
                        icon: const Icon(Icons.copy),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: _invite!.code));
                          if (context.mounted) showInfo(context, 'Código copiado');
                        },
                      ),
                    ],
                  ),
                  if (_invite!.expiresAt != null)
                    Text('Vence el ${formatKickoff(_invite!.expiresAt!.toUtc())}',
                        textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                ],
                FilledButton.tonalIcon(
                  onPressed: _loading ? null : _createInvite,
                  icon: const Icon(Icons.link),
                  label: Text(_invite == null ? 'Generar código' : 'Generar otro código'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Miembros (${detail.members.length})', style: theme.textTheme.titleMedium),
        ),
        for (final m in detail.members)
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(m.username),
            trailing: m.userId == detail.group.ownerId ? const Chip(label: Text('Dueño')) : null,
          ),
      ],
    );
  }
}
