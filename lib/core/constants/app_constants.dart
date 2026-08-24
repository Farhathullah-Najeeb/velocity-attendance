class AppConstants {
  // Try to use environment variable if possible, but default to onrender URL
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://attendanace-backend.onrender.com/api',
  );
}
