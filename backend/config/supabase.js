const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Validation des variables d'environnement
if (!process.env.SUPABASE_URL || !process.env.SUPABASE_ANON_KEY) {
  throw new Error('Les variables SUPABASE_URL et SUPABASE_ANON_KEY sont requises');
}

// Client Supabase pour les opérations publiques (avec RLS)
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// Client Supabase admin pour les opérations privilégiées (bypass RLS)
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  }
);

module.exports = {
  supabase,
  supabaseAdmin
};
