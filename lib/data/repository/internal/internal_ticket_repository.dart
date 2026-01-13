import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:helpdesk_mobile/config/api_config.dart';
import 'package:helpdesk_mobile/data/models/api_response.dart';
import 'package:helpdesk_mobile/data/models/ticket_model.dart';
import 'package:helpdesk_mobile/data/models/category_model.dart';
import 'package:helpdesk_mobile/data/models/employee_model.dart';
import 'package:helpdesk_mobile/data/services/storage_service.dart';

class InternalTicketRepository {
  Future<String?> _getToken() async {
    return await StorageService.getInternalToken();
  }

  /// Get all categories
  Future<ApiResponse<List<CategoryModel>>> getCategories() async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.internalCategories}',
      );
      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final categoriesData =
            responseData['data'] ?? responseData['categories'] ?? [];
        final categories = (categoriesData as List)
            .map((e) => CategoryModel.fromJson(e))
            .toList();

        return ApiResponse.success(categories);
      }

      return ApiResponse.error(
        responseData['message'] ?? 'Failed to fetch categories',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Get category extras (subcategories, projects, envato_required)
  Future<ApiResponse<CategoryExtrasModel>> getCategoryExtras(
    int categoryId,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.internalCategoryExtras(categoryId)}',
      );
      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final extrasData = responseData['data'];

        if (extrasData != null) {
          final extras = CategoryExtrasModel.fromJson(extrasData);
          return ApiResponse.success(extras);
        }
      }

      return ApiResponse.error(
        responseData['message'] ?? 'Failed to fetch category extras',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Get all employees
  Future<ApiResponse<List<EmployeeModel>>> getEmployees() async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.internalEmployees}',
      );
      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final employeesData =
            responseData['data'] ?? responseData['employees'] ?? [];
        final employees = (employeesData as List)
            .map((e) => EmployeeModel.fromJson(e))
            .toList();

        return ApiResponse.success(employees);
      }

      return ApiResponse.error(
        responseData['message'] ?? 'Failed to fetch employees',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Get ticket list with filters
  Future<ApiResponse<List<TicketModel>>> getTickets({
    String? status,
    String? startDate,
    String? endDate,
    String? search,
    int perPage = 20,
    int page = 1,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      // Build query parameters
      final queryParams = <String, String>{
        'per_page': perPage.toString(),
        'page': page.toString(),
      };

      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (startDate != null && startDate.isNotEmpty)
        queryParams['start_date'] = startDate;
      if (endDate != null && endDate.isNotEmpty)
        queryParams['end_date'] = endDate;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.internalTickets}',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final ticketsData =
            responseData['data'] ?? responseData['tickets'] ?? [];

        final tickets = (ticketsData as List)
            .map((e) => TicketModel.fromJson(e))
            .toList();

        return ApiResponse.success(tickets);
      }

      return ApiResponse.error(
        responseData['message'] ?? 'Failed to fetch tickets',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Get ticket detail
  Future<ApiResponse<TicketModel>> getTicketDetail(String ticketId) async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.internalTicketDetail(ticketId)}',
      );

      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final ticketData = responseData['data'] ?? responseData['ticket'];

        if (ticketData != null) {
          final ticket = TicketModel.fromJson(ticketData);
          return ApiResponse.success(ticket);
        }
      }

      return ApiResponse.error(
        responseData['message'] ?? 'Failed to fetch ticket detail',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Create new ticket (internal - requires email field)
  Future<ApiResponse<TicketModel>> createTicket({
    required String email,
    required String subject,
    required int categoryId,
    required String message,
    required String requestToUserId,
    String? requestToOther,
    String? project,
    int? subCategory,
    List<File>? files,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.internalTickets}');

      // Decide between JSON or multipart
      if (files == null || files.isEmpty) {
        // JSON request
        final body = {
          'email': email,
          'subject': subject,
          'category_id': categoryId,
          'message': message,
          'request_to_user_id': requestToUserId,
        };

        if (requestToOther != null) body['request_to_other'] = requestToOther;
        if (project != null) body['project'] = project;
        if (subCategory != null) body['subscategory'] = subCategory;

        final response = await http.post(
          url,
          headers: ApiConfig.headers(token: token),
          body: jsonEncode(body),
        );

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final ticketData = responseData['data'] ?? responseData['ticket'];
          if (ticketData != null) {
            return ApiResponse.success(TicketModel.fromJson(ticketData));
          }
          throw Exception(
            responseData['message'] ?? 'Ticket created but no data returned',
          );
        }

        return ApiResponse.error(
          responseData['message'] ?? 'Failed to create ticket',
          statusCode: response.statusCode,
        );
      } else {
        // Multipart request
        final request = http.MultipartRequest('POST', url);
        request.headers.addAll(ApiConfig.headers(token: token));
        request.headers.remove(
          'Content-Type',
        ); // Let http handle multipart boundary

        request.fields['email'] = email;
        request.fields['subject'] = subject;
        request.fields['category_id'] = categoryId.toString();
        request.fields['message'] = message;
        request.fields['request_to_user_id'] = requestToUserId;

        if (requestToOther != null)
          request.fields['request_to_other'] = requestToOther;
        if (project != null) request.fields['project'] = project;
        if (subCategory != null)
          request.fields['subscategory'] = subCategory.toString();

        // Add files
        for (var file in files) {
          request.files.add(
            await http.MultipartFile.fromPath('files[]', file.path),
          );
        }

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final ticketData = responseData['data'] ?? responseData['ticket'];
          if (ticketData != null) {
            return ApiResponse.success(TicketModel.fromJson(ticketData));
          }
          throw Exception(
            responseData['message'] ?? 'Ticket created but no data returned',
          );
        }

        return ApiResponse.error(
          responseData['message'] ?? 'Failed to create ticket',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Reply to ticket
  Future<ApiResponse<void>> replyTicket({
    required String ticketId,
    required String comment,
    String? status,
    List<File>? files,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.internalTicketReply(ticketId)}',
      );

      // Decide between JSON or multipart
      if (files == null || files.isEmpty) {
        // JSON request
        final body = {'comment': comment};
        if (status != null) body['status'] = status;

        final response = await http.post(
          url,
          headers: ApiConfig.headers(token: token),
          body: jsonEncode(body),
        );

        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return ApiResponse.success(null, message: responseData['message']);
        }

        return ApiResponse.error(
          responseData['message'] ?? 'Failed to reply ticket',
          statusCode: response.statusCode,
        );
      } else {
        // Multipart request
        final request = http.MultipartRequest('POST', url);
        request.headers.addAll(ApiConfig.headers(token: token));
        request.headers.remove('Content-Type');

        request.fields['comment'] = comment;
        if (status != null) request.fields['status'] = status;

        // Add files
        for (var file in files) {
          request.files.add(
            await http.MultipartFile.fromPath('files[]', file.path),
          );
        }

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return ApiResponse.success(null, message: responseData['message']);
        }

        return ApiResponse.error(
          responseData['message'] ?? 'Failed to reply ticket',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Get ticket replies
  Future<ApiResponse<List<TicketReplyModel>>> getTicketReplies(
    String ticketId,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.internalTicketReplies(ticketId)}',
      );

      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final repliesData = responseData['data'] ?? [];

        final replies = repliesData
            .map((e) => TicketReplyModel.fromJson(e))
            .toList()
            .cast<TicketReplyModel>();

        return ApiResponse.success(replies);
      }

      return ApiResponse.error(
        responseData['message'] ?? 'Failed to fetch ticket replies',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }
}
