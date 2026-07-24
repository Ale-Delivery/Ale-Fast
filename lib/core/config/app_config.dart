class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
      'https://supabase.com/dashboard/project/bwilctlrsmmpyulmgoog');

  static const supabaseAnonKey = String.fromEnvironment(
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ3aWxjdGxyc21tcHl1bG1nb29nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ4OTY0NzgsImV4cCI6MjEwMDQ3MjQ3OH0.yUZA_y4v214yP2WQHT1Y5XfiIxcVo_qX7BFlZwkwkDA');

  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'SUPABASE_URL and SUPABASE_ANON_KEY are missing.',
      );
    }
  }
}
