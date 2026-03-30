import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';
import 'package:helpdesk_mobile/data/models/ticket_model.dart';
import 'package:helpdesk_mobile/states/customer/customer_csat_provider.dart';
import 'package:helpdesk_mobile/ui/customer/csat_filter_screen.dart';
import 'package:helpdesk_mobile/ui/customer/ticket_detail_screen.dart';
import 'package:helpdesk_mobile/ui/shared/widgets/app_action_button.dart';
import 'package:intl/intl.dart';

class CustomerCsatScreen extends ConsumerStatefulWidget {
  const CustomerCsatScreen({super.key});

  @override
  ConsumerState<CustomerCsatScreen> createState() => _CustomerCsatScreenState();
}

class _CustomerCsatScreenState extends ConsumerState<CustomerCsatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerCsatProvider.notifier).fetchTickets(refresh: true);
    });

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final current = _scrollController.position.pixels;
      if (current >= (max - 220)) {
        ref.read(customerCsatProvider.notifier).loadMoreTickets();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(customerCsatProvider.notifier).fetchTickets(refresh: true);
  }

  Future<void> _openFilter(CustomerCsatState state) async {
    final result = await Navigator.push<Map<String, String?>>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerCsatFilterScreen(
          initialTicketStatus: state.ticketStatus,
          initialSearch: state.search,
          initialStartDate: state.startDate,
          initialEndDate: state.endDate,
        ),
      ),
    );

    if (result != null) {
      await ref.read(customerCsatProvider.notifier).fetchTickets(
            ticketStatus: result['ticketStatus'],
            search: result['search'],
            startDate: result['startDate'],
            endDate: result['endDate'],
            refresh: true,
          );
    }
  }

  Widget _buildStatusChip({
    required String value,
    required String label,
    required CustomerCsatState state,
  }) {
    final selected = state.csatStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        ref.read(customerCsatProvider.notifier).fetchTickets(
              csatStatus: value,
              refresh: true,
            );
      },
      selectedColor: AppColors.primary.withOpacity(0.16),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerCsatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CSAT Tickets'),
        actions: [
          IconButton(
            onPressed: () => _openFilter(state),
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusChip(
                  value: 'pending',
                  label: 'Pending',
                  state: state,
                ),
                _buildStatusChip(
                  value: 'rated',
                  label: 'Rated',
                  state: state,
                ),
                _buildStatusChip(
                  value: 'all',
                  label: 'All',
                  state: state,
                ),
              ],
            ),
          ),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.tickets.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 140),
                            Center(
                              child: Text(
                                'No CSAT tickets found',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 8,
                            bottom: MediaQuery.of(context).padding.bottom + 20,
                          ),
                          itemCount: state.tickets.length +
                              (state.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.tickets.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final ticket = state.tickets[index];
                            return _buildTicketItem(ticket);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketItem(TicketModel ticket) {
    final csat = ticket.csat;
    final isRated = csat?.isRated == true;
    final canSubmit = csat?.canSubmit == true;
    final hasRatedNote =
        isRated && (csat?.comment != null && csat!.comment!.trim().isNotEmpty);
    const ratedBadgeBg = Color(0xFFE8F5E9);
    const ratedBadgeText = Color(0xFF1B5E20);
    const pendingBadgeBg = Color(0xFFFFF4E5);
    const pendingBadgeText = Color(0xFF8A4B00);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.ticketId,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isRated ? ratedBadgeBg : pendingBadgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isRated ? 'Rated' : 'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isRated ? ratedBadgeText : pendingBadgeText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket.subject,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd MMM yyyy').format(ticket.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (isRated && csat?.rating != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFE65100),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${csat!.rating}/5',
                          style: const TextStyle(
                            color: Color(0xFF6D4C41),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (isRated) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD6E4FF)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.notes_rounded,
                        size: 16,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasRatedNote
                          ? csat.comment!.trim()
                            : 'No additional notes from customer.',
                        style: TextStyle(
                          color: hasRatedNote
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight:
                              hasRatedNote ? FontWeight.w500 : FontWeight.w400,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: AppActionButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerTicketDetailScreen(
                        ticketId: ticket.ticketId,
                      ),
                    ),
                  );
                  if (!mounted) return;
                  await ref.read(customerCsatProvider.notifier).fetchTickets(
                        refresh: true,
                      );
                },
                  variant: canSubmit
                    ? AppActionButtonVariant.filled
                    : AppActionButtonVariant.outlined,
                  icon: canSubmit
                    ? Icons.rate_review_rounded
                    : Icons.visibility_outlined,
                  label: canSubmit ? 'Fill CSAT' : 'View Ticket',
                  backgroundColor: canSubmit
                    ? AppColors.primary
                    : const Color(0xFFF3F7FF),
                  foregroundColor: canSubmit
                    ? AppColors.white
                    : const Color(0xFF1E3A8A),
                  borderColor: canSubmit
                    ? AppColors.primary
                    : const Color(0xFFBFD2FF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
