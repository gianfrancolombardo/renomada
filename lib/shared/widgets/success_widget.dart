import 'package:flutter/material.dart';

class SuccessWidget extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onContinue;
  final String? continueText;

  const SuccessWidget({
    super.key,
    required this.message,
    this.details,
    this.onContinue,
    this.continueText = 'Continuar',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 40,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Success message
            Text(
              message,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.tertiary,
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
            
            if (onContinue != null) ...[
              const SizedBox(height: 24),
              
              // Continue button
              ElevatedButton(
                onPressed: onContinue,
                child: Text(continueText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
