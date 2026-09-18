import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class AppError {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? action;

  AppError({
    required this.title,
    required this.message,
    this.actionLabel,
    this.action,
  });

  factory AppError.network() => AppError(
    title: 'Connection Error',
    message: 'Failed to connect to server. Check your internet connection.',
  );

  factory AppError.timeout() => AppError(
    title: 'Request Timeout',
    message: 'Server is taking too long to respond. Please try again.',
  );

  factory AppError.notFound() => AppError(
    title: 'Not Found',
    message: 'The requested page or resource could not be found.',
  );

  factory AppError.serverError() => AppError(
    title: 'Server Error',
    message: 'Server encountered an error. Please try again later.',
  );

  factory AppError.unauthorized() => AppError(
    title: 'Unauthorized',
    message: 'Your session has expired. Please log in again.',
    actionLabel: 'Login',
  );

  factory AppError.generic(String message) => AppError(
    title: 'Error',
    message: message,
  );

  void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (action != null && actionLabel != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                action!();
              },
              child: Text(actionLabel!),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void showSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 5),
        action: action != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel!,
                onPressed: action!,
              )
            : null,
      ),
    );
  }
}

class ErrorHandler {
  static AppError handleException(Object error, StackTrace? stackTrace) {
    print('[ErrorHandler] Exception: $error');
    print('[ErrorHandler] Stack: $stackTrace');

    if (error is SocketException || error is ClientException) {
      return AppError.network();
    }

    if (error is TimeoutException) {
      return AppError.timeout();
    }

    if (error is FormatException) {
      return AppError.generic('Invalid data format received from server');
    }

    return AppError.generic(error.toString());
  }
}
