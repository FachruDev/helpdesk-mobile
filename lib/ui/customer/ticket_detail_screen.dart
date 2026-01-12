import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';
import 'package:helpdesk_mobile/data/models/ticket_model.dart';
import 'package:helpdesk_mobile/states/customer/customer_ticket_provider.dart';
import 'package:helpdesk_mobile/states/customer/customer_ticket_replies_provider.dart';
import 'package:helpdesk_mobile/ui/shared/widgets/attachment_viewer.dart';
import 'package:intl/intl.dart';

class CustomerTicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const CustomerTicketDetailScreen({
    super.key,
    required this.ticketId,
  });

  @override
  ConsumerState<CustomerTicketDetailScreen> createState() =>
      _CustomerTicketDetailScreenState();
}

class _CustomerTicketDetailScreenState
    extends ConsumerState<CustomerTicketDetailScreen> {
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  List<File> _selectedFiles = [];
  bool _isReplying = false;
  String? _selectedStatus; // For status dropdown
  bool _isEditMode = false;
  TicketReplyModel? _editingReply;

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

    final repository = ref.read(customerReplyTicketProvider);
    
    // Handle edit mode vs create mode
    final response = _isEditMode && _editingReply != null
        ? await repository.editReply(
            ticketId: widget.ticketId,
            commentId: _editingReply!.id,
            comment: _replyController.text.trim(),
          )
        : await repository.replyTicket(
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
          _isEditMode = false;
          _editingReply = null;
        });
        
        // Refresh ticket detail and replies to show new reply
        ref.invalidate(customerTicketDetailProvider(widget.ticketId));
        ref.invalidate(customerTicketRepliesProvider(widget.ticketId));
        
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
          SnackBar(
            content: Text(_isEditMode ? 'Reply updated successfully' : 'Reply sent successfully'),
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

  void _startEditReply(TicketReplyModel reply) {
    setState(() {
      _isEditMode = true;
      _editingReply = reply;
      _replyController.text = reply.comment;
      _selectedFiles = []; // Can't edit attachments
      _selectedStatus = null;
    });
    
    // Scroll to bottom to show input
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditMode = false;
      _editingReply = null;
      _replyController.clear();
      _selectedFiles = [];
      _selectedStatus = null;
    });
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
    final ticketAsync = ref.watch(customerTicketDetailProvider(widget.ticketId));
    final repliesAsync = ref.watch(customerTicketRepliesProvider(widget.ticketId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticketId),
      ),
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
                  ref.invalidate(customerTicketDetailProvider(widget.ticketId));
                  ref.invalidate(customerTicketRepliesProvider(widget.ticketId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketDetail(TicketModel ticket, AsyncValue<List<TicketReplyModel>> repliesAsync) {
    final isTicketClosed = ticket.status.value.toLowerCase() == 'closed';
    
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
                if (ticket.attachments != null && ticket.attachments!.isNotEmpty)
                  _buildAttachmentsSection(ticket.attachments!),

                const SizedBox(height: 16),

                // Replies Section
                _buildRepliesSection(repliesAsync),
                
                // Closed ticket notice
                if (isTicketClosed) ...[
                  const SizedBox(height: 16),
                  _buildClosedTicketNotice(),
                ],
              ],
            ),
          ),
        ),

        // Reply Input (disabled if closed)
        if (!isTicketClosed) _buildReplyInput(),
      ],
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            Text(
              ticket.message ?? '',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Metadata
            _buildInfoRow(Icons.category, 'Category', ticket.categoryName ?? 'N/A'),
            if (ticket.subCategoryName != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.category_outlined, 'Sub Category', ticket.subCategoryName!),
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
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
                return AttachmentViewer(attachment: attachment);
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
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No replies yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Replies (${replies.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ...replies.map((reply) => _buildReplyCard(reply)),
          ],
        );
      },
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  'Loading replies...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 40, color: AppColors.error),
                const SizedBox(height: 12),
                Text(
                  'Failed to load replies',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyCard(TicketReplyModel reply) {
    final isCustomer = reply.userRole.toLowerCase() == 'customer';

    return Card(
      color: isCustomer ? AppColors.white : AppColors.background,
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
                  backgroundColor: isCustomer ? AppColors.primary : AppColors.success,
                  child: Icon(
                    isCustomer ? Icons.person : Icons.support_agent,
                    size: 18,
                    color: AppColors.white,
                  ),
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
                            DateFormat('dd MMM yyyy, HH:mm').format(reply.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                          if (reply.isEdited) ...[
                            const SizedBox(width: 4),
                            Text(
                              '• edited',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCustomer
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reply.userRole,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isCustomer ? AppColors.primary : AppColors.success,
                    ),
                  ),
                ),
                // Edit button for editable replies
                if (reply.editable) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _startEditReply(reply),
                    color: AppColors.primary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Edit reply',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Reply Message
            Text(
              reply.comment,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            
            // Edited indicator (below comment)
            if (reply.isEdited) ...[
              const SizedBox(height: 4),
              Text(
                'edited',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

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

  Widget _buildClosedTicketNotice() {
    return Card(
      color: AppColors.statusClosed.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: AppColors.statusClosed,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ticket Closed',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusClosed,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This ticket has been closed. No further actions can be taken.',
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

  Widget _buildReplyInput() {
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
          // Edit mode indicator
          if (_isEditMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Editing reply',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _cancelEdit,
                    child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Status dropdown (only for new replies, not edit)
          if (!_isEditMode) ...[
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
              items: const [
                DropdownMenuItem(value: null, child: Text('No change')),
                DropdownMenuItem(value: 'New', child: Text('New')),
                DropdownMenuItem(value: 'Solved', child: Text('Solved')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 8),
          ],

          // Selected Files (only for new replies)
          if (!_isEditMode && _selectedFiles.isNotEmpty) ...[
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
              // Attach button (disabled in edit mode)
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _isEditMode 
                    ? null 
                    : (_selectedFiles.length < 5 ? _pickFiles : null),
                color: _isEditMode ? AppColors.textHint : AppColors.primary,
              ),
              Expanded(
                child: TextField(
                  controller: _replyController,
                  decoration: InputDecoration(
                    hintText: _isEditMode 
                        ? 'Edit your reply...' 
                        : 'Type your reply...',
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
                      icon: Icon(_isEditMode ? Icons.check : Icons.send),
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
