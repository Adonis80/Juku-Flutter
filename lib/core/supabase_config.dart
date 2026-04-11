//
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://tipinjxdupfwntmkarkj.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRpcGluanhkdXBmd250bWthcmtqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2MTkwODYsImV4cCI6MjA5MDE5NTA4Nn0.kg2NuAJk1pFEpcXN0bbVma_xqMMjOIxcsNXlcLI8hhY';

SupabaseClient get supabase => Supabase.instance.client;
