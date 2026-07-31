-- 在 Supabase Dashboard 的 SQL Editor 中完整执行本文件。
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 1 and 40),
  created_at timestamptz not null default now(),
  user_id uuid not null default auth.uid()
);
create unique index if not exists categories_user_name_key on public.categories(user_id, lower(name));

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid(),
  name text not null check (char_length(trim(name)) between 1 and 80),
  category_id uuid references public.categories(id) on delete set null,
  cost_price numeric(12,2) not null check (cost_price >= 0),
  sale_price numeric(12,2) not null check (sale_price >= 0),
  quantity integer not null default 0 check (quantity >= 0),
  low_stock_threshold integer not null default 0 check (low_stock_threshold >= 0),
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.inventory_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid(),
  product_id uuid not null references public.products(id) on delete cascade,
  action text not null check (action in ('restock','sale','loss','stocktake')),
  quantity_change integer not null,
  quantity_before integer not null check (quantity_before >= 0),
  quantity_after integer not null check (quantity_after >= 0),
  notes text not null default '',
  created_at timestamptz not null default now()
);

alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.inventory_records enable row level security;
create policy "own categories" on public.categories for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own products" on public.products for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own records" on public.inventory_records for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- RLS 负责“只能看自己的数据”；下面的权限允许已登录用户通过 API 使用这些表。
grant usage on schema public to authenticated;
grant select, insert, update, delete on table public.categories, public.products, public.inventory_records to authenticated;

create or replace function public.adjust_inventory(p_product_id uuid, p_action text, p_value integer, p_notes text default '')
returns public.products language plpgsql security invoker as $$
declare p public.products; after_qty integer; change_qty integer;
begin
  select * into p from public.products where id = p_product_id and user_id = auth.uid() for update;
  if not found then raise exception '商品不存在或无权操作'; end if;
  if p_action = 'stocktake' then after_qty := p_value; change_qty := p_value - p.quantity;
  elsif p_action = 'restock' then after_qty := p.quantity + p_value; change_qty := p_value;
  elsif p_action in ('sale','loss') then after_qty := p.quantity - p_value; change_qty := -p_value;
  else raise exception '无效的库存操作'; end if;
  if p_value < 0 or after_qty < 0 then raise exception '库存数量不能为负数'; end if;
  update public.products set quantity = after_qty, updated_at = now() where id = p.id returning * into p;
  insert into public.inventory_records(product_id, action, quantity_change, quantity_before, quantity_after, notes)
  values (p.id, p_action, change_qty, p.quantity - change_qty, after_qty, coalesce(p_notes,''));
  return p;
end; $$;

grant execute on function public.adjust_inventory(uuid, text, integer, text) to authenticated;
