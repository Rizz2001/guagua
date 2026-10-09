-- ==============================================================================
-- RPC: crear_producto (Bypass de RLS con SECURITY DEFINER)
-- ==============================================================================
-- Esta función permite la creación atómica de productos sin ser bloqueada por
-- políticas RLS estrictas en el cliente de Flutter.
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.crear_producto(
  p_name TEXT,
  p_code TEXT,
  p_category TEXT,
  p_price_usd NUMERIC(15,2),
  p_cost_usd NUMERIC(15,2) DEFAULT 0.00,
  p_stock INT DEFAULT 0,
  p_min_stock INT DEFAULT 5,
  p_parent_box_id UUID DEFAULT NULL,
  p_units_per_box INT DEFAULT 1
) RETURNS JSONB 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_new_id UUID;
BEGIN
  INSERT INTO public.products (
    name,
    code,
    category,
    price_usd,
    cost_usd,
    stock,
    min_stock,
    parent_box_id,
    units_per_box,
    is_active
  ) VALUES (
    p_name,
    p_code,
    p_category,
    p_price_usd,
    p_cost_usd,
    p_stock,
    p_min_stock,
    p_parent_box_id,
    p_units_per_box,
    true
  )
  RETURNING id INTO v_new_id;

  RETURN jsonb_build_object(
    'success', true,
    'id', v_new_id,
    'message', 'Producto creado exitosamente'
  );
END;
$$;
