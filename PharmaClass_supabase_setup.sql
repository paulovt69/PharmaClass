-- PharmaClass 3.0 — execute no SQL Editor do projeto Supabase.
-- Use somente a chave publishable/anon no frontend. Nunca exponha service_role.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Estudante',
  role text not null default 'student' check (role in ('student','teacher')),
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles for select to authenticated using (auth.uid() = id);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name, role)
  values (new.id, coalesce(nullif(new.raw_user_meta_data ->> 'display_name',''), 'Estudante'), 'student');
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.is_pharmaclass_teacher()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'teacher');
$$;

create table if not exists public.lessons (
  id text primary key,
  title text not null,
  subject text not null default '',
  description text not null default '',
  published boolean not null default false,
  content jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now()
);
alter table public.lessons enable row level security;
drop policy if exists "lessons_read_published_or_teacher" on public.lessons;
create policy "lessons_read_published_or_teacher" on public.lessons for select to authenticated
using (published = true or public.is_pharmaclass_teacher());
drop policy if exists "lessons_teacher_insert" on public.lessons;
create policy "lessons_teacher_insert" on public.lessons for insert to authenticated
with check (public.is_pharmaclass_teacher());
drop policy if exists "lessons_teacher_update" on public.lessons;
create policy "lessons_teacher_update" on public.lessons for update to authenticated
using (public.is_pharmaclass_teacher()) with check (public.is_pharmaclass_teacher());
drop policy if exists "lessons_teacher_delete" on public.lessons;
create policy "lessons_teacher_delete" on public.lessons for delete to authenticated
using (public.is_pharmaclass_teacher());

create table if not exists public.student_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id text not null references public.lessons(id) on delete cascade,
  slide_ids jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, lesson_id)
);
alter table public.student_progress enable row level security;
drop policy if exists "progress_read_own" on public.student_progress;
create policy "progress_read_own" on public.student_progress for select to authenticated
using (auth.uid() = user_id);
drop policy if exists "progress_insert_own" on public.student_progress;
create policy "progress_insert_own" on public.student_progress for insert to authenticated
with check (auth.uid() = user_id);
drop policy if exists "progress_update_own" on public.student_progress;
create policy "progress_update_own" on public.student_progress for update to authenticated
using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "progress_delete_own" on public.student_progress;
create policy "progress_delete_own" on public.student_progress for delete to authenticated
using (auth.uid() = user_id);

-- Aula inicial de exemplo compartilhada após a execução deste script.
insert into public.lessons (id,title,subject,description,published,content)
values (
 'lesson-intro','Fundamentos de Farmacologia','Farmacologia',
 'Conceitos iniciais, ADME e uso racional de medicamentos.',true,
 '{"id":"lesson-intro","title":"Fundamentos de Farmacologia","subject":"Farmacologia","description":"Conceitos iniciais, ADME e uso racional de medicamentos.","videoUrl":"","videoBlobKey":"","published":true,"slides":[{"id":"s1","title":"O que é Farmacologia?","body":"A farmacologia estuda como os fármacos interagem com os sistemas biológicos. Diferencie fármaco, medicamento, indicação e efeito terapêutico.","bullets":["Farmacocinética: o que o organismo faz com o fármaco","Farmacodinâmica: o que o fármaco faz no organismo","Segurança: benefício, risco e uso racional"],"imageKey":"","question":"Qual área estuda absorção, distribuição, metabolismo e excreção?","options":["Farmacodinâmica","Farmacocinética","Farmacognosia"],"correct":1,"explanation":"Farmacocinética abrange ADME."},{"id":"s2","title":"Farmacocinética: ADME","body":"ADME resume quatro processos que influenciam a concentração de um fármaco no organismo.","bullets":["Absorção: entrada na circulação","Distribuição: deslocamento entre sangue e tecidos","Metabolismo: transformação química","Excreção: remoção do organismo"],"imageKey":"","question":"Qual opção representa corretamente ADME?","options":["Absorção, distribuição, metabolismo e excreção","Aplicação, dose, medição e efeito","Ação, diluição, mistura e eliminação"],"correct":0,"explanation":"ADME corresponde a absorção, distribuição, metabolismo e excreção."}]} '::jsonb
)
on conflict (id) do nothing;

-- Depois de cadastrar e confirmar a conta do professor, promova-a manualmente:
-- update public.profiles p set role='teacher'
-- from auth.users u where p.id=u.id and u.email='professor@escola.edu.br';
-- Execute essa promoção apenas após verificar a identidade com a escola.
