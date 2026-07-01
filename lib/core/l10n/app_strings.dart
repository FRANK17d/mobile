/// Cadenas de texto localizables para TOKE+.
/// Estructura preparada para agregar mas idiomas en el futuro.
///
/// Uso: `S.of(context).appName` o `AppStrings.es.appName`
class AppStrings {
  const AppStrings._({
    required this.appName,
    required this.home,
    required this.search,
    required this.orders,
    required this.profile,
    required this.settings,
    required this.login,
    required this.register,
    required this.logout,
    required this.cancel,
    required this.save,
    required this.confirm,
    required this.delete,
    required this.edit,
    required this.loading,
    required this.error,
    required this.retry,
    required this.noResults,
    required this.connectionError,
    required this.sessionExpired,
  });

  final String appName;
  final String home;
  final String search;
  final String orders;
  final String profile;
  final String settings;
  final String login;
  final String register;
  final String logout;
  final String cancel;
  final String save;
  final String confirm;
  final String delete;
  final String edit;
  final String loading;
  final String error;
  final String retry;
  final String noResults;
  final String connectionError;
  final String sessionExpired;

  /// Español (idioma por defecto)
  static const es = AppStrings._(
    appName: 'Toke+',
    home: 'Inicio',
    search: 'Buscar',
    orders: 'Pedidos',
    profile: 'Perfil',
    settings: 'Ajustes',
    login: 'Iniciar sesion',
    register: 'Registrarse',
    logout: 'Cerrar sesion',
    cancel: 'Cancelar',
    save: 'Guardar',
    confirm: 'Confirmar',
    delete: 'Eliminar',
    edit: 'Editar',
    loading: 'Cargando...',
    error: 'Ocurrio un error',
    retry: 'Reintentar',
    noResults: 'Sin resultados',
    connectionError: 'Sin conexion a internet',
    sessionExpired: 'Tu sesion expiro. Inicia sesion nuevamente.',
  );

  /// English (placeholder for future)
  static const en = AppStrings._(
    appName: 'Toke+',
    home: 'Home',
    search: 'Search',
    orders: 'Orders',
    profile: 'Profile',
    settings: 'Settings',
    login: 'Sign in',
    register: 'Sign up',
    logout: 'Sign out',
    cancel: 'Cancel',
    save: 'Save',
    confirm: 'Confirm',
    delete: 'Delete',
    edit: 'Edit',
    loading: 'Loading...',
    error: 'An error occurred',
    retry: 'Retry',
    noResults: 'No results',
    connectionError: 'No internet connection',
    sessionExpired: 'Your session expired. Please sign in again.',
  );

  /// Idioma actual (hardcoded a español por ahora).
  /// Cambiar a un sistema con InheritedWidget/Provider cuando se implemente el switcher.
  static AppStrings get current => es;
}
