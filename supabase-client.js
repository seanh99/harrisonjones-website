// ============================================================
// Harrison Jones — Supabase client (shared)
// Publishable key is safe to expose client-side; all access is
// gated by Row Level Security policies / SECURITY DEFINER RPCs.
// ============================================================

const SUPABASE_URL = 'https://ulyfruyxmzvskwkwctmt.supabase.co';
const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_LSlsPnNpcey1gskzg80SVQ__l3_iaTW';

const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);
