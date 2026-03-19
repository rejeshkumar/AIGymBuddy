/// API base URL configuration.
/// For web/Chrome: use localhost
/// For Android emulator: use 10.0.2.2 (emulator's alias for host machine)
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);
