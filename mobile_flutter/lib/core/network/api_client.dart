import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/preferences_service.dart';
import 'api_exceptions.dart';

class ApiClient {
  final Dio dio;
  final PreferencesService preferencesService;

  ApiClient({
    required this.preferencesService,
    Dio? customDio,
  }) : dio = customDio ?? Dio() {
    _initDio();
  }

  void _initDio() {
    final customUrl = preferencesService.getApiBaseUrl();
    final baseUrl = (customUrl != null && customUrl.trim().isNotEmpty)
        ? customUrl.trim()
        : AppConfig.defaultBaseUrl;

    dio.options = BaseOptions(
      baseUrl: baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Dynamically check if custom URL changed
          final activeCustom = preferencesService.getApiBaseUrl();
          if (activeCustom != null && activeCustom.trim().isNotEmpty) {
            final formatted = activeCustom.trim().endsWith('/')
                ? activeCustom.trim().substring(0, activeCustom.trim().length - 1)
                : activeCustom.trim();
            options.baseUrl = formatted;
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await dio.get(endpoint, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<dynamic> post(String endpoint, {dynamic data}) async {
    try {
      final response = await dio.post(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  ApiException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkException(
        'Unable to reach TransitGo server at ${dio.options.baseUrl}. Please ensure the Spring Boot backend is running and reachable from your device.',
      );
    }

    final status = e.response?.statusCode;
    if (status == 404) {
      return NotFoundException('The requested resource was not found on the server.');
    }
    if (status != null && status >= 500) {
      return ServerException('TransitGo server encountered an internal error ($status).', statusCode: status);
    }

    final serverMsg = e.response?.data is Map ? e.response?.data['error'] : null;
    return ApiException(serverMsg?.toString() ?? e.message ?? 'An unexpected network error occurred.', statusCode: status);
  }
}
