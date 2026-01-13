import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:helpdesk_mobile/config/api_config.dart';
import 'package:helpdesk_mobile/data/models/api_response.dart';
import 'package:helpdesk_mobile/data/models/ticket_model.dart';
import 'package:helpdesk_mobile/data/models/category_model.dart';
import 'package:helpdesk_mobile/data/models/employee_model.dart';
import 'package:helpdesk_mobile/data/services/storage_service.dart';

class CustomerTicketRepository {
  Future<String?> _getToken() async {
    return await StorageService.getCustomerToken();
  }

  /// Get all categories
  Future<ApiResponse<List<CategoryModel>>> getCategories() async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.customerCategories}');
      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final categoriesData = responseData['data'] ?? responseData['categories'] ?? [];
        
        // Debug: Print raw API response
        print('\\n===== CATEGORIES API RESPONSE =====');
        print('Response data: ${jsonEncode(responseData)}');
        print('Categories count: ${(categoriesData as List).length}');
        
        final categories = categoriesData
            .map((e) {
              print('\\nCategory raw data: ${jsonEncode(e)}');
              final cat = CategoryModel.fromJson(e);
              print('Parsed - ID: ${cat.id}, Name: ${cat.name}');
              print('Parsed - hasSubCategories: ${cat.hasSubCategories}, hasProjects: ${cat.hasProjects}');
              return cat;
            })
            .toList();
        
        print('====================================\\n');
        
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
  Future<ApiResponse<CategoryExtrasModel>> getCategoryExtras(int categoryId) async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.customerCategoryExtras(categoryId)}',
      );
      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final extrasData = responseData['data'];
        
        print('\n===== CATEGORY EXTRAS API RESPONSE =====');
        print('Category ID: $categoryId');
        print('Extras data: ${jsonEncode(extrasData)}');
        print('========================================\n');
        
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

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.customerEmployees}');
      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final employeesData = responseData['data'] ?? responseData['employees'] ?? [];
        final employees = employeesData
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
      if (startDate != null && startDate.isNotEmpty) queryParams['start_date'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['end_date'] = endDate;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.customerTickets}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final ticketsData = responseData['data'] ?? responseData['tickets'] ?? [];
        
        // Debug: Print API response
        print('\n===== TICKETS API RESPONSE =====');
        print('Success: ${responseData['success']}');
        print('Tickets count: ${(ticketsData as List).length}');
        if ((ticketsData).isNotEmpty) {
          print('First ticket: ${jsonEncode(ticketsData[0])}');
        }
        print('================================\n');
        
        final tickets = ticketsData
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
        '${ApiConfig.baseUrl}${ApiConfig.customerTicketDetail(ticketId)}',
      );

      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final ticketData = responseData['data'] ?? responseData['ticket'];
        
        // Debug: Print detail API response
        print('\n===== TICKET DETAIL API RESPONSE =====');
        print('Success: ${responseData['success']}');
        print('Ticket ID: ${ticketData?['ticket_id']}');
        print('Has comments: ${ticketData?['comments'] != null}');
        if (ticketData?['comments'] != null) {
          print('Comments count: ${(ticketData!['comments'] as List).length}');
          if ((ticketData['comments'] as List).isNotEmpty) {
            print('First comment: ${jsonEncode(ticketData['comments'][0])}');
          }
        }
        print('======================================\n');
        
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

  /// Create new ticket
  Future<ApiResponse<TicketModel>> createTicket({
    required String subject,
    required int categoryId,
    required String message,
    required String requestToUserId,
    String? requestToOther,
    String? project,
    int? subCategory,
    String? envatoSupport,
    List<File>? files,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.customerTickets}');

      http.Response response;

      // Check if files need to be uploaded
      if (files != null && files.isNotEmpty) {
        // Multipart request
        final request = http.MultipartRequest('POST', url);
        request.headers.addAll(ApiConfig.multipartHeaders(token: token));
        
        // Add fields
        request.fields['subject'] = subject;
        request.fields['category_id'] = categoryId.toString();
        request.fields['message'] = message;
        request.fields['request_to_user_id'] = requestToUserId;
        
        if (requestToOther != null) request.fields['request_to_other'] = requestToOther;
        if (project != null) request.fields['project'] = project;
        if (subCategory != null) request.fields['subscategory'] = subCategory.toString();
        if (envatoSupport != null) request.fields['envato_support'] = envatoSupport;

        // Add files
        for (var file in files) {
          request.files.add(await http.MultipartFile.fromPath('files[]', file.path));
        }

        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // JSON request
        response = await http.post(
          url,
          headers: ApiConfig.headers(token: token),
          body: jsonEncode({
            'subject': subject,
            'category_id': categoryId,
            'message': message,
            'request_to_user_id': requestToUserId,
            if (requestToOther != null) 'request_to_other': requestToOther,
            if (project != null) 'project': project,
            if (subCategory != null) 'subscategory': subCategory,
            if (envatoSupport != null) 'envato_support': envatoSupport,
          }),
        );
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final ticketData = responseData['data'] ?? responseData['ticket'];
        
        if (ticketData != null) {
          final ticket = TicketModel.fromJson(ticketData);
          return ApiResponse.success(
            ticket,
            message: responseData['message'] ?? 'Ticket created successfully',
          );
        }
      }

      return ApiResponse.error(
        responseData['message'] ?? 'Failed to create ticket',
        statusCode: response.statusCode,
        errors: responseData['errors'] as Map<String, dynamic>?,
      );
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Reply to ticket
  Future<ApiResponse<TicketModel>> replyTicket({
    required String ticketId,
    required String comment,
    String? status,
    List<File>? files,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.customerTicketReply(ticketId)}',
      );

      http.Response response;

      // Check if files need to be uploaded
      if (files != null && files.isNotEmpty) {
        // Multipart request
        final request = http.MultipartRequest('POST', url);
        request.headers.addAll(ApiConfig.multipartHeaders(token: token));
        
        // Add fields
        request.fields['comment'] = comment;
        if (status != null) request.fields['status'] = status;

        // Add files
        for (var file in files) {
          request.files.add(await http.MultipartFile.fromPath('files[]', file.path));
        }

        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // JSON request
        response = await http.post(
          url,
          headers: ApiConfig.headers(token: token),
          body: jsonEncode({
            'comment': comment,
            if (status != null) 'status': status,
          }),
        );
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final ticketData = responseData['data'] ?? responseData['ticket'];
        
        if (ticketData != null) {
          final ticket = TicketModel.fromJson(ticketData);
          return ApiResponse.success(
            ticket,
            message: responseData['message'] ?? 'Reply sent successfully',
          );
        }
      }

      return ApiResponse.error(
        responseData['message'] ?? 'Failed to send reply',
        statusCode: response.statusCode,
        errors: responseData['errors'] as Map<String, dynamic>?,
      );
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Get ticket replies with attachments
  Future<ApiResponse<List<TicketReplyModel>>> getTicketReplies(String ticketId) async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.customerTicketReplies(ticketId)}',
      );

      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final repliesData = responseData['data'] ?? [];
        
        print('\n===== TICKET REPLIES API RESPONSE =====');
        print('Ticket ID: $ticketId');
        print('Replies count: ${(repliesData as List).length}');
        print('========================================\n');
        
        final replies = repliesData
            .map((e) => TicketReplyModel.fromJson(e))
            .toList();
        
        return ApiResponse.success(replies);
      }

      return ApiResponse.error(
        responseData['message'] ?? 'Failed to fetch replies',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Edit latest reply (only editable replies)
  Future<ApiResponse<TicketReplyModel>> editReply({
    required String ticketId,
    required int commentId,
    required String comment,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.customerEditReply(ticketId, commentId)}',
      );

      final response = await http.post(
        url,
        headers: ApiConfig.headers(token: token),
        body: jsonEncode({'comment': comment}),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final replyData = responseData['data'];
        
        if (replyData != null) {
          final reply = TicketReplyModel.fromJson(replyData);
          return ApiResponse.success(
            reply,
            message: responseData['message'] ?? 'Reply updated successfully',
          );
        }
      }

      return ApiResponse.error(
        responseData['message'] ?? 'Failed to edit reply',
        statusCode: response.statusCode,
        errors: responseData['errors'] as Map<String, dynamic>?,
      );
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }
}
