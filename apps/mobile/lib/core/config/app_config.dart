class AppConfig {
  AppConfig._();

  static const String appName = 'ClassRoom';
  static const String appVersion = '1.0.0';

  // Environment variables supplied via --dart-define or --dart-define-from-file
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hpktztdtczjltntlpbbj.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhwa3R6dGR0Y3pqbHRudGxwYmJqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM2ODU1MDQsImV4cCI6MjEwOTI2MTUwNH0.8W6POC7vUx4uePZuo0m4uxkYjWsDCZ6l5P-tC-lYxD4',
  );

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '1024179326506-9gue9fu3b7sg9pf8qg4403lfndc5cbiq.apps.googleusercontent.com',
  );
}

