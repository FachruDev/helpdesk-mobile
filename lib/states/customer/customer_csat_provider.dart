import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/data/models/ticket_model.dart';
import 'package:helpdesk_mobile/data/repository/customer/customer_ticket_repository.dart';
import 'package:helpdesk_mobile/states/customer/customer_ticket_provider.dart';

class CustomerCsatState {
  final List<TicketModel> tickets;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final bool hasMore;
  final int currentPage;
  final int lastPage;
  final String csatStatus;
  final String? ticketStatus;
  final String? search;
  final String? startDate;
  final String? endDate;

  CustomerCsatState({
    this.tickets = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.hasMore = true,
    this.currentPage = 1,
    this.lastPage = 1,
    this.csatStatus = 'pending',
    this.ticketStatus,
    this.search,
    this.startDate,
    this.endDate,
  });

  CustomerCsatState copyWith({
    List<TicketModel>? tickets,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool? hasMore,
    int? currentPage,
    int? lastPage,
    String? csatStatus,
    String? ticketStatus,
    String? search,
    String? startDate,
    String? endDate,
  }) {
    return CustomerCsatState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      csatStatus: csatStatus ?? this.csatStatus,
      ticketStatus: ticketStatus ?? this.ticketStatus,
      search: search ?? this.search,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class CustomerCsatNotifier extends Notifier<CustomerCsatState> {
  CustomerTicketRepository get _repository =>
      ref.read(customerTicketRepositoryProvider);

  @override
  CustomerCsatState build() {
    return CustomerCsatState();
  }

  Future<void> fetchTickets({
    String? csatStatus,
    String? ticketStatus,
    String? search,
    String? startDate,
    String? endDate,
    bool refresh = false,
  }) async {
    final nextCsatStatus = csatStatus ?? state.csatStatus;
    final nextTicketStatus = ticketStatus ?? state.ticketStatus;
    final nextSearch = search ?? state.search;
    final nextStartDate = startDate ?? state.startDate;
    final nextEndDate = endDate ?? state.endDate;

    if (refresh) {
      state = CustomerCsatState(
        isLoading: true,
        csatStatus: nextCsatStatus,
        ticketStatus: nextTicketStatus,
        search: nextSearch,
        startDate: nextStartDate,
        endDate: nextEndDate,
      );
    } else {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        csatStatus: nextCsatStatus,
        ticketStatus: nextTicketStatus,
        search: nextSearch,
        startDate: nextStartDate,
        endDate: nextEndDate,
      );
    }

    try {
      final response = await _repository.getCsatTickets(
        csatStatus: nextCsatStatus,
        ticketStatus: nextTicketStatus,
        search: nextSearch,
        startDate: nextStartDate,
        endDate: nextEndDate,
        page: 1,
        perPage: 20,
      );

      if (response.success && response.data != null) {
        final lastPage = response.meta?.lastPage ?? 1;
        state = state.copyWith(
          isLoading: false,
          tickets: response.data!,
          currentPage: 1,
          lastPage: lastPage,
          hasMore: 1 < lastPage,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message ?? 'Failed to fetch CSAT tickets',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadMoreTickets() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final response = await _repository.getCsatTickets(
        csatStatus: state.csatStatus,
        ticketStatus: state.ticketStatus,
        search: state.search,
        startDate: state.startDate,
        endDate: state.endDate,
        page: nextPage,
        perPage: 20,
      );

      if (response.success && response.data != null) {
        final lastPage = response.meta?.lastPage ?? state.lastPage;
        state = state.copyWith(
          isLoadingMore: false,
          tickets: [...state.tickets, ...response.data!],
          currentPage: nextPage,
          lastPage: lastPage,
          hasMore: nextPage < lastPage,
        );
      } else {
        state = state.copyWith(isLoadingMore: false);
      }
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final customerCsatProvider =
    NotifierProvider<CustomerCsatNotifier, CustomerCsatState>(() {
  return CustomerCsatNotifier();
});
