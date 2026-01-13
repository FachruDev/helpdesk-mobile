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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Ticket ID & Status
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ticket.ticketId,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(ticket.status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ticket.status.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getStatusColor(ticket.status),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Subject
                Text(
                  ticket.subject,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.4,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Category & Priority
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (ticket.categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ticket.categoryName!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (ticket.priority != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flag,
                              size: 12,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ticket.priority!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Divider
                Container(
                  height: 1,
                  color: AppColors.background,
                ),
                const SizedBox(height: 12),

                // Footer: Date & Last Reply
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 15,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd MMM yyyy').format(ticket.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (ticket.lastReply != null) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.reply,
                              size: 13,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM').format(ticket.lastReply!),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
