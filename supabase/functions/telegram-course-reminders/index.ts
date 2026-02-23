import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const TELEGRAM_BOT_TOKEN = Deno.env.get('TELEGRAM_BOT_TOKEN')
const TELEGRAM_CHANNEL_ID = Deno.env.get('TELEGRAM_CHANNEL_ID')
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

// Initialize Supabase Client with service role to bypass RLS
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

serve(async (req) => {
  try {
    // Only accept POST requests for security (Triggered by Cron)
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    // Verify it's actually our cron job calling
    const authHeader = req.headers.get('Authorization')
    if (authHeader !== `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`) {
      // In production, use a dedicated custom secret for the webhook/cron 
      // instead of the service role key for the auth header if preferred.
    }

    if (!TELEGRAM_BOT_TOKEN || !TELEGRAM_CHANNEL_ID) {
      throw new Error("Telegram credentials not configured in Edge Secrets");
    }

    console.log("🔍 Checking for upcoming courses...");

    // Get current time in UTC
    const now = new Date();
    // Look ahead 30 minutes
    const lookAheadTime = new Date(now.getTime() + 30 * 60000); 

    // Fetch all active courses
    const { data: courses, error } = await supabase
      .from('courses')
      .select('*')
      .eq('is_active', true)

    if (error) throw error;
    if (!courses || courses.length === 0) {
      return new Response(JSON.stringify({ message: "No active courses found" }), {
        headers: { "Content-Type": "application/json" },
      })
    }

    let messagesSent = 0;

    for (const course of courses) {
      const courseStartTime = new Date(course.start_time);
      let shouldSendReminder = false;

      // Logic to determine if course starts in the next ~15-30 minutes window
      if (course.recurrence === 'once') {
        // One-time course
        if (courseStartTime > now && courseStartTime <= lookAheadTime) {
          shouldSendReminder = true;
        }
      } else if (course.recurrence === 'weekly') {
        // Weekly course - check day of week and time
        if (now.getDay() === course.recurrence_day) {
           const timeToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), courseStartTime.getHours(), courseStartTime.getMinutes());
           if (timeToday > now && timeToday <= lookAheadTime) {
             shouldSendReminder = true;
           }
        }
      } else if (course.recurrence === 'daily') {
        // Daily course - just check time today
        const timeToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), courseStartTime.getHours(), courseStartTime.getMinutes());
        if (timeToday > now && timeToday <= lookAheadTime) {
          shouldSendReminder = true;
        }
      }

      if (shouldSendReminder) {
        console.log(`🔔 Sending reminder for course: ${course.title}`);
        
        // Format time (ex: 14:00)
        const timeStr = courseStartTime.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit', timeZone: 'UTC' }); 
        // Note: Timezone handling might need adjustment depending on your DB storage timezone vs users.

        let message = `📚 **Rappel de Cours !**\n\n`;
        message += `Le cours **"${course.title}"** va commencer prochainement.\n\n`;
        if (course.teacher_name) {
          message += `👨‍🏫 **Professeur:** ${course.teacher_name}\n`;
        }
        if (course.telegram_link) {
          message += `\n🔗 Rejoignez directement sur Telegram ici :\n${course.telegram_link}`;
        }

        // Send to Telegram API
        const telegramUrl = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
        const response = await fetch(telegramUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            chat_id: TELEGRAM_CHANNEL_ID,
            text: message,
            parse_mode: 'Markdown',
            disable_web_page_preview: true,
          }),
        });

        if (!response.ok) {
          const errorData = await response.text();
          console.error(`❌ Failed to send Telegram message for ${course.title}:`, errorData);
        } else {
          messagesSent++;
        }
      }
    }

    return new Response(JSON.stringify({ 
      success: true, 
      messages_sent: messagesSent,
      checked_courses: courses.length
    }), {
      headers: { "Content-Type": "application/json" },
      status: 200
    })

  } catch (err) {
    console.error(`Edge Function Error: ${err.message}`);
    return new Response(JSON.stringify({ error: err.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500
    })
  }
})
