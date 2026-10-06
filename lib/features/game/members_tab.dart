import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
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
      final invite = await ref
          .read(apiProvider)
          .createInvite(widget.detail.group.id);
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
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Invita a tus amigos',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${competitionNames[detail.group.competitionCode] ?? detail.group.competitionCode}. Comparte el código y se unen desde "Tengo un código de invitación".',
                style: TextStyle(fontSize: 13, color: c.inkMuted),
              ),
              const SizedBox(height: 16),
              if (_invite != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SelectableText(
                      _invite!.code,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copiar',
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: _invite!.code),
                        );
                        if (context.mounted)
                          showInfo(context, 'Código copiado');
                      },
                    ),
                  ],
                ),
                if (_invite!.expiresAt != null)
                  Text(
                    'Vence el ${formatKickoff(_invite!.expiresAt!.toUtc())}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: c.inkMuted),
                  ),
                const SizedBox(height: 12),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _createInvite,
                  icon: const Icon(Icons.link, size: 18),
                  label: Text(
                    _invite == null ? 'Generar código' : 'Generar otro código',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Overline('Miembros (${detail.members.length})'),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < detail.members.length; i++) ...[
                if (i > 0) Divider(color: c.line),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          detail.members[i].username,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (detail.members[i].userId == detail.group.ownerId)
                        StatusChip(
                          text: 'Dueño',
                          color: c.brandStrong,
                          soft: c.brandSoft,
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
  }
}
