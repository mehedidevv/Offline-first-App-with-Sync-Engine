import 'package:dio/dio.dart';
import '../errors/app_exceptions.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://jsonplaceholder.typicode.com', // Default placeholder API, configurable
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token if available
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          final appException = _mapDioErrorToAppException(e);
          return handler.next(
            DioException(
              requestOptions: e.requestOptions,
              error: appException,
              message: appException.message,
              response: e.response,
              type: e.type,
            ),
          );
        },
      ),
    );
  }

  Dio get dio => _dio;

  AppException _mapDioErrorToAppException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'Connection timed out or network is unavailable.',
          code: 'NETWORK_TIMEOUT',
          originalError: error,
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return AuthenticationException(
            message: 'Authentication failed or token expired.',
            code: 'AUTH_ERROR',
            originalError: error,
          );
        } else if (statusCode == 429) {
          return NetworkException(
            message: 'Too many requests. Please try again later.',
            code: 'HTTP_429',
            originalError: error,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return NetworkException(
            message: 'Server error ($statusCode). Please try again later.',
            code: 'HTTP_5XX',
            originalError: error,
          );
        }
        return NetworkException(
          message: error.response?.statusMessage ?? 'Bad response from server.',
          code: 'BAD_RESPONSE_$statusCode',
          originalError: error,
        );
      case DioExceptionType.cancel:
        return NetworkException(
          message: 'Request was cancelled.',
          code: 'REQUEST_CANCELLED',
          originalError: error,
        );
      case DioExceptionType.unknown:
      default:
        return NetworkException(
          message: error.message ?? 'An unexpected network error occurred.',
          code: 'UNKNOWN_NETWORK_ERROR',
          originalError: error,
        );
    }
  }
}
