// Placeholder for Internal Ticket Repository
// This will be implemented later for internal/employee users

import 'dart:io';
import 'package:helpdesk_mobile/data/models/api_response.dart';
import 'package:helpdesk_mobile/data/models/ticket_model.dart';
import 'package:helpdesk_mobile/data/models/category_model.dart';
import 'package:helpdesk_mobile/data/models/employee_model.dart';

class InternalTicketRepository {
  // TODO: Implement internal ticket repository

  Future<ApiResponse<List<CategoryModel>>> getCategories() async {
    throw UnimplementedError('Internal getCategories not implemented yet');
  }

  Future<ApiResponse<List<EmployeeModel>>> getEmployees() async {
    throw UnimplementedError('Internal getEmployees not implemented yet');
  }

  Future<ApiResponse<List<TicketModel>>> getTickets({
    String? status,
    String? startDate,
    String? endDate,
    String? search,
    int perPage = 20,
    int page = 1,
  }) async {
    throw UnimplementedError('Internal getTickets not implemented yet');
  }

  Future<ApiResponse<TicketModel>> getTicketDetail(String ticketId) async {
    throw UnimplementedError('Internal getTicketDetail not implemented yet');
  }

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
    throw UnimplementedError('Internal createTicket not implemented yet');
  }

  Future<ApiResponse<TicketModel>> replyTicket({
    required String ticketId,
    required String comment,
    String? status,
    List<File>? files,
  }) async {
    throw UnimplementedError('Internal replyTicket not implemented yet');
  }
}
