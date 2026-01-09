import 'package:flutter/material.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';
import 'package:helpdesk_mobile/data/models/ticket_model.dart';
import 'package:helpdesk_mobile/data/enums/ticket_status.dart';
import 'package:intl/intl.dart';

class TicketCard extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onTap;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.newTicket:
        return AppColors.statusNew;
      case TicketStatus.inProgress:
        return AppColors.statusInProgress;
      case TicketStatus.solved:
        return AppColors.statusSolved;
      case TicketStatus.closed:
        return AppColors.statusClosed;
      case TicketStatus.cancelled:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Ticket ID & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ticket.ticketId,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ticket.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(ticket.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      ticket.status.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(ticket.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Subject
              Text(
                ticket.subject,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Category & Priority
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (ticket.categoryName != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ticket.categoryName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  if (ticket.priority != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ticket.priority!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Request To
              if (ticket.requestToName != null)
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'To: ${ticket.requestToName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (ticket.requestToName != null)
                const SizedBox(height: 8),

              // Footer: Date & Last Reply
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(ticket.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                  if (ticket.lastReply != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.reply,
                      size: 14,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Last: ${DateFormat('dd MMM').format(ticket.lastReply!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
