-- ==============================================================================
-- GUAGUA ERP - MIGRACIÓN FASE 1 (P0): SEGURIDAD, MULTI-TENANT & AUTORIZACIÓN
-- ==============================================================================

-- 1. TABLA DE EMPRESAS (TENANTS)
CREATE TABLE IF NOT EXISTS public.companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  legal_name TEXT NOT NULL,
  trade_name TEXT NOT NULL,
  rif TEXT NOT NULL UNIQUE,
  address TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT NOT NULL,
  base_currency TEXT NOT NULL DEFAULT 'USD',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;

-- 2. INSERTAR EMPRESA INICIAL POR DEFECTO PARA DATOS HISTÓRICOS
INSERT INTO public.companies (id, legal_name, trade_name, rif, address, phone, email)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Guagua Enterprise C.A.',
  'Guagua POS & ERP',
  'J-50000000-0',
  'Caracas, Venezuela',
  '+584120000000',
  'admin@guaguapos.com'
)
ON CONFLICT (rif) DO NOTHING;

-- 3. TABLA DE MEMBRESÍAS DE USUARIO EN EMPRESAS
CREATE TABLE IF NOT EXISTS public.company_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('ADMIN', 'SUPERVISOR', 'CASHIER', 'WAREHOUSE')),
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, user_id)
);

ALTER TABLE public.company_memberships ENABLE ROW LEVEL SECURITY;

-- 4. VINCULAR PERFILES EXISTENTES A LA EMPRESA PRINCIPAL
INSERT INTO public.company_memberships (company_id, user_id, role, status)
SELECT '00000000-0000-0000-0000-000000000001', p.id, p.role, 'ACTIVE'
FROM public.profiles p
ON CONFLICT (company_id, user_id) DO NOTHING;

-- 5. AGREGAR company_id A TODAS LAS ENTIDADES COMERCIALES
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) DEFAULT '00000000-0000-0000-0000-000000000001';
UPDATE public.products SET company_id = '00000000-0000-0000-0000-000000000001' WHERE company_id IS NULL;

ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) DEFAULT '00000000-0000-0000-0000-000000000001';
UPDATE public.categories SET company_id = '00000000-0000-0000-0000-000000000001' WHERE company_id IS NULL;

ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) DEFAULT '00000000-0000-0000-0000-000000000001';
UPDATE public.clients SET company_id = '00000000-0000-0000-0000-000000000001' WHERE company_id IS NULL;

ALTER TABLE public.debts ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) DEFAULT '00000000-0000-0000-0000-000000000001';
UPDATE public.debts SET company_id = '00000000-0000-0000-0000-000000000001' WHERE company_id IS NULL;

ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) DEFAULT '00000000-0000-0000-0000-000000000001';
UPDATE public.sales SET company_id = '00000000-0000-0000-0000-000000000001' WHERE company_id IS NULL;

ALTER TABLE public.cash_shifts ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) DEFAULT '00000000-0000-0000-0000-000000000001';
UPDATE public.cash_shifts SET company_id = '00000000-0000-0000-0000-000000000001' WHERE company_id IS NULL;

ALTER TABLE public.spoilage_logs ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) DEFAULT '00000000-0000-0000-0000-000000000001';
UPDATE public.spoilage_logs SET company_id = '00000000-0000-0000-0000-000000000001' WHERE company_id IS NULL;

ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) DEFAULT '00000000-0000-0000-0000-000000000001';
UPDATE public.audit_logs SET company_id = '00000000-0000-0000-0000-000000000001' WHERE company_id IS NULL;

ALTER TABLE public.stock_transfers ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) DEFAULT '00000000-0000-0000-0000-000000000001';
UPDATE public.stock_transfers SET company_id = '00000000-0000-0000-0000-000000000001' WHERE company_id IS NULL;

-- 6. FUNCIONES HELPER DE AUTORIZACIÓN (SECURITY DEFINER)
CREATE OR REPLACE FUNCTION public.get_user_company_ids(p_user_id UUID)
RETURNS SETOF UUID AS $$
  SELECT company_id 
  FROM public.company_memberships 
  WHERE user_id = p_user_id AND status = 'ACTIVE';
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.is_company_member(p_company_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.company_memberships
    WHERE company_id = p_company_id AND user_id = p_user_id AND status = 'ACTIVE'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- 7. ENDURECIMIENTO DE POLÍTICAS RLS (CIERRE DE ACCESO PÚBLICO INSEGURO)

-- 7.1 Empresas
DROP POLICY IF EXISTS "Permitir lectura de empresas a miembros" ON public.companies;
CREATE POLICY "Permitir lectura de empresas a miembros" ON public.companies
  FOR SELECT TO authenticated
  USING (id IN (SELECT public.get_user_company_ids(auth.uid())));

-- 7.2 Membresías
DROP POLICY IF EXISTS "Permitir lectura de membresias propias" ON public.company_memberships;
CREATE POLICY "Permitir lectura de membresias propias" ON public.company_memberships
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR company_id IN (SELECT public.get_user_company_ids(auth.uid())));

