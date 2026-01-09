class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      statusCode: 200,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode, Map<String, dynamic>? errors}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    final success = json['success'] ?? false;
    final message = json['message'] as String?;
    final statusCode = json['status_code'] as int?;
    
    if (success && json['data'] != null && fromJsonT != null) {
      return ApiResponse.success(
        fromJsonT(json['data']),
        message: message,
      );
    }
    
    return ApiResponse.error(
      message ?? 'Unknown error',
      statusCode: statusCode,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}
