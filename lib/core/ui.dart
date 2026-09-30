import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_exception.dart';

void showError(BuildContext context, Object error) {
  final message = switch (error) {
    ApiException e => e.message,
    String s => s,
    _ => 'Ocurrió un error inesperado',
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red.shade700));
}

void showInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String formatKickoff(DateTime utc) =>
    DateFormat("EEE d MMM, HH:mm", 'es').format(utc.toLocal());

const competitionNames = {
  'BETPLAY': 'Liga BetPlay',
  'UCL': 'Champions League',
  'PL': 'Premier League',
};

/// Contenedor centrado con ancho máximo, para que se vea bien en web.
class Centered extends StatelessWidget {
  const Centered({super.key, required this.child, this.maxWidth = 640});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

/// Estado de carga / error / datos para un AsyncValue en una línea.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.data, this.onRetry});
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
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(e is ApiException ? e.message : 'No se pudo cargar',
                  textAlign: TextAlign.center),
              if (onRetry != null)
                TextButton(onPressed: onRetry, child: const Text('Reintentar')),
            ]),
          ),
        ),
      );
}
