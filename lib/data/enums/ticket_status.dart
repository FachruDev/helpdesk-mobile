enum TicketStatus {
  newTicket('New'),
  inProgress('Inprogress'),
  solved('Solved'),
  closed('Closed'),
  cancelled('Cancelled');

  final String value;
  const TicketStatus(this.value);

  static TicketStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return TicketStatus.newTicket;
      case 'inprogress':
      case 'in progress':
        return TicketStatus.inProgress;
      case 'solved':
        return TicketStatus.solved;
      case 'closed':
        return TicketStatus.closed;
      case 'cancelled':
        return TicketStatus.cancelled;
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
      case TicketStatus.solved:
        return 'Solved';
      case TicketStatus.closed:
        return 'Closed';
      case TicketStatus.cancelled:
        return 'Cancelled';
    }
  }
}
