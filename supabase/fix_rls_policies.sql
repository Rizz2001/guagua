-- ==============================================================================
-- SOLUCIÓN ERROR DE SEGURIDAD RLS (Row-Level Security) EN SUPABASE
-- ==============================================================================
-- Ejecuta este script en el SQL Editor de tu Dashboard de Supabase para
-- permitir que la app pueda crear/actualizar productos, registrar ventas y mermas.
-- ==============================================================================

-- 1. PRODUCTOS
DROP POLICY IF EXISTS "Permitir todo en productos" ON public.products;
CREATE POLICY "Permitir todo en productos" ON public.products 
FOR ALL 
TO public 
USING (true) 
WITH CHECK (true);

-- 2. VENTAS E ÍTEMS
DROP POLICY IF EXISTS "Permitir todo en ventas" ON public.sales;
CREATE POLICY "Permitir todo en ventas" ON public.sales 
FOR ALL 
TO public 
USING (true) 
WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir todo en items de venta" ON public.sale_items;
CREATE POLICY "Permitir todo en items de venta" ON public.sale_items 
FOR ALL 
TO public 
USING (true) 
WITH CHECK (true);

-- 3. LOGS DE MERMAS
DROP POLICY IF EXISTS "Permitir todo en mermas" ON public.spoilage_logs;
CREATE POLICY "Permitir todo en mermas" ON public.spoilage_logs 
FOR ALL 
TO public 
USING (true) 
WITH CHECK (true);

-- 4. CLIENTES Y CRÉDITOS
DROP POLICY IF EXISTS "Permitir todo en clientes" ON public.clients;
CREATE POLICY "Permitir todo en clientes" ON public.clients 
FOR ALL 
TO public 
USING (true) 
WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir todo en deudas" ON public.debts;
CREATE POLICY "Permitir todo en deudas" ON public.debts 
FOR ALL 
TO public 
USING (true) 
WITH CHECK (true);

-- 5. CAJAS Y TURNOS
DROP POLICY IF EXISTS "Permitir todo en turnos de caja" ON public.cash_shifts;
CREATE POLICY "Permitir todo en turnos de caja" ON public.cash_shifts 
FOR ALL 
TO public 
USING (true) 
WITH CHECK (true);
