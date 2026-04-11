-- GL-3: AI Conversation Partner
-- Tables for voice conversation sessions with AI native speakers.

-- Conversation scenarios (e.g., airport, restaurant, job interview)
create table if not exists ai_conversation_scenarios (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  language text not null default 'de',
  difficulty text not null default 'beginner' check (difficulty in ('beginner', 'intermediate', 'advanced')),
  system_prompt text not null,
  icon_name text not null default 'chat',
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

-- Individual conversation sessions
create table if not exists ai_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  scenario_id uuid references ai_conversation_scenarios(id) on delete set null,
  language text not null default 'de',
  status text not null default 'active' check (status in ('active', 'completed', 'abandoned')),
  fluency_score int,        -- 0-100
  vocabulary_score int,     -- 0-100
  grammar_score int,        -- 0-100
  overall_score int,        -- 0-100
  xp_awarded int not null default 0,
  turn_count int not null default 0,
  duration_seconds int,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

-- Individual messages within a conversation
create table if not exists ai_conversation_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references ai_conversations(id) on delete cascade,
  role text not null check (role in ('user', 'assistant', 'system')),
  content text not null,
  audio_url text,           -- R2 URL for recorded/synthesized audio
  transcription text,       -- Whisper transcription of user audio
  duration_ms int,          -- Audio duration
  created_at timestamptz not null default now()
);

-- User API keys for BYOK (ElevenLabs, OpenAI/Whisper)
create table if not exists ai_api_keys (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  provider text not null check (provider in ('elevenlabs', 'openai', 'anthropic')),
  api_key_encrypted text not null,
  is_valid boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, provider)
);

-- Indexes
create index if not exists idx_ai_conversations_user on ai_conversations(user_id);
create index if not exists idx_ai_conversations_status on ai_conversations(status);
create index if not exists idx_ai_conversation_messages_conv on ai_conversation_messages(conversation_id);
create index if not exists idx_ai_api_keys_user on ai_api_keys(user_id);

-- RLS
alter table ai_conversation_scenarios enable row level security;
alter table ai_conversations enable row level security;
alter table ai_conversation_messages enable row level security;
alter table ai_api_keys enable row level security;

-- Scenarios: readable by all authenticated users
create policy "Scenarios are readable by authenticated users"
  on ai_conversation_scenarios for select
  to authenticated
  using (true);

-- Conversations: users can only access their own
create policy "Users can read own conversations"
  on ai_conversations for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can create own conversations"
  on ai_conversations for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update own conversations"
  on ai_conversations for update
  to authenticated
  using (auth.uid() = user_id);

-- Messages: users can access messages from their own conversations
create policy "Users can read own conversation messages"
  on ai_conversation_messages for select
  to authenticated
  using (
    exists (
      select 1 from ai_conversations
      where ai_conversations.id = ai_conversation_messages.conversation_id
        and ai_conversations.user_id = auth.uid()
    )
  );

create policy "Users can insert own conversation messages"
  on ai_conversation_messages for insert
  to authenticated
  with check (
    exists (
      select 1 from ai_conversations
      where ai_conversations.id = ai_conversation_messages.conversation_id
        and ai_conversations.user_id = auth.uid()
    )
  );

-- API keys: users can only manage their own
create policy "Users can read own API keys"
  on ai_api_keys for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert own API keys"
  on ai_api_keys for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update own API keys"
  on ai_api_keys for update
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can delete own API keys"
  on ai_api_keys for delete
  to authenticated
  using (auth.uid() = user_id);

-- Seed scenarios
insert into ai_conversation_scenarios (title, description, language, difficulty, system_prompt, icon_name, sort_order) values
  ('At the Airport', 'Navigate check-in, security, and boarding in the target language.', 'de', 'beginner',
   'You are a friendly airport staff member at Frankfurt Airport. Speak only in German. Keep sentences simple for a beginner. Help the user check in for their flight, go through security, and find their gate. Correct major errors gently by rephrasing.',
   'flight', 1),
  ('Restaurant Order', 'Order food, ask about the menu, and handle the bill.', 'de', 'beginner',
   'You are a waiter at a traditional German restaurant in Munich. Speak only in German. Keep language simple. Present the menu, take the order, and handle payment. If the user struggles, offer simpler alternatives.',
   'restaurant', 2),
  ('Job Interview', 'Practice answering common interview questions professionally.', 'de', 'advanced',
   'You are an HR manager at a German tech company conducting a job interview in German. Use formal register (Sie). Ask about experience, motivation, and skills. Provide professional but warm feedback. Use complex sentence structures appropriate for advanced learners.',
   'work', 3),
  ('Hotel Check-in', 'Check into a hotel, ask about amenities, and handle requests.', 'de', 'beginner',
   'You are a hotel receptionist in Berlin. Speak only in German at a beginner level. Help the user check in, explain breakfast times, Wi-Fi, and room amenities. Be patient and rephrase if needed.',
   'hotel', 4),
  ('Doctor Visit', 'Describe symptoms and understand medical advice.', 'de', 'intermediate',
   'You are a general practitioner in a German clinic. Speak German at an intermediate level. Ask about symptoms, medical history, and provide advice. Use medical vocabulary but explain complex terms.',
   'local_hospital', 5),
  ('Shopping', 'Browse a market, ask about prices, and negotiate.', 'de', 'beginner',
   'You are a vendor at a German outdoor market. Speak simple German. Sell fruits, vegetables, and local products. State prices, offer deals, and help the user find what they need.',
   'shopping_cart', 6),
  ('Giving Directions', 'Ask for and give directions around a city.', 'de', 'intermediate',
   'You are a local in Hamburg. A tourist is asking you for directions in German. Use intermediate-level German with prepositions and spatial vocabulary. Reference real Hamburg landmarks.',
   'directions', 7),
  ('Phone Call', 'Handle a phone conversation — appointments, complaints, inquiries.', 'de', 'intermediate',
   'You are a customer service representative for a German telecom company. Handle the call professionally in German. The user might want to book an appointment, make a complaint, or ask about their account.',
   'phone', 8),
  ('At the Airport', 'Navigate check-in and boarding at a French airport.', 'fr', 'beginner',
   'You are a staff member at Charles de Gaulle Airport in Paris. Speak only in French. Keep sentences simple. Help the user with check-in, security, and finding their gate.',
   'flight', 9),
  ('Café Conversation', 'Order coffee and chat casually at a Parisian café.', 'fr', 'beginner',
   'You are a barista at a cozy Parisian café. Speak casual French. Take coffee orders, suggest pastries, and make small talk about the weather and Paris.',
   'coffee', 10),
  ('At the Airport', 'Navigate a Russian airport with basic Russian.', 'ru', 'beginner',
   'You are staff at Sheremetyevo Airport in Moscow. Speak simple Russian. Help with check-in and directions. Use basic vocabulary and short sentences.',
   'flight', 11),
  ('Tea House', 'Order tea and discuss varieties at a Chinese tea house.', 'zh', 'beginner',
   'You are the owner of a traditional tea house in Beijing. Speak simple Mandarin Chinese. Introduce different teas, explain brewing methods, and help the user choose. Use pinyin-friendly vocabulary.',
   'emoji_food_beverage', 12);
