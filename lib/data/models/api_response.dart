class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? errors;
  final PaginationMeta? meta;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.errors,
    this.meta,
  });

  factory ApiResponse.success(T data, {String? message, PaginationMeta? meta}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      statusCode: 200,
      meta: meta,
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
