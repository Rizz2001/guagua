-- ==============================================================================
-- GUAGUA POS - MIGRACIÓN ENTERPRISE EDITION
-- ==============================================================================
-- 1. Precios dinámicos y escalas por mayor (price_wholesale_usd, wholesale_min_qty)
-- 2. Soporte para combos promocionales (is_combo)
-- 3. Auditoría anti-fraude con autorización de supervisor (public.audit_logs)
-- 4. Multi-sucursal y transferencias internas de inventario (public.stock_transfers)
-- ==============================================================================

-- 1. Columnas en productos
ALTER TABLE public.products 
  ADD COLUMN IF NOT EXISTS price_wholesale_usd NUMERIC(15,2) CHECK (price_wholesale_usd >= 0),
  ADD COLUMN IF NOT EXISTS wholesale_min_qty INT DEFAULT 6 CHECK (wholesale_min_qty >= 1),
  ADD COLUMN IF NOT EXISTS is_combo BOOLEAN NOT NULL DEFAULT FALSE;

-- 2. Tabla de auditoría anti-fraude
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  action TEXT NOT NULL CHECK (action IN ('VOID_ITEM', 'VOID_CART', 'MANUAL_CASH_DRAWER', 'VOID_SALE', 'PRICE_CHANGE')),
  user_id UUID REFERENCES public.profiles(id),
  supervisor_id UUID REFERENCES public.profiles(id),
  reason TEXT NOT NULL,
  details JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir todo en auditoria" ON public.audit_logs;
CREATE POLICY "Permitir todo en auditoria" ON public.audit_logs 
  FOR ALL TO public USING (true) WITH CHECK (true);

-- 3. Tabla de transferencias multi-sucursal
CREATE TABLE IF NOT EXISTS public.stock_transfers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transfer_number TEXT NOT NULL UNIQUE,
  origin_store TEXT NOT NULL,
  destination_store TEXT NOT NULL,
  product_id UUID NOT NULL REFERENCES public.products(id),
  product_name TEXT NOT NULL,
  quantity INT NOT NULL CHECK (quantity > 0),
  status TEXT NOT NULL DEFAULT 'EN_TRANSITO' CHECK (status IN ('EN_TRANSITO', 'CONFIRMADA', 'CANCELADA')),
  dispatched_by UUID REFERENCES public.profiles(id),
  received_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  confirmed_at TIMESTAMPTZ
);

ALTER TABLE public.stock_transfers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir todo en transferencias" ON public.stock_transfers;
CREATE POLICY "Permitir todo en transferencias" ON public.stock_transfers 
  FOR ALL TO public USING (true) WITH CHECK (true);
