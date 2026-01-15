import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';
import 'package:helpdesk_mobile/data/models/available_status_model.dart';
import 'package:helpdesk_mobile/data/models/ticket_model.dart';
import 'package:helpdesk_mobile/data/repository/internal/internal_ticket_repository.dart';
import 'package:helpdesk_mobile/states/internal/internal_ticket_replies_provider.dart';
import 'package:helpdesk_mobile/ui/shared/widgets/attachment_viewer.dart';
import 'package:intl/intl.dart';

// Provider for ticket detail
final internalTicketDetailProvider =
    FutureProvider.family<TicketModel?, String>((ref, ticketId) async {
      final repository = InternalTicketRepository();
      final response = await repository.getTicketDetail(ticketId);

      if (response.success && response.data != null) {
        return response.data;
      }

      return null;
    });

// Provider for reply repository
final internalReplyTicketProvider = Provider(
  (ref) => InternalTicketRepository(),
);

// Provider for available statuses
final internalAvailableStatusesProvider =
    FutureProvider.family<AvailableStatusModel?, String>((ref, ticketId) async {
      final repository = InternalTicketRepository();
      final response = await repository.getAvailableStatuses(ticketId);

      if (response.success && response.data != null) {
        return response.data;
      }

      return null;
    });

class InternalTicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const InternalTicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<InternalTicketDetailScreen> createState() =>
      _InternalTicketDetailScreenState();
}

