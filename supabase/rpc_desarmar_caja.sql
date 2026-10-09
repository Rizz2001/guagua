-- Función RPC: desarmar_caja_si_es_necesario
-- Objetivo: Si al procesar una venta, el stock de unidades es menor al necesario,
-- automáticamente buscar si hay cajas disponibles (stock > 0). Si hay, descontar
-- 1 caja, sumar las unidades correspondientes a esa caja y continuar.

CREATE OR REPLACE FUNCTION public.desarmar_caja_si_es_necesario(
    p_product_id uuid,
    p_qty_needed integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_stock_unidades integer;
    v_cajas_disponibles integer;
    v_unidades_por_caja integer;
    v_parent_box_id uuid;
BEGIN
    -- 1. Leer el estado actual del producto (unidades)
    SELECT stock, parent_box_id
    INTO v_stock_unidades, v_parent_box_id
    FROM public.products
    WHERE id = p_product_id;

    -- Si hay suficiente stock de unidades, no hacemos nada (el trigger o backend normal descontará)
    IF v_stock_unidades >= p_qty_needed THEN
        RETURN;
    END IF;

    -- Si NO hay suficiente stock de unidades pero el producto NO tiene un id de caja padre asociado,
    -- tampoco podemos hacer nada (quedará en stock negativo, manejado por la app).
    IF v_parent_box_id IS NULL THEN
        RETURN;
    END IF;

    -- 2. Verificar disponibilidad de la caja padre
    SELECT stock, units_per_box
    INTO v_cajas_disponibles, v_unidades_por_caja
    FROM public.products
    WHERE id = v_parent_box_id;

    -- Si no hay cajas disponibles, no se puede desarmar
    IF v_cajas_disponibles <= 0 THEN
        RETURN;
    END IF;

    -- Si hay al menos 1 caja, procedemos a desarmarla
    -- OJO: Esto asume que se desarma 1 sola caja. Si la venta requiere muchísimas unidades
    -- habría que calcular cuántas cajas desarmar, pero para el flujo común 1 caja es suficiente.
    
    -- 3. Transacción Atómica
    -- Restar 1 al stock de cajas
    UPDATE public.products
    SET stock = stock - 1
    WHERE id = v_parent_box_id;

    -- Sumar las unidades al stock individual (antes de que la venta descuente)
    UPDATE public.products
    SET stock = stock + v_unidades_por_caja
    WHERE id = p_product_id;

END;
$$;
