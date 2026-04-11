import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Sets up global error handling for the app.
void setupErrorHandling() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[Juku Error] ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[Juku PlatformError] $error\n$stack');
    return true;
  };
}

/// Fallback error widget shown when a widget tree fails to build.
class AppErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;
  const AppErrorWidget({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Try going back or restarting the app.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
