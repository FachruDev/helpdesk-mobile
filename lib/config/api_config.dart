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
  
  static String customerCategoryExtras(int categoryId) =>
      '/api/mobile/categories/$categoryId/extras';
  
  static String customerTicketDetail(String ticketId) =>
      '/api/mobile/tickets/$ticketId';
  
  static String customerTicketReplies(String ticketId) =>
      '/api/mobile/tickets/$ticketId/replies';
  
  static String customerTicketReply(String ticketId) =>
      '/api/mobile/tickets/$ticketId/reply';
  
  static String customerEditReply(String ticketId, int commentId) =>
      '/api/mobile/tickets/$ticketId/reply/$commentId/edit';

  // Internal Endpoints
  static const String internalLogin = '/api/mobile/internal/login';
  static const String internalLogout = '/api/mobile/internal/logout';
  static const String internalMe = '/api/mobile/internal/me';
  static const String internalCategories = '/api/mobile/internal/categories';
  static const String internalEmployees = '/api/mobile/internal/employees';
  static const String internalTickets = '/api/mobile/internal/tickets';
  
  static String internalCategoryExtras(int categoryId) =>
      '/api/mobile/internal/categories/$categoryId/extras';
  
  static String internalTicketDetail(String ticketId) =>
      '/api/mobile/internal/tickets/$ticketId';
  
  static String internalTicketReplies(String ticketId) =>
      '/api/mobile/internal/tickets/$ticketId/replies';
  
  static String internalTicketReply(String ticketId) =>
      '/api/mobile/internal/tickets/$ticketId/reply';
  
  static String internalEditReply(String ticketId, int commentId) =>
      '/api/mobile/internal/tickets/$ticketId/reply/$commentId/edit';

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
