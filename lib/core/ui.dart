import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_exception.dart';
import 'theme.dart';

void showError(BuildContext context, Object error) {
  final message = switch (error) {
    ApiException e => e.message,
    String s => s,
    _ => 'Ocurrió un error inesperado',
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: context.colors.danger)),
      ),
    );
}

void showInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String formatKickoff(DateTime utc) =>
    DateFormat("EEE d MMM, HH:mm", 'es').format(utc.toLocal());

String formatDay(DateTime utc) =>
    DateFormat("EEEE d MMM", 'es').format(utc.toLocal());

String formatTime(DateTime utc) => DateFormat('HH:mm').format(utc.toLocal());

const competitionNames = {
  'BETPLAY': 'Liga BetPlay',
  'UCL': 'Champions League',
  'PL': 'Premier League',
};

/// Contenedor centrado con ancho máximo, para que se vea bien en web.
class Centered extends StatelessWidget {
  const Centered({super.key, required this.child, this.maxWidth = 1040});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Estado de carga / error / datos para un AsyncValue en una línea.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
  });
  final AsyncValue<T> value;
  final Widget Function(T) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => value.when(
    data: data,
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              e is ApiException ? e.message : 'No se pudo cargar',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.inkMuted),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    ),
  );
}

/// Pantalla de acceso: marca mínima y una tarjeta de vidrio con el formulario.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.subtitle, required this.form});
  final String subtitle;
  final Widget form;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Centered(
              maxWidth: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_soccer, size: 40, color: c.brand),
                  const SizedBox(height: 12),
                  Text(
                    'Polla Automática',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: c.inkMuted)),
                  const SizedBox(height: 24),
                  GlassCard(padding: const EdgeInsets.all(20), child: form),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de formulario con indicador de carga.
class LoadingLabel extends StatelessWidget {
  const LoadingLabel({super.key, required this.loading, required this.label});
  final bool loading;
  final String label;

  @override
  Widget build(BuildContext context) => loading
      ? SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.colors.brand,
          ),
        )
      : Text(label);
}

/// Cuadrícula adaptable: 1 columna en móvil, 2 y 3 en pantallas anchas.
class CardGrid extends StatelessWidget {
  const CardGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const gap = 12.0;
      final cols = box.maxWidth >= 960 ? 3 : (box.maxWidth >= 620 ? 2 : 1);
      final w = (box.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final ch in children) SizedBox(width: w, child: ch)],
      );
    },
  );
}
