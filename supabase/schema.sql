/* 
==============================================================================
GUAGUA POS - ESQUEMA DE BASE DE DATOS SUPABASE (POSTGRESQL)
==============================================================================
Este script crea la estructura de tablas, funciones RPC atómicas y políticas RLS
para el sistema Guagua POS (Multimoneda, Tasa BCV, CPP, Roles RBAC, Crédito y Cajas).
Copia y ejecuta este script en el SQL Editor de tu proyecto en Supabase.
==============================================================================
*/

-- 1. TABLA DE ROLES Y PERFILES DE USUARIO (RBAC)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('ADMIN', 'SUPERVISOR', 'CASHIER', 'WAREHOUSE')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 2. TABLA DE HISTORIAL DE TASAS DE CAMBIO (BCV / PARALELO)
CREATE TABLE IF NOT EXISTS public.store_exchange_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rate_bcv NUMERIC(15,4) NOT NULL CHECK (rate_bcv > 0),
  effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
  updated_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.store_exchange_rates ENABLE ROW LEVEL SECURITY;

-- Insertar tasa inicial por defecto (36.50 Bs/USD)
INSERT INTO public.store_exchange_rates (rate_bcv) 
VALUES (36.5000)
ON CONFLICT DO NOTHING;

-- 3. CATEGORÍAS Y PRODUCTOS (COMBOS, UNIDADES Y COSTO PROMEDIO PONDERADO CPP)
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  price_usd NUMERIC(15,2) NOT NULL CHECK (price_usd >= 0),
  price_wholesale_usd NUMERIC(15,2) CHECK (price_wholesale_usd >= 0),
  wholesale_min_qty INT DEFAULT 6 CHECK (wholesale_min_qty >= 1),
  cost_usd NUMERIC(15,2) NOT NULL DEFAULT 0.00 CHECK (cost_usd >= 0),
  stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
  min_stock INT NOT NULL DEFAULT 5 CHECK (min_stock >= 0),
  parent_box_id UUID REFERENCES public.products(id),
  units_per_box INT NOT NULL DEFAULT 1 CHECK (units_per_box >= 1),
  is_combo BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- 4. CLIENTES Y GESTIÓN DE CRÉDITO (CUENTAS POR COBRAR)
CREATE TABLE IF NOT EXISTS public.clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  document_id TEXT NOT NULL UNIQUE,
  phone TEXT NOT NULL,
  credit_limit NUMERIC(15,2) NOT NULL DEFAULT 100.00 CHECK (credit_limit >= 0),
  current_debt NUMERIC(15,2) NOT NULL DEFAULT 0.00 CHECK (current_debt >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.debts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES public.clients(id) ON DELETE CASCADE,
  sale_id UUID,
  total_amount_usd NUMERIC(15,2) NOT NULL CHECK (total_amount_usd > 0),
  pending_amount_usd NUMERIC(15,2) NOT NULL CHECK (pending_amount_usd >= 0),
  is_paid BOOLEAN NOT NULL DEFAULT FALSE,
  due_date DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.debts ENABLE ROW LEVEL SECURITY;

-- 5. TURNO DE CAJA Y ARQUEO (CIERRE X / Z)
CREATE TABLE IF NOT EXISTS public.cash_shifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cashier_id UUID NOT NULL REFERENCES public.profiles(id),
  opening_fund_usd NUMERIC(15,2) NOT NULL DEFAULT 50.00,
  cash_usd_expected NUMERIC(15,2) NOT NULL DEFAULT 0.00,
  cash_bs_expected NUMERIC(15,2) NOT NULL DEFAULT 0.00,
  pago_movil_bs_expected NUMERIC(15,2) NOT NULL DEFAULT 0.00,
  zelle_usd_expected NUMERIC(15,2) NOT NULL DEFAULT 0.00,
  cash_usd_actual NUMERIC(15,2),
  cash_bs_actual NUMERIC(15,2),
  difference_usd NUMERIC(15,2),
  status TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLOSED')),
  opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  closed_at TIMESTAMPTZ
);
ALTER TABLE public.cash_shifts ENABLE ROW LEVEL SECURITY;

