enum TicketStatus {
  newTicket('New'),
  inProgress('Inprogress'),
  onHold('On-Hold'),
  backNew('Back New'),
  reOpen('Re-Open'),
  solved('Solved'),
  closed('Closed'),
  cancelled('Cancelled'),
  suspend('Suspend');

  final String value;
  const TicketStatus(this.value);

  static TicketStatus fromString(String status) {
    final normalized = status
        .trim()
        .toLowerCase()
        .replaceAll('-', ' ')
        .replaceAll('_', ' ');

    switch (normalized) {
      case 'new':
        return TicketStatus.newTicket;
      case 'in progress':
      case 'inprogress':
        return TicketStatus.inProgress;
      case 'on hold':
      case 'onhold':
        return TicketStatus.onHold;
      case 'back new':
      case 'backnew':
        return TicketStatus.backNew;
      case 're open':
      case 'reopen':
        return TicketStatus.reOpen;
      case 'solved':
        return TicketStatus.solved;
      case 'closed':
        return TicketStatus.closed;
      case 'cancelled':
      case 'canceled':
        return TicketStatus.cancelled;
      case 'suspend':
      case 'suspended':
        return TicketStatus.suspend;
      default:
        return TicketStatus.newTicket;
    }
  }

  String get displayName {
    switch (this) {
      case TicketStatus.newTicket:
        return 'New';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.onHold:
        return 'On Hold';
      case TicketStatus.backNew:
        return 'Back New';
      case TicketStatus.reOpen:
        return 'Re-Open';
      case TicketStatus.solved:
        return 'Solved';
      case TicketStatus.closed:
        return 'Closed';
      case TicketStatus.cancelled:
        return 'Cancelled';
      case TicketStatus.suspend:
        return 'Suspend';
    }
  }
}
