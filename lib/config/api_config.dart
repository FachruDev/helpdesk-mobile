class ApiConfig {
  ApiConfig._();

  // Base URL from .env
  static String get baseUrl => const String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://143.198.212.197:8001',
      );

  // Customer Endpoints
  static const String customerLogin = '/api/mobile/login';
  static const String customerLogout = '/api/mobile/logout';
  static const String customerMe = '/api/mobile/me';
  static const String customerCategories = '/api/mobile/categories';
  static const String customerEmployees = '/api/mobile/employees';
  static const String customerTickets = '/api/mobile/tickets';
  
  static String customerTicketDetail(String ticketId) =>
      '/api/mobile/tickets/$ticketId';
  
  static String customerTicketReply(String ticketId) =>
      '/api/mobile/tickets/$ticketId/reply';

  // Internal Endpoints
  static const String internalLogin = '/api/mobile/internal/login';
  static const String internalLogout = '/api/mobile/internal/logout';
  static const String internalMe = '/api/mobile/internal/me';
  static const String internalCategories = '/api/mobile/internal/categories';
  static const String internalEmployees = '/api/mobile/internal/employees';
  static const String internalTickets = '/api/mobile/internal/tickets';
  
  static String internalTicketDetail(String ticketId) =>
      '/api/mobile/internal/tickets/$ticketId';
  
  static String internalTicketReply(String ticketId) =>
      '/api/mobile/internal/tickets/$ticketId/reply';

  // Headers
  static Map<String, String> headers({String? token}) {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  static Map<String, String> multipartHeaders({String? token}) {
    final Map<String, String> headers = {
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
}
