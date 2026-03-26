import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:helpdesk_mobile/config/api_config.dart';
import 'package:helpdesk_mobile/data/models/api_response.dart';
import 'package:helpdesk_mobile/data/models/available_status_model.dart';
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
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.internalTickets}',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Debug: Print raw response structure
      print('\n===== INTERNAL TICKETS API =====');
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
          ticketsData = rawData['data'] as List? ?? [];
        } else {
          ticketsData = responseData['tickets'] as List? ?? [];
        }

        print('Tickets count: ${ticketsData.length}');
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

  /// Get CSAT ticket list for internal CSAT Center.
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
      if (ticketStatus != null && ticketStatus.isNotEmpty) {
        queryParams['ticket_status'] = ticketStatus;
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.internalCsatTickets}',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

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

  /// Send CSAT reminder for one ticket id (database id, not ticket number).
  Future<ApiResponse<void>> sendCsatReminder(int ticketId) async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.internalCsatRemind(ticketId)}',
      );

      final response = await http.post(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(null, message: responseData['message']);
      }

      return ApiResponse.error(
        responseData['message'] ?? 'Failed to send CSAT reminder',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Send reminder to all pending CSAT tickets based on current filter.
  Future<ApiResponse<void>> sendCsatReminderAll({
    String? ticketStatus,
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final queryParams = <String, String>{};
      if (ticketStatus != null && ticketStatus.isNotEmpty) {
        queryParams['ticket_status'] = ticketStatus;
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.internalCsatRemindAll}',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.post(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(null, message: responseData['message']);
      }

      return ApiResponse.error(
        responseData['message'] ?? 'Failed to send CSAT reminders',
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

  /// Get available statuses for ticket (dynamic based on current status & permissions)
  Future<ApiResponse<AvailableStatusModel>> getAvailableStatuses(
      String ticketId) async {
    try {
      final token = await _getToken();
      if (token == null) return ApiResponse.error('No token found');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/mobile/internal/tickets/$ticketId/available-statuses',
      );

      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final data = responseData['data'];
        if (data != null) {
          final availableStatus = AvailableStatusModel.fromJson(data);
          return ApiResponse.success(availableStatus);
        }
      }

      return ApiResponse.error(
        responseData['message'] ?? 'Failed to fetch available statuses',
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
    String? envatoSupport,
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
        if (envatoSupport != null) body['envato_support'] = envatoSupport;

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

        if (requestToOther != null) {
          request.fields['request_to_other'] = requestToOther;
        }
        if (project != null) request.fields['project'] = project;
        if (subCategory != null) {
          request.fields['subscategory'] = subCategory.toString();
        }
        if (envatoSupport != null) {
          request.fields['envato_support'] = envatoSupport;
        }

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

  /// Reply to ticket.
  ///
  /// [slaPauseReasonCode] — required when [status] is `On-Hold`.
  /// [slaPauseReasonNote] — required when reason code is `other`.
  /// [resolutionTargetWorkingDays] — optional; only sent when the user has
  ///   `can_edit_resolution_target_working_days` permission.
  Future<ApiResponse<void>> replyTicket({
    required String ticketId,
    required String comment,
    String? status,
    String? slaPauseReasonCode,
    String? slaPauseReasonNote,
    int? resolutionTargetWorkingDays,
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
        final Map<String, dynamic> body = {'comment': comment};
        if (status != null) body['status'] = status;
        if (slaPauseReasonCode != null) {
          body['sla_pause_reason_code'] = slaPauseReasonCode;
        }
        if (slaPauseReasonNote != null) {
          body['sla_pause_reason_note'] = slaPauseReasonNote;
        }
        if (resolutionTargetWorkingDays != null) {
          body['resolution_target_working_days'] = resolutionTargetWorkingDays;
        }

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
        if (slaPauseReasonCode != null) {
          request.fields['sla_pause_reason_code'] = slaPauseReasonCode;
        }
        if (slaPauseReasonNote != null) {
          request.fields['sla_pause_reason_note'] = slaPauseReasonNote;
        }
        if (resolutionTargetWorkingDays != null) {
          request.fields['resolution_target_working_days'] =
              resolutionTargetWorkingDays.toString();
        }

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

        final replies = repliesData
            .map((e) => TicketReplyModel.fromJson(e as Map<String, dynamic>))
            .toList();

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
