import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/data/models/ticket_model.dart';
import 'package:helpdesk_mobile/data/repository/customer/customer_ticket_repository.dart';

/// Provider for ticket replies (separate from ticket detail)
final customerTicketRepliesProvider = FutureProvider.family<List<TicketReplyModel>, String>((ref, ticketId) async {
  final repository = CustomerTicketRepository();
  final response = await repository.getTicketReplies(ticketId);
  
  if (response.success && response.data != null) {
    return response.data!;
  }
  
  throw Exception(response.message ?? 'Failed to load replies');
});
