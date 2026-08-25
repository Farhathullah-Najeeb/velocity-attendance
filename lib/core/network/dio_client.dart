import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../utils/secure_storage.dart';

void Function()? onUnauthorizedCallback;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class CustomLogInterceptor extends Interceptor {
  final Map<RequestOptions, DateTime> _requestTimes = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _requestTimes[options] = DateTime.now();
    // print('\n======================================================');
    // print('→ ${options.method.toUpperCase()} ${options.uri}');
    
    final headers = Map<String, dynamic>.from(options.headers);
    if (headers.containsKey('Authorization')) {
      final token = headers['Authorization'].toString();
      if (token.startsWith('Bearer ') && token.length > 25) {
        headers['Authorization'] = 'Bearer ${token.substring(7, 15)}...${token.substring(token.length - 5)}';
      }
    }
    // print('Headers: ${_prettyJson(headers)}');
    
    if (options.data != null) {
      // print('Body: ${_prettyJson(options.data)}');
    }
    // print('======================================================\n');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = _requestTimes.remove(response.requestOptions);
    final duration = startTime != null ? DateTime.now().difference(startTime) : null;
    final durationStr = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    debugPrint('DIO [${response.statusCode}] ${response.requestOptions.uri}$durationStr');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startTime = _requestTimes.remove(err.requestOptions);
    final duration = startTime != null ? DateTime.now().difference(startTime) : null;
    final durationStr = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    debugPrint('DIO ERROR [${err.response?.statusCode ?? err.type.name}] ${err.requestOptions.uri}$durationStr: ${err.message}');
    super.onError(err, handler);
  }
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (config, handler) async {
        final token = await SecureStorage.getToken();
        if (token != null) {
          config.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(config);
      },
      onError: (DioException e, handler) async {
        String userFriendlyMessage = 'An unexpected error occurred. Please try again.';
        
        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.receiveTimeout || 
            e.type == DioExceptionType.sendTimeout) {
          userFriendlyMessage = 'Connection timed out. Please check your internet connection.';
        } else if (e.type == DioExceptionType.connectionError) {
          userFriendlyMessage = 'No internet connection available.';
        } else if (e.response != null) {
          final statusCode = e.response?.statusCode;
          final responseData = e.response?.data;
          
          switch (statusCode) {
            case 400:
              // Try to extract specific validation message from API response
              if (responseData is Map && responseData['message'] != null) {
                userFriendlyMessage = responseData['message'].toString();
              } else {
                userFriendlyMessage = 'Invalid request. Please check your inputs.';
              }
              break;
            case 401:
              if (responseData is Map && responseData['message'] != null) {
                userFriendlyMessage = responseData['message'].toString();
              } else {
                userFriendlyMessage = 'Your session has expired. Please log in again.';
              }
              // Trigger auto-logout via callback to prevent import cycles
              if (onUnauthorizedCallback != null) onUnauthorizedCallback!();
              break;
            case 403:
              if (responseData is Map && responseData['message'] != null) {
                userFriendlyMessage = responseData['message'].toString();
              } else {
                userFriendlyMessage = 'You don\'t have permission for this action.';
              }
              break;
            case 404:
              userFriendlyMessage = 'This item could not be found — it may have been removed.';
              break;
            case 429:
              userFriendlyMessage = 'Too many requests. Please wait a moment before trying again.';
              break;
            case 500:
            case 502:
            case 503:
            case 504:
              userFriendlyMessage = 'Something went wrong on our end. Please try again.';
              break;
          }
        }

        // We wrap the original error in our ApiException with the user-friendly message
        final apiException = ApiException(userFriendlyMessage, e.response?.statusCode);
        
        // Pass it forward. Services should catch ApiException or general Exception and just show its message.
        return handler.reject(
          DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: apiException,
          ),
        );
      },
    ),
  );

  // Add the custom logger only in debug mode
  if (kDebugMode) {
    dio.interceptors.add(CustomLogInterceptor());
  }

  return dio;
});
