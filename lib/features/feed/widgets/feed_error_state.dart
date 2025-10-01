import 'package:flutter/material.dart';

class FeedErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const FeedErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar el feed',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getErrorMessage(error),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(String error) {
    if (error.contains('Ubicación no disponible')) {
      return 'No se pudo obtener tu ubicación. Verifica que tengas permisos de ubicación activados.';
    } else if (error.contains('conexión')) {
      return 'Problema de conexión. Verifica tu internet e intenta nuevamente.';
    } else {
      return 'Algo salió mal. Intenta nuevamente en unos momentos.';
    }
  }
}