-- 6. VENTAS Y DETALLE DE ÍTEMS (MULTIMONEDA Y CONGELACIÓN DE TASA DEL DÍA)
CREATE TABLE IF NOT EXISTS public.sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number TEXT NOT NULL UNIQUE,
  cashier_id UUID NOT NULL REFERENCES public.profiles(id),
  client_id UUID REFERENCES public.clients(id),
  total_usd NUMERIC(15,2) NOT NULL CHECK (total_usd >= 0),
  exchange_rate NUMERIC(15,4) NOT NULL,
  payment_method TEXT NOT NULL,
  payment_details JSONB,
  status TEXT NOT NULL DEFAULT 'COMPLETED' CHECK (status IN ('COMPLETED', 'VOIDED')),
  shift_id UUID REFERENCES public.cash_shifts(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.sale_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id UUID NOT NULL REFERENCES public.sales(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id),
  product_name TEXT NOT NULL,
  quantity INT NOT NULL CHECK (quantity > 0),
  unit_price_usd NUMERIC(15,2) NOT NULL CHECK (unit_price_usd >= 0),
  unit_price_bs NUMERIC(15,2) NOT NULL DEFAULT 0.00 CHECK (unit_price_bs >= 0),
  subtotal_usd NUMERIC(15,2) NOT NULL CHECK (subtotal_usd >= 0)
);
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;

-- 7. REGISTRO DE MERMAS Y DEVOLUCIONES
CREATE TABLE IF NOT EXISTS public.spoilage_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES public.products(id),
  product_name TEXT NOT NULL,
  quantity INT NOT NULL CHECK (quantity > 0),
  reason TEXT NOT NULL,
  reported_by UUID NOT NULL REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.spoilage_logs ENABLE ROW LEVEL SECURITY;

-- 8. AUDITORÍA ANTI-FRAUDE (AUTORIZACIÓN DE SUPERVISOR)
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

-- 9. MULTI-SUCURSAL Y TRANSFERENCIAS INTERNAS DE MERCANCÍA
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

-- ==============================================================================
-- FUNCIONES RPC ATÓMICAS (LÓGICA FINANCIERA Y OPERATIVA EN POSTGRESQL)
-- ==============================================================================

