import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/env_config.dart';
import '../core/constants/app_constants.dart';

/// Base API service for handling HTTP requests
class ApiService {
  late final Dio _dio;
  late final SupabaseClient _supabase;
  
  static ApiService? _instance;
  
  factory ApiService() {
    _instance ??= ApiService._internal();
    return _instance!;
  }
  
  ApiService._internal() {
    _initializeDio();
    _initializeSupabase();
  }
  
  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: AppConstants.defaultTimeout,
        receiveTimeout: AppConstants.defaultTimeout,
        sendTimeout: AppConstants.defaultTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    // Add interceptors
    _dio.interceptors.add(LogInterceptor(
      requestBody: EnvConfig.logRequests,
      responseBody: EnvConfig.logResponses,
    ));
    
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available
          final token = await _getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle token refresh on 401
          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the request
              final options = error.requestOptions;
              final token = await _getAuthToken();
              options.headers['Authorization'] = 'Bearer $token';
              
              try {
                final response = await _dio.fetch(options);
                handler.resolve(response);
              } catch (e) {
                handler.reject(error);
              }
            } else {
              handler.reject(error);
            }
          } else {
            handler.reject(error);
          }
        },
      ),
    );
  }
  
  void _initializeSupabase() {
    _supabase = Supabase.instance.client;
  }
  
  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Upload file
  Future<Response<T>> uploadFile<T>(
    String path,
    String filePath, {
    String? filename,
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...?data,
        'file': await MultipartFile.fromFile(filePath, filename: filename),
      });
      
      return await _dio.post<T>(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Supabase query builder
  SupabaseQueryBuilder from(String table) {
    return _supabase.from(table);
  }
  
  /// Supabase storage
  SupabaseStorageClient get storage => _supabase.storage;
  
  /// Supabase auth
  SupabaseAuth get auth => _supabase.auth;
  
  /// Supabase realtime
  RealtimeClient get realtime => _supabase.realtime;
  
  /// Get current auth token
  Future<String?> _getAuthToken() async {
    final session = _supabase.auth.currentSession;
    return session?.accessToken;
  }
  
  /// Refresh auth token
  Future<bool> _refreshToken() async {
    try {
      await _supabase.auth.refreshSession();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Handle Dio errors
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return TimeoutException('Request timed out');
        
      case DioExceptionType.connectionError:
        return NetworkException('Network connection error');
        
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? error.message;
        
        switch (statusCode) {
          case 400:
            return BadRequestException(message);
          case 401:
            return UnauthorizedException(message);
          case 403:
            return ForbiddenException(message);
          case 404:
            return NotFoundException(message);
          case 500:
            return ServerException(message);
          default:
            return ApiException(message, statusCode);
        }
        
      case DioExceptionType.cancel:
        return RequestCancelledException('Request was cancelled');
        
      default:
        return ApiException(error.message ?? 'Unknown error occurred');
    }
  }
}

/// Custom exceptions
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, [this.statusCode]);
  
  @override
  String toString() => 'ApiException: $message';
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class TimeoutException extends ApiException {
  TimeoutException(String message) : super(message);
}

class BadRequestException extends ApiException {
  BadRequestException(String message) : super(message, 400);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message, 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException(String message) : super(message, 403);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message, 404);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message, 500);
}

class RequestCancelledException extends ApiException {
  RequestCancelledException(String message) : super(message);
}