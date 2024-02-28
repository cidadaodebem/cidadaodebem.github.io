drop table if exists user_boards;
drop table if exists cards;
drop table if exists lists;
drop table if exists boards;
drop table if exists users;

-- Create boards table
create table boards (
  id bigint generated by default as identity primary key,
  creator uuid references auth.users not null default auth.uid(),
  title text default 'Untitled Board',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create lists table
create table lists (
  id bigint generated by default as identity primary key,
  board_id bigint references boards ON DELETE CASCADE not null,
  title text default '',
  position int not null default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create Cards table
create table cards (
  id bigint generated by default as identity primary key,
  list_id bigint references lists ON DELETE CASCADE not null,
  board_id bigint references boards ON DELETE CASCADE not null,
  position int not null default 0,
  title text default '',
  description text check (char_length(description) > 0),
  assigned_to uuid references auth.users,
  done boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Many to many table for user <-> boards relationship
create table user_boards (
  id bigint generated by default as identity primary key,
  user_id uuid references auth.users ON DELETE CASCADE not null default auth.uid(),
  board_id bigint references boards ON DELETE CASCADE
);

-- User ID lookup table
create table users (
  id uuid not null primary key,
  email text
);

-- Make sure deleted records are included in realtime
alter table cards replica identity full;
alter table lists replica identity full;

-- Function to get all user boards
create or replace function get_boards_for_authenticated_user()
returns setof bigint
language sql
security definer
set search_path = public
stable
as $$
    select board_id
    from user_boards
    where user_id = auth.uid()
$$;