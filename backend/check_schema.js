const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);

async function checkSchema() {
    console.log('Fetching a single profile to inspect its structure...');
    const { data, error } = await supabase.from('profiles').select('*').limit(1);
    if (error) {
        console.error('Error:', error);
    } else {
        console.log('Profile data:', JSON.stringify(data, null, 2));

        if (data && data.length > 0) {
            console.log('\nColumns present in the response:');
            console.log(Object.keys(data[0]).join(', '));
        } else {
            console.log('No profiles found to inspect.');
        }
    }
}

checkSchema();
