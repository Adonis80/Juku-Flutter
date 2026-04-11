-- GL-2: Juku for Schools
-- Classrooms, student membership, curated content, teacher dashboard

create table if not exists classrooms (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references profiles(id) on delete cascade,
  name text not null,
  description text,
  language text not null default 'german',
  join_code text not null unique default encode(gen_random_bytes(3), 'hex'),
  max_students int not null default 30,
  plan text not null default 'free' check (plan in ('free', 'paid')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table classrooms enable row level security;

create policy "Teachers can manage own classrooms"
  on classrooms for all using (teacher_id = auth.uid());

create policy "Students can read their classrooms"
  on classrooms for select
  using (
    id in (select classroom_id from classroom_members where user_id = auth.uid())
  );

create policy "Anyone can read by join code"
  on classrooms for select using (true);

-- Classroom members (students)
create table if not exists classroom_members (
  id uuid primary key default gen_random_uuid(),
  classroom_id uuid not null references classrooms(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  role text not null default 'student' check (role in ('student', 'assistant')),
  joined_at timestamptz not null default now(),
  unique (classroom_id, user_id)
);

alter table classroom_members enable row level security;

create policy "Teachers can manage classroom members"
  on classroom_members for all
  using (
    classroom_id in (select id from classrooms where teacher_id = auth.uid())
  );

create policy "Members can read own membership"
  on classroom_members for select
  using (user_id = auth.uid());

-- Curated content assignments
create table if not exists classroom_content (
  id uuid primary key default gen_random_uuid(),
  classroom_id uuid not null references classrooms(id) on delete cascade,
  module_id text not null,
  module_title text not null,
  assigned_at timestamptz not null default now(),
  due_date date,
  assigned_by uuid not null references profiles(id)
);

alter table classroom_content enable row level security;

create policy "Teachers can manage content"
  on classroom_content for all
  using (
    classroom_id in (select id from classrooms where teacher_id = auth.uid())
  );

create policy "Students can read assigned content"
  on classroom_content for select
  using (
    classroom_id in (select classroom_id from classroom_members where user_id = auth.uid())
  );

-- RPC: join classroom by code
create or replace function join_classroom(p_join_code text)
returns uuid language plpgsql security definer as $$
declare
  v_classroom classrooms%rowtype;
  v_count int;
begin
  select * into v_classroom from classrooms
  where join_code = p_join_code and active = true;

  if v_classroom is null then
    raise exception 'Invalid or inactive classroom code';
  end if;

  -- Check capacity
  select count(*) into v_count from classroom_members
  where classroom_id = v_classroom.id;

  if v_count >= v_classroom.max_students then
    raise exception 'Classroom is full';
  end if;

  -- Don't let teacher join as student
  if v_classroom.teacher_id = auth.uid() then
    raise exception 'You are the teacher of this classroom';
  end if;

  -- Add member
  insert into classroom_members (classroom_id, user_id)
  values (v_classroom.id, auth.uid())
  on conflict (classroom_id, user_id) do nothing;

  return v_classroom.id;
end;
$$;
