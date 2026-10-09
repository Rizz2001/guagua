/// Constantes de configuración para la conexión con Supabase.
///
/// Reemplaza [supabaseUrl] y [supabaseAnonKey] con las credenciales de tu proyecto
/// desde el panel de Supabase (Project Settings -> API).
class SupabaseConstants {
  // Configuración de Supabase
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ptfefcqyjwfeaymedgnu.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB0ZmVmY3F5andmZWF5bWVkZ251Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE0OTg4NDgsImV4cCI6MjEwNzA3NDg0OH0.cjWzo9nBa9IIL9hDUJ3HeBuEHASEglMLB7PA_GT_MUo',
  );

  /// Retorna true si Supabase tiene credenciales reales configuradas.
  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') &&
      !supabaseUrl.contains('YOUR_SUPABASE_URL_HERE') &&
      supabaseAnonKey.length > 20;
}
