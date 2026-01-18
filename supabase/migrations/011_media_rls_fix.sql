-- Enable RLS (if not already)
ALTER TABLE public.media_authors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.media_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.media_videos ENABLE ROW LEVEL SECURITY;

-- Allow Public READ access (already likely there, but ensuring)
CREATE POLICY "Allow Public Read Authors" ON public.media_authors FOR SELECT USING (true);
CREATE POLICY "Allow Public Read Categories" ON public.media_categories FOR SELECT USING (true);
CREATE POLICY "Allow Public Read Videos" ON public.media_videos FOR SELECT USING (true);

-- Allow Public/Anon WRITE access for Scraper (Development Mode)
-- In production, this should be restricted to a Service Role or Admin User.
CREATE POLICY "Allow Anon Insert Authors" ON public.media_authors FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow Anon Update Authors" ON public.media_authors FOR UPDATE USING (true);

CREATE POLICY "Allow Anon Insert Categories" ON public.media_categories FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow Anon Update Categories" ON public.media_categories FOR UPDATE USING (true);

CREATE POLICY "Allow Anon Insert Videos" ON public.media_videos FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow Anon Update Videos" ON public.media_videos FOR UPDATE USING (true);
