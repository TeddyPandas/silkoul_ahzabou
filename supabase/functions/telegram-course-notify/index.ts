import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const TELEGRAM_BOT_TOKEN = Deno.env.get('TELEGRAM_BOT_TOKEN');
const TELEGRAM_CHANNEL_ID = Deno.env.get('TELEGRAM_CHANNEL_ID');

// Day names in French
const DAYS_FR = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
const MONTHS_FR = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];

function formatDate(dateStr: string): string {
  const d = new Date(dateStr);
  return `${DAYS_FR[d.getDay()]} ${d.getDate()} ${MONTHS_FR[d.getMonth()]} ${d.getFullYear()}`;
}

function formatTime(dateStr: string): string {
  const d = new Date(dateStr);
  return `${d.getHours().toString().padStart(2, '0')}h${d.getMinutes().toString().padStart(2, '0')}`;
}

function formatDuration(minutes: number): string {
  if (minutes < 60) return `${minutes}min`;
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return m > 0 ? `${h}h${m.toString().padStart(2, '0')}` : `${h}h`;
}

function recurrenceLabel(recurrence: string): string {
  switch (recurrence) {
    case 'weekly': return '🔁 Chaque semaine';
    case 'daily': return '🔁 Chaque jour';
    default: return '📌 Cours unique';
  }
}

function buildMessage(event: string, course: any, oldStartTime?: string): string {
  const greeting = `بسم الله الرحمن الرحيم\nالسلام عليكم ورحمة الله وبركاته\n\n`;
  
  let header = '';
  let body = '';
  let footer = '';

  switch (event) {
    case 'created':
      header = `📚 *𝗡𝗼𝘂𝘃𝗲𝗮𝘂 𝗖𝗼𝘂𝗿𝘀 𝗣𝗿𝗼𝗴𝗿𝗮𝗺𝗺𝗲́*\n\n`;
      body = `📖 *Titre :* ${course.title}\n`;
      if (course.teacher_name) body += `👨‍🏫 *Professeur :* ${course.teacher_name}\n`;
      body += `📅 *Date :* ${formatDate(course.start_time)}\n`;
      body += `🕐 *Heure :* ${formatTime(course.start_time)}\n`;
      body += `⏱ *Durée :* ${formatDuration(course.duration_minutes || 60)}\n`;
      body += `${recurrenceLabel(course.recurrence || 'once')}\n`;
      if (course.description) body += `\n📝 ${course.description}\n`;
      if (course.telegram_link) body += `\n🔗 *Rejoindre le cours :*\n${course.telegram_link}\n`;
      footer = `\nاللهم علمنا ما ينفعنا`;
      break;

    case 'rescheduled':
      header = `🔄 *𝗖𝗼𝘂𝗿𝘀 𝗥𝗲𝗽𝗿𝗼𝗴𝗿𝗮𝗺𝗺𝗲́*\n\n`;
      body = `📖 *Titre :* ${course.title}\n`;
      if (oldStartTime) {
        body += `📅 *Ancienne date :* ${formatDate(oldStartTime)} à ${formatTime(oldStartTime)}\n`;
      }
      body += `📅 *Nouvelle date :* ${formatDate(course.start_time)} à ${formatTime(course.start_time)}\n`;
      if (course.teacher_name) body += `👨‍🏫 *Professeur :* ${course.teacher_name}\n`;
      body += `⏱ *Durée :* ${formatDuration(course.duration_minutes || 60)}\n`;
      if (course.telegram_link) body += `\n🔗 *Rejoindre le cours :*\n${course.telegram_link}\n`;
      footer = `\nجزاكم الله خيرا`;
      break;

    case 'cancelled':
      header = `❌ *𝗖𝗼𝘂𝗿𝘀 𝗔𝗻𝗻𝘂𝗹𝗲́*\n\n`;
      body = `📖 *Titre :* ${course.title}\n`;
      if (course.teacher_name) body += `👨‍🏫 *Professeur :* ${course.teacher_name}\n`;
      body += `📅 *Date prévue :* ${formatDate(course.start_time)} à ${formatTime(course.start_time)}\n`;
      body += `\n⚠️ Ce cours a été annulé. Nous vous tiendrons informés d'une éventuelle reprogrammation.\n`;
      footer = `\nإنا لله وإنا إليه راجعون\nبارك الله فيكم`;
      break;

    default:
      header = `📢 *Mise à jour de cours*\n\n`;
      body = `📖 *Titre :* ${course.title}\n`;
  }

  return greeting + header + body + footer;
}

Deno.serve(async (req: Request) => {
  try {
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }

    if (!TELEGRAM_BOT_TOKEN || !TELEGRAM_CHANNEL_ID) {
      console.error("❌ Telegram credentials not configured");
      return new Response(
        JSON.stringify({ error: "Telegram credentials not configured. Set TELEGRAM_BOT_TOKEN and TELEGRAM_CHANNEL_ID in Edge Function secrets." }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const { event, course, old_start_time } = await req.json();

    if (!event || !course) {
      return new Response(
        JSON.stringify({ error: "Missing 'event' or 'course' in request body" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(`📨 Sending ${event} notification for course: ${course.title}`);

    const message = buildMessage(event, course, old_start_time);

    const telegramUrl = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
    const response = await fetch(telegramUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: TELEGRAM_CHANNEL_ID,
        text: message,
        parse_mode: 'Markdown',
        disable_web_page_preview: false,
      }),
    });

    const result = await response.json();

    if (!response.ok) {
      console.error(`❌ Telegram API error:`, result);
      return new Response(
        JSON.stringify({ success: false, error: result }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(`✅ Telegram notification sent for: ${course.title}`);

    return new Response(
      JSON.stringify({ success: true, message_id: result.result?.message_id }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );

  } catch (err) {
    console.error(`Edge Function Error: ${err.message}`);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