-- 7.3 Productos
DROP POLICY IF EXISTS "Permitir todo en productos" ON public.products;
CREATE POLICY "Permitir productos de la empresa" ON public.products
  FOR ALL TO authenticated
  USING (company_id IN (SELECT public.get_user_company_ids(auth.uid())))
  WITH CHECK (company_id IN (SELECT public.get_user_company_ids(auth.uid())));

-- 7.4 Categorías
DROP POLICY IF EXISTS "Permitir todo en categorias" ON public.categories;
CREATE POLICY "Permitir categorias de la empresa" ON public.categories
  FOR ALL TO authenticated
  USING (company_id IN (SELECT public.get_user_company_ids(auth.uid())))
  WITH CHECK (company_id IN (SELECT public.get_user_company_ids(auth.uid())));

-- 7.5 Clientes
DROP POLICY IF EXISTS "Permitir todo en clientes" ON public.clients;
CREATE POLICY "Permitir clientes de la empresa" ON public.clients
  FOR ALL TO authenticated
  USING (company_id IN (SELECT public.get_user_company_ids(auth.uid())))
  WITH CHECK (company_id IN (SELECT public.get_user_company_ids(auth.uid())));

-- 7.6 Deudas
DROP POLICY IF EXISTS "Permitir todo en deudas" ON public.debts;
CREATE POLICY "Permitir deudas de la empresa" ON public.debts
  FOR ALL TO authenticated
  USING (company_id IN (SELECT public.get_user_company_ids(auth.uid())))
  WITH CHECK (company_id IN (SELECT public.get_user_company_ids(auth.uid())));

-- 7.7 Ventas
DROP POLICY IF EXISTS "Permitir todo en ventas" ON public.sales;
CREATE POLICY "Permitir ventas de la empresa" ON public.sales
  FOR ALL TO authenticated
  USING (company_id IN (SELECT public.get_user_company_ids(auth.uid())))
  WITH CHECK (company_id IN (SELECT public.get_user_company_ids(auth.uid())));

-- 7.8 Ítems de venta
DROP POLICY IF EXISTS "Permitir todo en items de venta" ON public.sale_items;
CREATE POLICY "Permitir items de venta de la empresa" ON public.sale_items
  FOR ALL TO authenticated
  USING (sale_id IN (SELECT id FROM public.sales WHERE company_id IN (SELECT public.get_user_company_ids(auth.uid()))))
  WITH CHECK (sale_id IN (SELECT id FROM public.sales WHERE company_id IN (SELECT public.get_user_company_ids(auth.uid()))));

-- 7.9 Turnos de caja
DROP POLICY IF EXISTS "Permitir todo en turnos de caja" ON public.cash_shifts;
CREATE POLICY "Permitir turnos de caja de la empresa" ON public.cash_shifts
  FOR ALL TO authenticated
  USING (company_id IN (SELECT public.get_user_company_ids(auth.uid())))
  WITH CHECK (company_id IN (SELECT public.get_user_company_ids(auth.uid())));

-- 7.10 Auditoría
DROP POLICY IF EXISTS "Permitir todo en auditoria" ON public.audit_logs;
CREATE POLICY "Permitir auditoria de la empresa" ON public.audit_logs
  FOR ALL TO authenticated
  USING (company_id IN (SELECT public.get_user_company_ids(auth.uid())))
  WITH CHECK (company_id IN (SELECT public.get_user_company_ids(auth.uid())));

-- 7.11 Transferencias
DROP POLICY IF EXISTS "Permitir todo en transferencias" ON public.stock_transfers;
CREATE POLICY "Permitir transferencias de la empresa" ON public.stock_transfers
  FOR ALL TO authenticated
  USING (company_id IN (SELECT public.get_user_company_ids(auth.uid())))
  WITH CHECK (company_id IN (SELECT public.get_user_company_ids(auth.uid())));

-- 7.12 Mermas
DROP POLICY IF EXISTS "Permitir todo en mermas" ON public.spoilage_logs;
CREATE POLICY "Permitir mermas de la empresa" ON public.spoilage_logs
  FOR ALL TO authenticated
  USING (company_id IN (SELECT public.get_user_company_ids(auth.uid())))
  WITH CHECK (company_id IN (SELECT public.get_user_company_ids(auth.uid())));
