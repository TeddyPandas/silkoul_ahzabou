create table public.transcripts (
  id uuid default gen_random_uuid() primary key,
  teaching_id uuid references public.teachings(id) not null,
  language text default 'fr', -- Target language for translation (e.g. 'fr', 'en')
  content jsonb not null,     -- The structured List<TranscriptSegment>
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.transcripts enable row level security;

-- Policies
create policy "Public transcripts are viewable by everyone."
  on public.transcripts for select
  using ( true );

create policy "Admins can insert transcripts."
  on public.transcripts for insert
  with check ( true ); -- In prod, restrict this to admins

create policy "Admins can update transcripts."
  on public.transcripts for update
  using ( true );
