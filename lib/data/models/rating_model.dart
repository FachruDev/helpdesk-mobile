/// Models for Customer CSAT Rating (GET form + POST submit).
library;

class RatingScale {
  final int min;
  final int max;
  final List<int> values;

  RatingScale({required this.min, required this.max, required this.values});

  factory RatingScale.fromJson(Map<String, dynamic> json) {
    return RatingScale(
      min: json['min'] ?? 1,
      max: json['max'] ?? 5,
      values: json['values'] != null
          ? List<int>.from(json['values'])
          : List.generate(5, (i) => i + 1),
    );
  }
}

class RatingOption {
  final int value;
  final String label;
  final int points;

  RatingOption({required this.value, required this.label, required this.points});

  factory RatingOption.fromJson(Map<String, dynamic> json) {
    return RatingOption(
      value: json['value'] ?? 0,
      label: json['label'] ?? '',
      points: json['points'] ?? 0,
    );
  }
}

class RatingStatus {
  final bool isClosed;
  final bool alreadyRated;
  final bool canRate;
  final String? reasonIfBlocked;

  RatingStatus({
    required this.isClosed,
    required this.alreadyRated,
    required this.canRate,
    this.reasonIfBlocked,
  });

  factory RatingStatus.fromJson(Map<String, dynamic> json) {
    return RatingStatus(
      isClosed: json['is_closed'] ?? false,
      alreadyRated: json['already_rated'] ?? false,
      canRate: json['can_rate'] ?? false,
      reasonIfBlocked: json['reason_if_blocked'],
    );
  }
}

class ExistingRating {
  final int id;
  final int rating;
  final String? comment;
  final DateTime? submittedAt;
  final DateTime? updatedAt;

  ExistingRating({
    required this.id,
    required this.rating,
    this.comment,
    this.submittedAt,
    this.updatedAt,
  });

  factory ExistingRating.fromJson(Map<String, dynamic> json) {
    return ExistingRating(
      id: json['id'] ?? 0,
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}

class RatingTicketSummary {
  final int id;
  final String ticketId;
  final String subject;

  RatingTicketSummary({
    required this.id,
    required this.ticketId,
    required this.subject,
  });

  factory RatingTicketSummary.fromJson(Map<String, dynamic> json) {
    return RatingTicketSummary(
      id: json['id'] ?? 0,
      ticketId: json['ticket_id'] ?? '',
      subject: json['subject'] ?? '',
    );
  }
}

/// Full response of GET /api/mobile/tickets/{id}/rating/form
class RatingFormModel {
  final RatingTicketSummary ticket;
  final RatingStatus status;
  final RatingScale scale;
  final List<RatingOption> ratingOptions;
  final ExistingRating? existingRating;
  final bool canSubmit;

  RatingFormModel({
    required this.ticket,
    required this.status,
    required this.scale,
    required this.ratingOptions,
    this.existingRating,
    required this.canSubmit,
  });

  factory RatingFormModel.fromJson(Map<String, dynamic> json) {
    return RatingFormModel(
      ticket: RatingTicketSummary.fromJson(json['ticket'] ?? {}),
      status: RatingStatus.fromJson(json['status'] ?? {}),
      scale: RatingScale.fromJson(json['scale'] ?? {}),
      ratingOptions: json['rating_options'] != null
          ? (json['rating_options'] as List)
              .map((e) => RatingOption.fromJson(e))
              .toList()
          : [],
      existingRating: json['existing_rating'] != null
          ? ExistingRating.fromJson(json['existing_rating'])
          : null,
      canSubmit: json['can_submit'] ?? false,
    );
  }
}

/// Response of POST /api/mobile/tickets/{id}/rating
class RatingSubmitResult {
  final int rating;
  final RatingTicketSummary ticket;
  final RatingStatus status;
  final ExistingRating submittedRating;
  final int? pointValue;

  RatingSubmitResult({
    required this.rating,
    required this.ticket,
    required this.status,
    required this.submittedRating,
    this.pointValue,
  });

  factory RatingSubmitResult.fromJson(Map<String, dynamic> json) {
    return RatingSubmitResult(
      rating: json['rating'] ?? 0,
      ticket: RatingTicketSummary.fromJson(json['ticket'] ?? {}),
      status: RatingStatus.fromJson(json['status'] ?? {}),
      submittedRating: ExistingRating.fromJson(json['submitted_rating'] ?? {}),
      pointValue: json['point_value'],
    );
  }
}
