import 'package:flutter/material.dart';

class ErrorWidget extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final String? retryText;

  const ErrorWidget({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.retryText = 'Reintentar',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Error message
            Text(
              message,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              
              // Retry button
              ElevatedButton(
                onPressed: onRetry,
                child: Text(retryText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      message: 'Error de conexión',
      details: 'Verifica tu conexión a internet e intenta nuevamente.',
      onRetry: onRetry,
      retryText: 'Reintentar',
    );
  }
}

class PermissionErrorWidget extends StatelessWidget {
  final String permission;
  final VoidCallback? onGrantPermission;

  const PermissionErrorWidget({
    super.key,
    required this.permission,
    this.onGrantPermission,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      message: 'Permiso requerido',
      details: 'Necesitamos acceso a $permission para continuar.',
      onRetry: onGrantPermission,
      retryText: 'Conceder permiso',
    );
  }
}

class GenericErrorWidget extends StatelessWidget {
  final String? error;
  final VoidCallback? onRetry;

  const GenericErrorWidget({
    super.key,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      message: 'Algo salió mal',
      details: error ?? 'Ha ocurrido un error inesperado. Intenta nuevamente.',
      onRetry: onRetry,
    );
  }
}
