import 'package:dio/dio.dart';
import '../network/dio_client.dart';

class ErrorHandler {
  /// Extracts a clean, user-friendly error message from an exception.
  /// If the exception is a DioException wrapping an ApiException (our custom interceptor logic),
  /// it returns the clean message. Otherwise, it returns a generic fallback.
  static String getUserMessage(Object e) {
    if (e is DioException) {
      if (e.error is ApiException) {
        return (e.error as ApiException).message;
      }
      
      // Fallback for DioExceptions that somehow bypassed the interceptor's ApiException wrapping
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout || 
          e.type == DioExceptionType.sendTimeout) {
        return 'Connection timed out. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        return 'No internet connection available.';
      } else if (e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map && responseData['message'] != null) {
          return responseData['message'].toString();
        }
      }
    }
    
    // For non-Dio errors or if everything else fails
    return 'An unexpected error occurred. Please try again.';
  }
}
