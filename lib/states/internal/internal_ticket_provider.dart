// Placeholder for Internal Ticket Provider
// This will be implemented later for internal/employee users

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/data/models/ticket_model.dart';
import 'package:helpdesk_mobile/data/repository/internal/internal_ticket_repository.dart';

// Repository Provider
final internalTicketRepositoryProvider = Provider<InternalTicketRepository>((ref) {
  return InternalTicketRepository();
});

// Ticket List State
class InternalTicketState {
  final List<TicketModel> tickets;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final bool hasMore;
  final int currentPage;

  InternalTicketState({
    this.tickets = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.hasMore = true,
    this.currentPage = 1,
  });

  InternalTicketState copyWith({
    List<TicketModel>? tickets,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool? hasMore,
    int? currentPage,
  }) {
    return InternalTicketState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Ticket Notifier
class InternalTicketNotifier extends Notifier<InternalTicketState> {

  @override
  InternalTicketState build() {
    return InternalTicketState();
  }

  // TODO: Implement internal ticket methods
}

// Provider
final internalTicketProvider = NotifierProvider<InternalTicketNotifier, InternalTicketState>(() {
  return InternalTicketNotifier();
});
