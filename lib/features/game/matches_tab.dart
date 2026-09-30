import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/ui.dart';
import '../../models/models.dart';

class MatchesTab extends ConsumerWidget {
  const MatchesTab({super.key, required this.groupId, required this.competitionCode});
  final int groupId;
  final String competitionCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchesProvider(competitionCode));
    final predictions = ref.watch(predictionsProvider(groupId));

    Future<void> refresh() async {
      ref.invalidate(matchesProvider(competitionCode));
      ref.invalidate(predictionsProvider(groupId));
      await ref.read(matchesProvider(competitionCode).future);
    }

    return AsyncBody(
      value: matches,
      onRetry: refresh,
      data: (all) => AsyncBody(
        value: predictions,
        onRetry: refresh,
        data: (preds) {
          final byMatch = {for (final p in preds) p.matchId: p};
          final now = DateTime.now();
          final upcoming = all.where((m) => !m.isFinished && m.status != 'POSTPONED').toList()
            ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
          final done = all.where((m) => m.isFinished).toList()
            ..sort((a, b) => b.kickoff.compareTo(a.kickoff));
          if (all.isEmpty) {
            return RefreshIndicator(
              onRefresh: refresh,
              child: ListView(children: const [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Todavía no hay partidos cargados para esta competición.',
                      textAlign: TextAlign.center),
                ),
              ]),
            );
          }
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (upcoming.isNotEmpty) const _SectionTitle('Próximos y en juego'),
                for (final m in upcoming)
                  MatchCard(
                    key: ValueKey('m${m.id}'),
                    match: m,
                    groupId: groupId,
                    prediction: byMatch[m.id],
                    now: now,
                  ),
                if (done.isNotEmpty) const _SectionTitle('Terminados'),
                for (final m in done)
                  MatchCard(
                    key: ValueKey('m${m.id}'),
                    match: m,
                    groupId: groupId,
                    prediction: byMatch[m.id],
                    now: now,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

class MatchCard extends ConsumerStatefulWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.groupId,
    required this.prediction,
    required this.now,
  });
  final MatchItem match;
  final int groupId;
  final Prediction? prediction;
  final DateTime now;

  @override
  ConsumerState<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends ConsumerState<MatchCard> {
  late final TextEditingController _home;
  late final TextEditingController _away;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _home = TextEditingController(text: widget.prediction?.home.toString() ?? '');
    _away = TextEditingController(text: widget.prediction?.away.toString() ?? '');
  }

  @override
  void dispose() {
    _home.dispose();
    _away.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final home = int.tryParse(_home.text);
    final away = int.tryParse(_away.text);
    if (home == null || away == null || home < 0 || away < 0 || home > 99 || away > 99) {
      showError(context, 'Ingresa dos marcadores entre 0 y 99');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(apiProvider)
          .savePrediction(widget.groupId, widget.match.id, home, away);
      ref.invalidate(predictionsProvider(widget.groupId));
      if (mounted) showInfo(context, 'Pronóstico guardado');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final open = m.isOpen(widget.now);
    final theme = Theme.of(context);
    final saved = widget.prediction;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(formatKickoff(m.kickoff), style: theme.textTheme.bodySmall)),
                _StatusChip(match: m, open: open),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: Text(m.homeTeam,
                        textAlign: TextAlign.end, style: theme.textTheme.titleSmall)),
                const SizedBox(width: 8),
                if (open) ...[
                  _ScoreField(controller: _home, label: 'L'),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('-')),
                  _ScoreField(controller: _away, label: 'V'),
                ] else
                  Text(
                    m.homeScore != null ? '${m.homeScore} - ${m.awayScore}' : 'vs',
                    style: theme.textTheme.titleLarge,
                  ),
                const SizedBox(width: 8),
                Expanded(child: Text(m.awayTeam, style: theme.textTheme.titleSmall)),
              ],
            ),
            const SizedBox(height: 8),
            if (open)
              Align(
                alignment: Alignment.center,
                child: FilledButton.tonal(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(saved == null ? 'Guardar pronóstico' : 'Actualizar pronóstico'),
                ),
              )
            else
              Text(
                saved == null
                    ? 'No pronosticaste este partido'
                    : 'Tu pronóstico: ${saved.home} - ${saved.away}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}

class _ScoreField extends StatelessWidget {
  const _ScoreField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 52,
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.match, required this.open});
  final MatchItem match;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (match.status) {
      'FINISHED' => ('Terminado', Colors.grey),
      'LIVE' => ('En juego', Colors.red),
      'POSTPONED' => ('Aplazado', Colors.orange),
      _ => open ? ('Abierto', Colors.green) : ('Cerrado', Colors.grey),
    };
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color),
      backgroundColor: color.withValues(alpha: 0.12),
    );
  }
}
