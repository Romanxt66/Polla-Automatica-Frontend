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

/// Pantalla de acceso: marca arriba, mensaje a la izquierda (solo en pantallas
/// anchas) y una tarjeta de vidrio con el formulario.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.form,
  });
  final String title;
  final String subtitle;
  final Widget form;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final card = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: GlassCard(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.inkMuted),
            ),
            const SizedBox(height: 28),
            form,
          ],
        ),
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth >= 900;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 48 : 16,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: _Brand(),
                      ),
                      SizedBox(height: wide ? 72 : 32),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(child: _Hero()),
                            const SizedBox(width: 48),
                            Expanded(
                              child: Align(
                                alignment: Alignment.center,
                                child: card,
                              ),
                            ),
                          ],
                        )
                      else
                        card,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: c.brand,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(Icons.sports_soccer, size: 20, color: c.onBrand),
        ),
        const SizedBox(width: 10),
        const Text(
          'Polla Automática',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const style = TextStyle(
      fontSize: 48,
      height: 1.1,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: style,
            children: [
              const TextSpan(text: 'Pronostica con amigos y domina la '),
              TextSpan(
                text: 'tabla de posiciones',
                style: TextStyle(color: c.brand),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(
            'Crea tu polla en segundos, suma puntos cuando termina cada partido y compite con tu grupo.',
            style: TextStyle(fontSize: 16, height: 1.5, color: c.inkMuted),
          ),
        ),
      ],
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