class _InternalTicketDetailScreenState
    extends ConsumerState<InternalTicketDetailScreen> {
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  List<File> _selectedFiles = [];
  bool _isReplying = false;
  String? _selectedStatus; // For status dropdown

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    if (_selectedFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 files allowed'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      final newFiles = result.paths
          .where((path) => path != null)
          .map((path) => File(path!))
          .toList();

      setState(() {
        final remainingSlots = 5 - _selectedFiles.length;
        _selectedFiles.addAll(newFiles.take(remainingSlots));
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isReplying = true);

    final repository = ref.read(internalReplyTicketProvider);

    final response = await repository.replyTicket(
      ticketId: widget.ticketId,
      comment: _replyController.text.trim(),
      status: _selectedStatus,
      files: _selectedFiles.isNotEmpty ? _selectedFiles : null,
    );

    setState(() => _isReplying = false);

    if (mounted) {
      if (response.success) {
        setState(() {
          _replyController.clear();
          _selectedFiles = [];
          _selectedStatus = null;
        });

        // Refresh ticket detail and replies to show new reply
        ref.invalidate(internalTicketDetailProvider(widget.ticketId));
        ref.invalidate(internalTicketRepliesProvider(widget.ticketId));
        ref.invalidate(internalAvailableStatusesProvider(widget.ticketId));

        // Scroll to bottom to show new reply
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply sent successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to send reply'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Color _getStatusColor(ticket) {
    switch (ticket.status.value.toLowerCase()) {
      case 'new':
        return AppColors.statusNew;
      case 'inprogress':
        return AppColors.statusInProgress;
      case 'solved':
        return AppColors.statusSolved;
      case 'closed':
        return AppColors.statusClosed;
      default:
        return AppColors.statusNew;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(
      internalTicketDetailProvider(widget.ticketId),
    );
    final repliesAsync = ref.watch(
      internalTicketRepliesProvider(widget.ticketId),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.ticketId)),
      body: ticketAsync.when(
        data: (ticket) {
          if (ticket == null) {
            return const Center(child: Text('Ticket not found'));
          }
          return _buildTicketDetail(ticket, repliesAsync);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 60, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(internalTicketDetailProvider(widget.ticketId));
                  ref.invalidate(
                    internalTicketRepliesProvider(widget.ticketId),
                  );
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketDetail(
    TicketModel ticket,
    AsyncValue<List<TicketReplyModel>> repliesAsync,
  ) {
    // Check if status is terminal (cannot reply)
    final isTerminalStatus = ['closed', 'cancelled', 'suspend']
        .contains(ticket.status.value.toLowerCase());

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ticket Info Card
                _buildTicketInfoCard(ticket),
                const SizedBox(height: 16),

                // Ticket Attachments
                if (ticket.attachments != null &&
                    ticket.attachments!.isNotEmpty)
                  _buildAttachmentsSection(ticket.attachments!),

                const SizedBox(height: 16),

                // Replies Section
                _buildRepliesSection(repliesAsync),

                // Terminal status notice
                if (isTerminalStatus) ...[
                  const SizedBox(height: 16),
                  _buildTerminalStatusNotice(ticket.status.displayName),
                ],
              ],
            ),
          ),
        ),

        // Reply Input (disabled if terminal status)
        if (!isTerminalStatus) _buildReplyInputWithStatus(),
      ],
    );
  }

  Widget _buildReplyInputWithStatus() {
    final availableStatusesAsync =
        ref.watch(internalAvailableStatusesProvider(widget.ticketId));

    return availableStatusesAsync.when(
      data: (availableStatuses) => _buildReplyInput(availableStatuses),
      loading: () => _buildReplyInput(null),
      error: (_, __) => _buildReplyInput(null),
    );
  }

  Widget _buildTicketInfoCard(TicketModel ticket) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(ticket).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getStatusColor(ticket)),
                ),
                child: Text(
                  ticket.status.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(ticket),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Subject
            Text(
              ticket.subject,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Html(
              data: ticket.message ?? '',
              style: {
                "body": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(15),
                  color: AppColors.textSecondary,
                  lineHeight: const LineHeight(1.5),
                ),
                "p": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                ),
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Metadata
            _buildInfoRow(
              Icons.category,
              'Category',
              ticket.categoryName ?? 'N/A',
            ),
            if (ticket.subCategoryName != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.category_outlined,
                'Sub Category',
                ticket.subCategoryName!,
              ),
            ],
            if (ticket.project != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.work, 'Project', ticket.project!),
            ],
            if (ticket.requestToOther != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.person, 'Request To', ticket.requestToOther!),
            ],
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time,
              'Created',
              DateFormat('dd MMM yyyy, HH:mm').format(ticket.createdAt),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.update,
              'Updated',
              ticket.updatedAt != null
                  ? DateFormat('dd MMM yyyy, HH:mm').format(ticket.updatedAt!)
                  : 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textHint),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection(List<AttachmentModel> attachments) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attachments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: attachments.map((attachment) {
                return AttachmentViewer(attachment: attachment, isSmall: true);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepliesSection(AsyncValue<List<TicketReplyModel>> repliesAsync) {
    return repliesAsync.when(
      data: (replies) {
        if (replies.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No replies yet',
                  style: TextStyle(color: AppColors.textHint),
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Replies',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...replies.map((reply) => _buildReplyCard(reply)),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error, color: AppColors.error),
              const SizedBox(height: 8),
              Text('Error loading replies: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyCard(TicketReplyModel reply) {
    // Check if this is an employee reply
    final isEmployee = reply.userRole.toLowerCase() == 'employee';

    return Card(
      color: isEmployee ? AppColors.background : AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reply Header
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isEmployee
                      ? AppColors.success
                      : AppColors.primary,
                  backgroundImage: reply.userImageUrl != null
                      ? CachedNetworkImageProvider(reply.userImageUrl!)
                      : null,
                  child: reply.userImageUrl == null
                      ? Icon(
                          isEmployee ? Icons.support_agent : Icons.person,
                          size: 18,
                          color: AppColors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reply.userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            DateFormat(
                              'dd MMM yyyy, HH:mm',
                            ).format(reply.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isEmployee
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reply.userRole,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isEmployee ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Reply Message
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Html(
                  data: reply.comment,
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(14),
                      color: AppColors.textSecondary,
                      lineHeight: const LineHeight(1.5),
                    ),
                    "p": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                    ),
                  },
                ),
                // Edited indicator
                if (reply.isEdited) ...[
                  const SizedBox(height: 2),
                  Text(
                    '\u2022 edited',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),

            // Reply Attachments
            if (reply.attachments != null && reply.attachments!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: reply.attachments!.map((attachment) {
                  return AttachmentViewer(
                    attachment: attachment,
                    isSmall: true,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalStatusNotice(String statusName) {
    final IconData icon;
    final Color color;
    final String message;

    switch (statusName.toLowerCase()) {
      case 'closed':
        icon = Icons.lock_outline;
        color = AppColors.statusClosed;
        message = 'This ticket has been closed. No further actions can be taken.';
        break;
      case 'cancelled':
        icon = Icons.cancel_outlined;
        color = AppColors.error;
        message = 'This ticket has been cancelled. No further actions can be taken.';
        break;
      case 'suspend':
        icon = Icons.block;
        color = AppColors.warning;
        message = 'This ticket is suspended. No replies or updates allowed.';
        break;
      default:
        icon = Icons.info_outline;
        color = AppColors.textHint;
        message = 'This ticket cannot be modified.';
    }

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ticket $statusName',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyInput(AvailableStatusModel? availableStatuses) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status Dropdown (show only if available options exist)
          if (availableStatuses != null && availableStatuses.hasOptions) ...[
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Update Status (Optional)',
                prefixIcon: const Icon(Icons.flag_outlined, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('No change'),
                ),
                ...availableStatuses.availableStatuses.map((option) {
                  return DropdownMenuItem(
                    value: option.value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            option.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (option.hasPermissionRequirement ||
                            option.hasRoleRequirement) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: AppColors.textHint,
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 8),
          ],

          // Selected Files
          if (_selectedFiles.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_selectedFiles.length, (index) {
                  final file = _selectedFiles[index];
                  final fileName = file.path.split('/').last;
                  return Chip(
                    label: Text(
                      fileName,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeFile(index),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Input Row
          Row(
            children: [
              // Attach button
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _selectedFiles.length < 5 ? _pickFiles : null,
                color: AppColors.primary,
              ),
              Expanded(
                child: TextField(
                  controller: _replyController,
                  decoration: InputDecoration(
                    hintText: 'Type your reply...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              _isReplying
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendReply,
                      color: AppColors.primary,
                      iconSize: 28,
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
