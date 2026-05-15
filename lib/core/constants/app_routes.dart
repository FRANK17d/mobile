/// Nombres de rutas para navegacion con GoRouter
abstract final class AppRoutes {
  // ─── Entry Flow ───
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // ─── Auth (inactive for current no-login flow) ───
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String roleSelection = '/role-selection';

  // ─── Client ───
  static const String clientHome = '/client';
  static const String clientSearch = '/client/search';
  static const String clientBooking = '/client/booking';
  static const String clientTracking = '/client/tracking';
  static const String clientOrders = '/client/orders';
  static const String clientOrderDetail = '/client/orders/:id';
  static const String clientReview = '/client/review';
  static const String technicianDetail = '/client/technician/:id';

  // ─── Technician ───
  static const String techHome = '/technician';
  static const String techRequests = '/technician/requests';
  static const String techRequestDetail = '/technician/requests/:id';
  static const String techJobs = '/technician/jobs';
  static const String techJobDetail = '/technician/jobs/:id';
  static const String techEarnings = '/technician/earnings';
  static const String techPortfolio = '/technician/portfolio';

  // ─── Shared ───
  static const String chat = '/chat';
  static const String chatDetail = '/chat/:id';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
}
