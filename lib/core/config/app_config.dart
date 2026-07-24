class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
      'https://supabase.com/dashboard/project/cllzatzyqvrcxvvhyoxx');

  static const supabaseAnonKey = String.fromEnvironment(
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNsbHphdHp5cXZyY3h2dmh5b3h4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1NTAwMDMsImV4cCI6MjA5ODEyNjAwM30.Ps67eDq_EwAekg22_b3zxTKUS1yUTIiB_qbb-GHDE60');

  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'SUPABASE_URL and SUPABASE_ANON_KEY are missing.',
      );
    }
  }
}
