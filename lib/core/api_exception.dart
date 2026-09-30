import 'package:dio/dio.dart';

/// Error legible para mostrar al usuario.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;

  factory ApiException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is String) return ApiException(detail, statusCode: status);
      if (detail is List && detail.isNotEmpty) {
        // Errores de validación de FastAPI: [{loc, msg, ...}]
        final first = detail.first;
        final msg = first is Map ? (first['msg'] ?? 'Datos inválidos') : 'Datos inválidos';
        return ApiException('$msg', statusCode: status);
      }
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException('No se pudo conectar con el servidor');
    }
    return ApiException('Error inesperado${status != null ? ' ($status)' : ''}',
        statusCode: status);
  }
}
