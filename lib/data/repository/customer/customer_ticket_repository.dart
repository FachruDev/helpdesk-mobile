import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:helpdesk_mobile/config/api_config.dart';
import 'package:helpdesk_mobile/data/models/api_response.dart';
import 'package:helpdesk_mobile/data/models/rating_model.dart';
import 'package:helpdesk_mobile/data/models/ticket_model.dart';
import 'package:helpdesk_mobile/data/models/category_model.dart';
import 'package:helpdesk_mobile/data/models/employee_model.dart';
import 'package:helpdesk_mobile/data/services/storage_service.dart';

class CustomerTicketRepository {
  // Callback for handling 401 errors
  Function()? onUnauthorized;

  Future<String?> _getToken() async {
    return await StorageService.getCustomerToken();
  }

  // Check if response is 401 and trigger logout
  void _checkUnauthorized(int statusCode) {
    if (statusCode == 401 && onUnauthorized != null) {
      onUnauthorized!();
    }
  }

  /// Get all categories
  Future<ApiResponse<List<CategoryModel>>> getCategories() async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.customerCategories}',
      );
      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final categoriesData =
            responseData['data'] ?? responseData['categories'] ?? [];

        // Debug: Print raw API response
        print('\\n===== CATEGORIES API RESPONSE =====');
        print('Response data: ${jsonEncode(responseData)}');
        print('Categories count: ${(categoriesData as List).length}');

        final categories = categoriesData.map((e) {
          print('\\nCategory raw data: ${jsonEncode(e)}');
          final cat = CategoryModel.fromJson(e);
          print('Parsed - ID: ${cat.id}, Name: ${cat.name}');
          print(
            'Parsed - hasSubCategories: ${cat.hasSubCategories}, hasProjects: ${cat.hasProjects}',
          );
          return cat;
        }).toList();

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
  Future<ApiResponse<CategoryExtrasModel>> getCategoryExtras(
    int categoryId,
  ) async {
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

  /// Get employees with optional subject category scope filter.
  Future<ApiResponse<List<EmployeeModel>>> getEmployees({
    String? subjectCategory,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('❌ [EMPLOYEES] No token found');
        return ApiResponse.error('No token found');
      }

      final queryParams = <String, String>{};
      if (subjectCategory != null && subjectCategory.isNotEmpty) {
        queryParams['subject_category'] = subjectCategory;
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.customerEmployees}',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      print('🌐 [EMPLOYEES] Calling: $url');

      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      print('📡 [EMPLOYEES] Status Code: ${response.statusCode}');
      print('📦 [EMPLOYEES] Response Body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final employeesData =
            responseData['data'] ?? responseData['employees'] ?? [];
        print('📊 [EMPLOYEES] Raw data type: ${employeesData.runtimeType}');
        print('📊 [EMPLOYEES] Data length: ${(employeesData as List).length}');

        final employees = (employeesData)
            .map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>))
            .toList();

        print('✅ [EMPLOYEES] Parsed ${employees.length} employees');
        if (employees.isNotEmpty) {
          print(
            '👤 [EMPLOYEES] First employee: ${employees.first.name} (ID: ${employees.first.id})',
          );
        }

        return ApiResponse.success(employees);
      }

      print('❌ [EMPLOYEES] Error: ${responseData['message']}');
      return ApiResponse.error(
        responseData['message'] ?? 'Failed to fetch employees',
        statusCode: response.statusCode,
      );
    } catch (e, stackTrace) {
      print('💥 [EMPLOYEES] Exception: $e');
      print('📚 [EMPLOYEES] Stack trace: $stackTrace');
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
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.customerTickets}',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      _checkUnauthorized(response.statusCode);

      // Debug: Print raw response structure
      print('\n===== CUSTOMER TICKETS API =====');
      print('Status: ${response.statusCode}');
      print('Response keys: ${responseData.keys.toList()}');
      final rawData = responseData['data'];
      print('data type: ${rawData.runtimeType}');

      if (response.statusCode == 200) {
        // Handle multiple response formats:
        // 1. data = [...tickets...]  (flat list)
        // 2. data = { data: [...tickets...], current_page: 1, ... }  (Laravel paginated)
        // 3. tickets = [...tickets...]  (alternative key)
        List ticketsData;
        if (rawData is List) {
          ticketsData = rawData;
        } else if (rawData is Map) {
          // Paginated response - actual items are in data.data
          ticketsData = rawData['data'] as List? ?? [];
        } else {
          ticketsData = responseData['tickets'] as List? ?? [];
        }

        print('Tickets count: ${ticketsData.length}');
        if (ticketsData.isNotEmpty) {
          print('First ticket: ${jsonEncode(ticketsData[0])}');
        }
        print('================================\n');

        final tickets = ticketsData
            .map((e) => TicketModel.fromJson(e as Map<String, dynamic>))
            .toList();

        // Parse pagination meta from top-level or nested paginated response
        PaginationMeta? meta;
        if (responseData['meta'] is Map) {
          meta = PaginationMeta.fromJson(
            responseData['meta'] as Map<String, dynamic>,
          );
        } else if (rawData is Map && rawData['meta'] is Map) {
          meta = PaginationMeta.fromJson(
            rawData['meta'] as Map<String, dynamic>,
          );
        }

        return ApiResponse.success(tickets, meta: meta);
      }

      return ApiResponse.error(
        responseData['message'] ?? 'Failed to fetch tickets',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Get CSAT ticket list for customer.
  Future<ApiResponse<List<TicketModel>>> getCsatTickets({
    String csatStatus = 'pending',
    String? ticketStatus,
    String? search,
    String? startDate,
    String? endDate,
    int perPage = 20,
    int page = 1,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final queryParams = <String, String>{
        'csat_status': csatStatus,
        'per_page': perPage.toString(),
        'page': page.toString(),
      };

      final isValidTicketStatus =
          ticketStatus == 'Closed' || ticketStatus == 'Solved';
      if (isValidTicketStatus) {
        queryParams['ticket_status'] = ticketStatus!;
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.customerCsatTickets}',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      _checkUnauthorized(response.statusCode);

      if (response.statusCode == 200) {
        final rawData = responseData['data'];
        List ticketsData;
        if (rawData is List) {
          ticketsData = rawData;
        } else if (rawData is Map) {
          ticketsData = rawData['data'] as List? ?? [];
        } else {
          ticketsData = responseData['tickets'] as List? ?? [];
        }

        final tickets = ticketsData
            .map((e) => TicketModel.fromJson(e as Map<String, dynamic>))
            .toList();

        PaginationMeta? meta;
        if (responseData['meta'] is Map) {
          meta = PaginationMeta.fromJson(
            responseData['meta'] as Map<String, dynamic>,
          );
        } else if (rawData is Map && rawData['meta'] is Map) {
          meta = PaginationMeta.fromJson(
            rawData['meta'] as Map<String, dynamic>,
          );
        }

        return ApiResponse.success(tickets, meta: meta);
      }

      return ApiResponse.error(
        responseData['message'] ?? 'Failed to fetch CSAT tickets',
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
    required String subjectCategory,
    required String message,
    required String requestToUserId,
    String? requestToOther,
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
        request.fields['subject_category'] = subjectCategory;
        request.fields['message'] = message;
        request.fields['description'] = message;
        request.fields['request_to_user_id'] = requestToUserId;
        request.fields['request_to'] = requestToUserId;

        if (requestToOther != null) {
          request.fields['request_to_other'] = requestToOther;
        }

        // Add files
        for (var file in files) {
          request.files.add(
            await http.MultipartFile.fromPath('files[]', file.path),
          );
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
            'subject_category': subjectCategory,
            'message': message,
            'description': message,
            'request_to_user_id': requestToUserId,
            'request_to': requestToUserId,
            if (requestToOther != null) 'request_to_other': requestToOther,
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

      String failureMessage = responseData['message'] ?? 'Failed to create ticket';
      final rawErrors = responseData['errors'];
      if (rawErrors is Map<String, dynamic> && rawErrors.isNotEmpty) {
        final details = <String>[];
        for (final entry in rawErrors.entries) {
          final value = entry.value;
          if (value is List && value.isNotEmpty) {
            details.add(value.first.toString());
          } else if (value != null) {
            details.add(value.toString());
          }
        }
        if (details.isNotEmpty) {
          failureMessage = details.join(', ');
        }
      }

      return ApiResponse.error(
        failureMessage,
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
          request.files.add(
            await http.MultipartFile.fromPath('files[]', file.path),
          );
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
  Future<ApiResponse<List<TicketReplyModel>>> getTicketReplies(
    String ticketId,
  ) async {
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
        final rawData = responseData['data'];

        // Handle both flat list and paginated (data.data) formats
        List repliesData;
        if (rawData is List) {
          repliesData = rawData;
        } else if (rawData is Map) {
          repliesData = rawData['data'] as List? ?? [];
        } else {
          repliesData = responseData['replies'] as List? ?? [];
        }

        print('\n===== TICKET REPLIES API RESPONSE =====');
        print('Ticket ID: $ticketId');
        print('data type: ${rawData.runtimeType}');
        print('Replies count: ${repliesData.length}');
        print('========================================\n');

        final replies = repliesData
            .map((e) => TicketReplyModel.fromJson(e as Map<String, dynamic>))
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

  /// Get CSAT rating form for a ticket (dynamic options from SLA point profile).
  Future<ApiResponse<RatingFormModel>> getRatingForm(String ticketId) async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.customerRatingForm(ticketId)}',
      );

      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final data = responseData['data'];
        if (data != null) {
          return ApiResponse.success(RatingFormModel.fromJson(data));
        }
      }

      return ApiResponse.error(
        responseData['message'] ?? 'Failed to load rating form',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Submit CSAT rating. Returns 409 if already rated.
  Future<ApiResponse<RatingSubmitResult>> submitRating({
    required String ticketId,
    required int rating,
    String? comment,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.customerRating(ticketId)}',
      );

      final Map<String, dynamic> body = {'rating': rating};
      if (comment != null && comment.isNotEmpty) body['comment'] = comment;

      final response = await http.post(
        url,
        headers: ApiConfig.headers(token: token),
        body: jsonEncode(body),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = responseData['data'];
        if (data != null) {
          return ApiResponse.success(
            RatingSubmitResult.fromJson(data),
            message: responseData['message'],
          );
        }
      }

      // 409 = already rated
      return ApiResponse.error(
        responseData['message'] ?? 'Failed to submit rating',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }
}
