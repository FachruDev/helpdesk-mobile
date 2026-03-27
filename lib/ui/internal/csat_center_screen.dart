import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';
import 'package:helpdesk_mobile/data/models/ticket_model.dart';
import 'package:helpdesk_mobile/states/internal/internal_csat_provider.dart';
import 'package:helpdesk_mobile/ui/internal/csat_filter_screen.dart';
import 'package:helpdesk_mobile/ui/internal/ticket_detail_screen.dart';
import 'package:intl/intl.dart';

class InternalCsatCenterScreen extends ConsumerStatefulWidget {
  const InternalCsatCenterScreen({super.key});

  @override
  ConsumerState<InternalCsatCenterScreen> createState() =>
      _InternalCsatCenterScreenState();
}

class _InternalCsatCenterScreenState
    extends ConsumerState<InternalCsatCenterScreen> {
  final ScrollController _scrollController = ScrollController();

  Future<bool> _showRemindAllConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Send Reminder All'),
          content: const Text(
            'Kirim notifikasi reminder ke semua ticket CSAT pending sesuai filter saat ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Kirim'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<void> _showSuccessDialog({
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text('Berhasil'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(internalCsatProvider.notifier).fetchTickets(refresh: true);
    });

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final current = _scrollController.position.pixels;
      if (current >= (max - 220)) {
        ref.read(internalCsatProvider.notifier).loadMoreTickets();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(internalCsatProvider.notifier).fetchTickets(refresh: true);
  }

  Future<void> _openFilter(InternalCsatState state) async {
    final result = await Navigator.push<Map<String, String?>>(
      context,
      MaterialPageRoute(
        builder: (_) => InternalCsatFilterScreen(
          initialTicketStatus: state.ticketStatus,
          initialSearch: state.search,
          initialStartDate: state.startDate,
          initialEndDate: state.endDate,
        ),
      ),
    );

    if (result != null) {
      await ref.read(internalCsatProvider.notifier).fetchTickets(
            ticketStatus: result['ticketStatus'],
            search: result['search'],
            startDate: result['startDate'],
            endDate: result['endDate'],
            refresh: true,
          );
    }
  }

  Future<void> _sendReminderAll(InternalCsatState state) async {
    final ok = await ref.read(internalCsatProvider.notifier).sendReminderAll();
    final latestState = ref.read(internalCsatProvider);
    if (!mounted) return;

    if (ok) {
      await _showSuccessDialog(
        title: 'Berhasil',
        message: 'Reminder berhasil dikirim ke semua ticket pending.',
      );
      await ref.read(internalCsatProvider.notifier).fetchTickets(refresh: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(latestState.errorMessage ?? 'Gagal kirim reminder.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _onTapRemindAll(InternalCsatState state) async {
    final confirmed = await _showRemindAllConfirmationDialog();
    if (!confirmed || !mounted) return;
    await _sendReminderAll(state);
  }

  Widget _buildStatusChip({
    required String value,
    required String label,
    required InternalCsatState state,
  }) {
    final selected = state.csatStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        ref.read(internalCsatProvider.notifier).fetchTickets(
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
    final state = ref.watch(internalCsatProvider);
    final canRemindAll = state.csatStatus != 'rated';

    return Scaffold(
      appBar: AppBar(
        title: const Text('CSAT Center'),
        actions: [
          IconButton(
            onPressed: () => _openFilter(state),
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
          ),
          if (canRemindAll)
            TextButton(
              onPressed: state.isSendingReminderAll
                  ? null
                  : () => _onTapRemindAll(state),
              child: state.isSendingReminderAll
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Text(
                      'Remind All',
                      style: TextStyle(color: AppColors.white),
                    ),
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
                            return _buildTicketItem(ticket, state);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketItem(TicketModel ticket, InternalCsatState state) {
    final csat = ticket.csat;
    final isRated = csat?.isRated == true;

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
                    color: isRated
                        ? AppColors.success.withOpacity(0.15)
                        : AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isRated ? 'Rated' : 'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isRated ? AppColors.success : AppColors.warning,
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
                  Icons.person_outline,
                  size: 14,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ticket.customerName ?? ticket.customerEmail ?? '-',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
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
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${csat!.rating}/5',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InternalTicketDetailScreen(
                            ticketId: ticket.ticketId,
                          ),
                        ),
                      );
                    },
                    child: const Text('View Ticket'),
                  ),
                ),
                if (!isRated) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: ticket.id == null
                          ? null
                          : () async {
                              final ok = await ref
                                  .read(internalCsatProvider.notifier)
                                  .sendReminder(ticket.id!);
                              final latestState =
                                  ref.read(internalCsatProvider);
                              if (!mounted) return;
                              if (ok) {
                                await _showSuccessDialog(
                                  title: 'Berhasil',
                                  message:
                                      'Reminder berhasil dikirim untuk ${ticket.ticketId}.',
                                );
                                await ref
                                    .read(internalCsatProvider.notifier)
                                    .fetchTickets(refresh: true);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      latestState.errorMessage ??
                                          'Failed to send reminder',
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            },
                      child: const Text('Remind'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
