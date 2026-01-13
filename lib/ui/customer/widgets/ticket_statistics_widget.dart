import 'package:flutter/material.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';

class TicketStatisticsWidget extends StatelessWidget {
  final int totalTickets;
  final int inProgressTickets;
  final int closedTickets;
  final int cancelledTickets;
  final Function(String?)? onStatusTap;

  const TicketStatisticsWidget({
    super.key,
    required this.totalTickets,
    required this.inProgressTickets,
    required this.closedTickets,
    required this.cancelledTickets,
    this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ticket Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Responsive Grid - 2 columns only
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                title: 'Total',
                count: totalTickets,
                icon: Icons.confirmation_number,
                color: AppColors.primary,
                onTap: () => onStatusTap?.call(null),
              ),
              _buildStatCard(
                title: 'In Progress',
                count: inProgressTickets,
                icon: Icons.sync,
                color: AppColors.statusInProgress,
                onTap: () => onStatusTap?.call('Inprogress'),
              ),
              _buildStatCard(
                title: 'Closed',
                count: closedTickets,
                icon: Icons.check_circle,
                color: AppColors.statusClosed,
                onTap: () => onStatusTap?.call('Closed'),
              ),
              _buildStatCard(
                title: 'Cancelled',
                count: cancelledTickets,
                icon: Icons.cancel,
                color: AppColors.error,
                onTap: () => onStatusTap?.call('Cancelled'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon + Number (horizontal)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Status name below
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
