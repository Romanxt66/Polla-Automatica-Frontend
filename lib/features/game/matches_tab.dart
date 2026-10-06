import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../models/models.dart';

class MatchesTab extends ConsumerWidget {
  const MatchesTab({
    super.key,
    required this.groupId,
    required this.competitionCode,
  });
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
          final upcoming =
              all
                  .where((m) => !m.isFinished && m.status != 'POSTPONED')
                  .toList()
                ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
          final done = all.where((m) => m.isFinished).toList()
            ..sort((a, b) => b.kickoff.compareTo(a.kickoff));
          if (all.isEmpty) {
            return RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Todavía no hay partidos cargados para esta competición.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.colors.inkMuted),
                    ),
                  ),
                ],
              ),
            );
          }
          Widget card(MatchItem m) => MatchCard(
            key: ValueKey('m${m.id}'),
            match: m,
            groupId: groupId,
            prediction: byMatch[m.id],
            now: now,
          );
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                ..._byDay(upcoming, card),
                if (done.isNotEmpty && upcoming.isNotEmpty)
                  const SizedBox(height: 8),
                if (done.isNotEmpty)
                  ..._byDay(done, card, prefix: 'Terminado · '),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Agrupa por día: encabezado en mayúsculas y cuadrícula de tarjetas.
List<Widget> _byDay(
  List<MatchItem> items,
  Widget Function(MatchItem) card, {
  String prefix = '',
}) {
  final days = <String, List<MatchItem>>{};
  for (final m in items) {
    days.putIfAbsent(formatDay(m.kickoff), () => []).add(m);
  }
  return [
    for (final e in days.entries) ...[
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Overline('$prefix${e.key}'),
      ),
      CardGrid(children: [for (final m in e.value) card(m)]),
      const SizedBox(height: 24),
    ],
  ];
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
    _home = TextEditingController(
      text: widget.prediction?.home.toString() ?? '',
    )..addListener(_onChanged);
    _away = TextEditingController(
      text: widget.prediction?.away.toString() ?? '',
    )..addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _home.dispose();
    _away.dispose();
    super.dispose();
  }

  static int? _score(String text) {
    final n = int.tryParse(text);
    return (n == null || n < 0 || n > 99) ? null : n;
  }

  Future<void> _save() async {
    final home = _score(_home.text);
    final away = _score(_away.text);
    if (home == null || away == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(apiProvider)
          .savePrediction(widget.groupId, widget.match.id, home, away);
      ref.invalidate(predictionsProvider(widget.groupId));
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
    final c = context.colors;
    final saved = widget.prediction;

    final home = _score(_home.text);
    final away = _score(_away.text);
    final valid = home != null && away != null;
    final dirty = saved == null || home != saved.home || away != saved.away;

    Widget team(String name) => Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 15,
        height: 20 / 15,
        fontWeight: FontWeight.w500,
      ),
    );

    Widget score(Widget w) => SizedBox(width: 52, child: Center(child: w));

    Widget digit(int? n) => Text(
      n?.toString() ?? '–',
      style: const TextStyle(
        fontSize: 20,
        height: 24 / 20,
        fontWeight: FontWeight.w700,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );

    Widget footer() {
      if (!open) {
        return Text(
          saved == null
              ? 'Sin pronóstico'
              : 'Tu pronóstico: ${saved.home} – ${saved.away}',
          style: TextStyle(fontSize: 13, color: c.inkMuted),
        );
      }
      if (saved != null && !dirty) {
        return Text(
          '✓ Guardado',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.brandStrong,
          ),
        );
      }
      if (!valid) return const SizedBox.shrink();
      return Row(
        children: [
          Expanded(
            child: Text(
              'Cambios sin guardar',
              style: TextStyle(fontSize: 13, color: c.inkMuted),
            ),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
            child: LoadingLabel(loading: _saving, label: 'Guardar'),
          ),
        ],
      );
    }

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Overline(formatTime(m.kickoff))),
              _statusChip(m, open, c),
            ],
          ),
          const SizedBox(height: 12),
          for (final side in [true, false]) ...[
            if (!side) const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: team(side ? m.homeTeam : m.awayTeam)),
                if (open)
                  _ScoreField(
                    fieldKey: Key(side ? 'home' : 'away'),
                    controller: side ? _home : _away,
                    semanticLabel: 'Goles de ${side ? m.homeTeam : m.awayTeam}',
                  )
                else
                  score(digit(side ? m.homeScore : m.awayScore)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: c.line),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.topLeft,
            child: SizedBox(width: double.infinity, child: footer()),
          ),
        ],
      ),
    );
  }
}

Widget _statusChip(MatchItem m, bool open, AppColors c) {
  final (text, color, soft) = switch (m.status) {
    'FINISHED' => ('Terminado', c.inkMuted, c.line),
    'LIVE' => ('En juego', c.live, c.liveSoft),
    'POSTPONED' => ('Aplazado', c.live, c.liveSoft),
    _ =>
      open
          ? ('Abierto', c.brandStrong, c.brandSoft)
          : ('Cerrado', c.inkMuted, c.line),
  };
  return StatusChip(
    text: text,
    color: color,
    soft: soft,
    pulse: m.status == 'LIVE',
  );
}

class _ScoreField extends StatelessWidget {
  const _ScoreField({
    required this.fieldKey,
    required this.controller,
    required this.semanticLabel,
  });
  final Key fieldKey;
  final TextEditingController controller;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 52,
    child: Semantics(
      label: semanticLabel,
      child: TextField(
        key: fieldKey,
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    ),
  );
}
