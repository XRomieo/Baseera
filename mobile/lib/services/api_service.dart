// services/api_service.dart
// HTTP client for communicating with the FastAPI backend.
// Uses Dio for robust error handling and timeout configuration.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/analysis_result_model.dart';
import '../models/outcome_model.dart';

// Android emulator maps 10.0.2.2 to the host machine's localhost
// For physical device testing: replace with your machine's LAN IP (e.g. 192.168.1.x)
const String _baseUrl = 'http://10.0.2.2:8000';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 90), // Gemini can be slow
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging interceptor in debug mode
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (obj) => debugPrint('[ApiService] $obj'),
      ),
    );
  }

  /// Trigger analysis of all 5 data sources.
  /// Calls POST /api/analyze
  Future<AnalysisResultModel> runAnalysis({bool forceRefresh = false}) async {
    try {
      final response = await _dio.post(
        '/api/analyze',
        data: {
          'trigger': 'run analysis',
          'force_refresh': forceRefresh,
        },
      );

      return AnalysisResultModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleDioError(e, 'runAnalysis');
    }
  }

  /// Execute a specific action step.
  /// Calls POST /api/execute-step
  /// Returns the step result dict — check result['status'] for 'failed'|'completed'
  Future<Map<String, dynamic>> executeStep(int stepNumber) async {
    try {
      final response = await _dio.post(
        '/api/execute-step',
        data: {'step_number': stepNumber},
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e, 'executeStep($stepNumber)');
    }
  }

  /// Get the before/after outcome comparison.
  /// Calls GET /api/outcome
  Future<OutcomeModel> getOutcome() async {
    try {
      final response = await _dio.get('/api/outcome');
      return OutcomeModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleDioError(e, 'getOutcome');
    }
  }

  /// Check if the backend is reachable.
  Future<bool> checkHealth() async {
    try {
      await _dio.get(
        '/api/health',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  ApiException _handleDioError(DioException e, String operation) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ApiException(
        message: 'Connection timed out. Make sure the backend server is running on port 8000.',
        isNetworkError: true,
      );
    } else if (e.type == DioExceptionType.connectionError) {
      return const ApiException(
        message: 'Cannot connect to backend. Run: uvicorn main:app --reload in the backend/ folder.',
        isNetworkError: true,
      );
    } else if (e.response != null) {
      return ApiException(
        message: e.response?.data?['detail'] ?? 'Server error: ${e.response?.statusCode}',
        statusCode: e.response?.statusCode,
      );
    } else {
      return ApiException(
        message: 'Network error in $operation: ${e.message}',
        isNetworkError: true,
      );
    }
  }
}

class ApiException implements Exception {
  final String message;
  final bool isNetworkError;
  final int? statusCode;

  const ApiException({
    required this.message,
    this.isNetworkError = false,
    this.statusCode,
  });

  @override
  String toString() => 'ApiException: $message';
}