-- RPC 1: Actualizar Tasa Diaria BCV (Solo ADMIN o SUPERVISOR)
CREATE OR REPLACE FUNCTION public.actualizar_tasa_diaria(
  p_rate_bcv NUMERIC(15,4),
  p_user_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_role TEXT;
BEGIN
  SELECT role INTO v_role FROM public.profiles WHERE id = p_user_id;

  IF v_role NOT IN ('ADMIN', 'SUPERVISOR') THEN
    RAISE EXCEPTION 'Acceso denegado: Solo Administradores o Supervisores pueden cambiar la tasa oficial.';
  END IF;

  INSERT INTO public.store_exchange_rates (rate_bcv, effective_date, updated_by, created_at)
  VALUES (p_rate_bcv, CURRENT_DATE, p_user_id, NOW());

  RETURN jsonb_build_object('success', true, 'rate_bcv', p_rate_bcv, 'message', 'Tasa oficial actualizada correctamente');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC 2: Obtener Tasa Activa del Día
CREATE OR REPLACE FUNCTION public.obtener_tasa_activa()
RETURNS NUMERIC(15,4) AS $$
DECLARE
  v_rate NUMERIC(15,4);
BEGIN
  SELECT rate_bcv INTO v_rate 
  FROM public.store_exchange_rates 
  ORDER BY created_at DESC 
  LIMIT 1;

  RETURN COALESCE(v_rate, 36.5000);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC 3: Desarmar Caja a Unidades Automáticamente si el Stock de Unidades es Insuficiente
CREATE OR REPLACE FUNCTION public.desarmar_caja_si_es_necesario(
  p_product_id UUID,
  p_qty_needed INT
) RETURNS VOID AS $$
DECLARE
  v_unit_stock INT;
  v_parent_box_id UUID;
  v_units_per_box INT;
BEGIN
  SELECT stock, parent_box_id, units_per_box INTO v_unit_stock, v_parent_box_id, v_units_per_box
  FROM public.products WHERE id = p_product_id FOR UPDATE;

  IF v_unit_stock < p_qty_needed AND v_parent_box_id IS NOT NULL THEN
    UPDATE public.products SET stock = stock - 1 WHERE id = v_parent_box_id AND stock >= 1;
    UPDATE public.products SET stock = stock + v_units_per_box WHERE id = p_product_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC 4: Recepción de Compra a Proveedor y Recálculo de Costo Promedio Ponderado (CPP)
CREATE OR REPLACE FUNCTION public.recepcionar_compra_proveedor(
  p_supplier_name TEXT,
  p_user_id UUID,
  p_items JSONB
) RETURNS JSONB AS $$
DECLARE
  v_item JSONB;
  v_current_stock INT;
  v_current_cost NUMERIC(15,2);
  v_new_qty INT;
  v_new_cost_usd NUMERIC(15,2);
BEGIN
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    SELECT stock, cost_usd INTO v_current_stock, v_current_cost 
    FROM public.products WHERE id = (v_item->>'product_id')::UUID FOR UPDATE;

    v_new_qty := (v_item->>'qty_bought')::INT;

    IF (v_current_stock + v_new_qty) > 0 THEN
      v_new_cost_usd := ( (v_current_stock * v_current_cost) + (v_new_qty * (v_item->>'unit_cost_usd')::NUMERIC) ) / (v_current_stock + v_new_qty);
    ELSE
      v_new_cost_usd := (v_item->>'unit_cost_usd')::NUMERIC;
    END IF;

    UPDATE public.products 
    SET stock = stock + v_new_qty, cost_usd = v_new_cost_usd, updated_at = NOW()
    WHERE id = (v_item->>'product_id')::UUID;
  END LOOP;

  RETURN jsonb_build_object('success', true, 'message', 'Recepcion de mercancía y recálculo de CPP completados.');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC 5: Validar Cupo de Crédito de Cliente
CREATE OR REPLACE FUNCTION public.validar_cupo_credito(
  p_client_id UUID,
  p_new_sale_usd NUMERIC(15,2)
) RETURNS BOOLEAN AS $$
DECLARE
  v_credit_limit NUMERIC(15,2);
  v_current_debt NUMERIC(15,2);
BEGIN
  SELECT credit_limit INTO v_credit_limit FROM public.clients WHERE id = p_client_id;
  
  SELECT COALESCE(SUM(pending_amount_usd), 0) INTO v_current_debt 
  FROM public.debts 
  WHERE client_id = p_client_id AND is_paid = false;

  IF (v_current_debt + p_new_sale_usd) > v_credit_limit THEN
    RAISE EXCEPTION 'La venta excede el límite de crédito disponible del cliente (Límite: $%, Deuda Actual: $%)', v_credit_limit, v_current_debt;
  END IF;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================================================
-- POLÍTICAS ROW LEVEL SECURITY (RLS)
-- ==============================================================================

DO $$
BEGIN
  -- Se usaba un bloque DO, pero es mejor usar sentencias directas para evitar errores de parseo en Supabase.
END $$;

DROP POLICY IF EXISTS "Permitir lectura de perfiles" ON public.profiles;
CREATE POLICY "Permitir lectura de perfiles" ON public.profiles FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Permitir lectura de tasas" ON public.store_exchange_rates;
CREATE POLICY "Permitir lectura de tasas" ON public.store_exchange_rates FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Permitir todo en productos" ON public.products;
CREATE POLICY "Permitir todo en productos" ON public.products FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir todo en categorias" ON public.categories;
CREATE POLICY "Permitir todo en categorias" ON public.categories FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir todo en clientes" ON public.clients;
CREATE POLICY "Permitir todo en clientes" ON public.clients FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir todo en deudas" ON public.debts;
CREATE POLICY "Permitir todo en deudas" ON public.debts FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir todo en turnos de caja" ON public.cash_shifts;
CREATE POLICY "Permitir todo en turnos de caja" ON public.cash_shifts FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir todo en ventas" ON public.sales;
CREATE POLICY "Permitir todo en ventas" ON public.sales FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir todo en items de venta" ON public.sale_items;
CREATE POLICY "Permitir todo en items de venta" ON public.sale_items FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir todo en mermas" ON public.spoilage_logs;
CREATE POLICY "Permitir todo en mermas" ON public.spoilage_logs FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir todo en auditoria" ON public.audit_logs;
CREATE POLICY "Permitir todo en auditoria" ON public.audit_logs FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir todo en transferencias" ON public.stock_transfers;
CREATE POLICY "Permitir todo en transferencias" ON public.stock_transfers FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Solo Admin/Supervisor modifica tasa" ON public.store_exchange_rates;
CREATE POLICY "Solo Admin/Supervisor modifica tasa" ON public.store_exchange_rates
  FOR INSERT TO authenticated WITH CHECK (
    (SELECT role FROM public.profiles WHERE id = auth.uid()) IN ('ADMIN', 'SUPERVISOR')
  );
