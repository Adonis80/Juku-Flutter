-- GL-1: Referral Engine
-- Unique referral codes, referred_by tracking, Juice + XP rewards

-- Each user gets a unique referral code
create table if not exists referral_codes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references profiles(id) on delete cascade,
  code text not null unique default encode(gen_random_bytes(4), 'hex'),
  created_at timestamptz not null default now()
);

alter table referral_codes enable row level security;

create policy "Users can read own referral code"
  on referral_codes for select using (user_id = auth.uid());

create policy "Anyone can read codes for lookup"
  on referral_codes for select using (true);

-- Referral tracking: who referred whom
create table if not exists referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references profiles(id),
  referred_id uuid not null unique references profiles(id),
  referral_code text not null,
  juice_rewarded boolean not null default false,
  xp_rewarded boolean not null default false,
  created_at timestamptz not null default now()
);

alter table referrals enable row level security;

create policy "Users can read referrals involving them"
  on referrals for select
  using (referrer_id = auth.uid() or referred_id = auth.uid());

-- Referral stats view (for leaderboard)
create or replace view referral_leaderboard as
  select
    r.referrer_id as user_id,
    p.username,
    p.display_name,
    count(*) as total_referrals,
    count(*) filter (where r.juice_rewarded) as rewarded_count
  from referrals r
  join profiles p on p.id = r.referrer_id
  group by r.referrer_id, p.username, p.display_name
  order by total_referrals desc;

-- RPC: claim referral (called when new user signs up with a code)
create or replace function claim_referral(p_referral_code text)
returns void language plpgsql security definer as $$
declare
  v_referrer_id uuid;
begin
  -- Look up referrer
  select user_id into v_referrer_id
  from referral_codes where code = p_referral_code;

  if v_referrer_id is null then
    raise exception 'Invalid referral code';
  end if;

  -- Don't let users refer themselves
  if v_referrer_id = auth.uid() then
    raise exception 'Cannot refer yourself';
  end if;

  -- Check if already referred
  if exists (select 1 from referrals where referred_id = auth.uid()) then
    return; -- Already referred, silently ignore
  end if;

  -- Create referral record
  insert into referrals (referrer_id, referred_id, referral_code)
  values (v_referrer_id, auth.uid(), p_referral_code);

  -- Award 50 Juice to both referrer and referred
  perform credit_juice(v_referrer_id, 50, 'referral_reward');
  perform credit_juice(auth.uid(), 50, 'referral_welcome');

  -- Mark juice as rewarded
  update referrals set juice_rewarded = true
  where referrer_id = v_referrer_id and referred_id = auth.uid();

  -- Award 100 XP to both
  insert into xp_events (user_id, event_type, xp_amount)
  values (v_referrer_id, 'referral', 100);

  insert into xp_events (user_id, event_type, xp_amount)
  values (auth.uid(), 'referral_welcome', 100);

  update referrals set xp_rewarded = true
  where referrer_id = v_referrer_id and referred_id = auth.uid();
end;
$$;

-- RPC: ensure current user has a referral code (creates one if not exists)
create or replace function ensure_referral_code()
returns text language plpgsql security definer as $$
declare
  v_code text;
begin
  select code into v_code from referral_codes where user_id = auth.uid();

  if v_code is null then
    insert into referral_codes (user_id)
    values (auth.uid())
    returning code into v_code;
  end if;

  return v_code;
end;
$$;
