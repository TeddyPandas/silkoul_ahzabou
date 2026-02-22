const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);

async function testSignup() {
    console.log('Testing direct signup with Supabase Auth...');
    const { data, error } = await supabase.auth.signUp({
        email: 'test_signup9@example.com',
        password: 'password123',
        options: {
            data: { display_name: 'Test 9' }
        }
    });
    console.log("\ndata:", JSON.stringify(data, null, 2));
    console.log("\nerror:", error ? error : "No error");
}

testSignup();
