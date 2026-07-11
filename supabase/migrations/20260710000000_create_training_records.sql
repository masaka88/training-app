-- トレーニング記録テーブル
-- id はアプリ側で生成する UUID（Hive からの移行時に既存 ID を保持するため）。
-- date は「日」の概念なので date 型とし、タイムゾーンによる日付ずれを防ぐ。
create table public.training_records (
  id uuid primary key,
  user_id uuid not null default auth.uid () references auth.users (id) on delete cascade,
  date date not null,
  activity text not null,
  duration text not null,
  comment text,
  location text,
  monthly_count integer not null default 0,
  created_at timestamptz not null default now()
);

-- 所有者のみ読み書き可能（将来のマルチユーザー化ではポリシーの緩和で対応する）
alter table public.training_records enable row level security;

create policy "owner_select" on public.training_records for
select
  using (auth.uid () = user_id);

create policy "owner_insert" on public.training_records for insert
with
  check (auth.uid () = user_id);

create policy "owner_update" on public.training_records
for update
  using (auth.uid () = user_id)
with
  check (auth.uid () = user_id);

create policy "owner_delete" on public.training_records for delete using (auth.uid () = user_id);

-- 一覧表示（新しい日付順）と日付範囲検索のためのインデックス
create index training_records_user_date_idx on public.training_records (user_id, date desc);
