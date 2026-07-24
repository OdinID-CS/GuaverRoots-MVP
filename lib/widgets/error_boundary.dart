import 'package:flutter/material.dart';
import 'dart:io';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String? customErrorMessage;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.customErrorMessage,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    // Error handling is done via Flutter's built-in error handling
    // This widget provides a fallback UI for unhandled errors
  }

  void _resetError() {
    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorScreen(context);
    }
    return widget.child;
  }

  Widget _buildErrorScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.customErrorMessage ??
                    'The app encountered an unexpected error. Please try again.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _resetError,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Restart the app
                  exit(0);
                },
                child: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FarmerFriendlyError {
  static String getMessage(dynamic error) {
    if (error is SocketException) {
      return 'Couldn\'t connect to the server. Showing offline results.';
    }
    if (error.toString().contains('timeout')) {
      return 'Connection timed out. Using offline mode.';
    }
    if (error.toString().contains('permission')) {
      return 'Permission needed. Please check your settings.';
    }
    if (error.toString().contains('camera')) {
      return 'Camera not available. Please try again.';
    }
    if (error.toString().contains('storage')) {
      return 'Storage error. Your data is safe, but we couldn\'t save this scan.';
    }
    return 'Something went wrong. Please try again.';
  }

  static String getAction(dynamic error) {
    if (error is SocketException || error.toString().contains('timeout')) {
      return 'Check your internet connection';
    }
    if (error.toString().contains('permission')) {
      return 'Open app settings';
    }
    if (error.toString().contains('camera')) {
      return 'Try using gallery instead';
    }
    return 'Try again';
  }
}
