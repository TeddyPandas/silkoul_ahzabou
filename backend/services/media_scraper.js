const YouTube = require("youtube-sr").default;
const { createClient } = require("@supabase/supabase-js");

// Initialize Supabase
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY;
if (!supabaseUrl || !supabaseKey) {
    console.error("❌ Supabase credentials missing.");
}
const supabase = createClient(supabaseUrl, supabaseKey);

/**
 * Extracts a search query (Handle or ID) from a YouTube URL.
 * Falls back to the original string if no URL pattern is found.
 */
function extractChannelIdentifier(input) {
    if (!input) return null;

    // Pattern for @Handle
    const handleMatch = input.match(/youtube\.com\/@([a-zA-Z0-9_\-]+)/);
    if (handleMatch) return handleMatch[1]; // Return handle (e.g. "CheikhSkiredj") as query

    // Pattern for Channel ID
    const idMatch = input.match(/youtube\.com\/channel\/(UC[a-zA-Z0-9_\-]+)/);
    if (idMatch) return idMatch[1];

    // Pattern for Custom URL /c/ or /user/
    const customMatch = input.match(/youtube\.com\/(?:c|user)\/([a-zA-Z0-9_\-]+)/);
    if (customMatch) return customMatch[1];

    return input; // Assume it's already a name or ID
}

/**
 * Scrapes videos from a specific channel's "Uploads" playlist.
 * @param {string} rawInput - Channel name OR URL
 */
async function syncChannel(rawInput = "Cheikh Ahmad Skiredj") {
    const channelQuery = extractChannelIdentifier(rawInput);
    console.log(`🔄 Starting sync for input: "${rawInput}" (Parsed: "${channelQuery}")...`);

    const errors = [];
    let upsertCount = 0;

    try {
        // 1. Find the Channel to get ID
        // youtube-sr searches by keyword well. Handles work great as keywords.
        const channelResult = await YouTube.searchOne(channelQuery, "channel");
        if (!channelResult) {
            throw new Error(`Channel not found: ${channelQuery}`);
        }

        const channelId = channelResult.id;
        const channelName = channelResult.name;

        // 2. Derive Uploads Playlist ID (UC -> UU)
        // Example: UCo7... -> UUo7...
        let uploadsId = channelId;
        if (channelId.startsWith("UC")) {
            uploadsId = "UU" + channelId.substring(2);
        }

        console.log(`✅ Channel: ${channelName} (${channelId})`);
        console.log(`ℹ️ Uploads Playlist: ${uploadsId}`);

        // 3. Fetch Playlist Videos
        const playlist = await YouTube.getPlaylist(uploadsId, { limit: 50 });
        if (!playlist || !playlist.videos) {
            return { success: true, count: 0, message: "No videos found in uploads" };
        }

        const videos = playlist.videos;
        console.log(`📥 Fetched ${videos.length} videos from playlist.`);

        // 4. Ensure Author Exists
        let { data: author } = await supabase
            .from("media_authors")
            .select("id")
            .ilike("name", `%${channelName}%`)
            .maybeSingle();

        if (!author) {
            console.log("⚠️ Author not found. Creating new author...");
            const { data: newAuthor, error: authError } = await supabase
                .from("media_authors")
                .insert({
                    name: channelName,
                    avatar_url: channelResult.icon?.url,
                    bio: "Chaîne officielle",
                })
                .select()
                .single();
            if (authError) throw authError;
            author = newAuthor;
        }

        // 5. Ensure Category Exists
        let { data: category } = await supabase
            .from("media_categories")
            .select("id")
            .eq("name", "Enseignements")
            .maybeSingle();

        if (!category) {
            const { data: newCat } = await supabase
                .from("media_categories")
                .insert({ name: 'Enseignements', rank: 1 })
                .select()
                .single();
            category = newCat;
        }

        // 6. Upsert Videos
        for (const video of videos) {
            // Fix: Parse relative date (default to now if missing)
            let publishedDate = new Date();
            if (video.uploadedAt) { // e.g. "2 years ago"
                try {
                    const now = new Date();
                    const str = video.uploadedAt.toLowerCase();
                    const num = parseInt(str.match(/\d+/)?.[0] || "0");
                    if (num > 0) {
                        if (str.includes("year")) now.setFullYear(now.getFullYear() - num);
                        else if (str.includes("month")) now.setMonth(now.getMonth() - num);
                        else if (str.includes("day")) now.setDate(now.getDate() - num);
                        else if (str.includes("hour")) now.setHours(now.getHours() - num);
                        publishedDate = now;
                    }
                } catch (e) { console.warn("Date parse error", e); }
            }

            const { error } = await supabase.from("media_videos").upsert(
                {
                    youtube_id: video.id,
                    title: video.title,
                    description: video.description || "",
                    duration: video.duration ? Math.floor(video.duration / 1000) : 0,
                    published_at: publishedDate.toISOString(),
                    author_id: author.id,
                    category_id: category.id,
                    status: "PUBLISHED",
                },
                { onConflict: "youtube_id" }
            );

            if (!error) upsertCount++;
            else {
                console.error(`❌ Upsert error ${video.id}:`, error.message);
                errors.push({ id: video.id, msg: error.message });
            }
        }

        console.log(`✅ Sync Completed. Upserted ${upsertCount} videos.`);
        return { success: true, count: upsertCount, channel: channelName, errors: errors };

    } catch (error) {
        console.error("❌ Sync Error:", error);
        return { success: false, error: error.message, stack: error.stack };
    }
}

module.exports = { syncChannel };
