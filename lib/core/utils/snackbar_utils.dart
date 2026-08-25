import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../network/dio_client.dart';

class SnackbarUtils {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void handleApiError(BuildContext context, dynamic error) {
    String message = 'An unexpected error occurred.';
    
    if (error is DioException) {
      if (error.error is ApiException) {
        message = (error.error as ApiException).message;
      } else {
        message = error.message ?? message;
      }
    } else {
      message = error.toString();
    }
    
    showError(context, message);
  }
}
