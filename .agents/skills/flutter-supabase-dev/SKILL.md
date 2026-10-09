---
name: flutter-supabase-dev
description: |
  Experto en desarrollo Flutter y Supabase para sistemas POS y financieros. Incluye transacciones atómicas PostgreSQL (RPC),
  sincronización Offline-First (Hive/Isar -> Outbox Queue), cálculo multimoneda (USD/VES) y vueltos mixtos, gestión manual diaria de tasa BCV,
  impresión térmica (ESC/POS 58/80mm), arqueo de caja (Cierre X/Z con fondo inicial), lectores de código de barras (PC/Android), auditoría anti-fraude, 
  combos/desarmado de cajas, precios dinámicos, compras a proveedores (CPP), roles RBAC, control de mermas/lotes, cobro por WhatsApp, analíticas de liquidez (VIEWS) y CI/CD.

  Cuándo usar:
  - Al escribir funciones RPC y Vistas SQL (`VIEW`) en PostgreSQL para actualización manual diaria de tasa de cambio (BCV/Paralelo), compras (CPP) y ventas.
  - Al implementar la matriz de roles RBAC (`admin`, `supervisor`, `cashier`, `warehouse`) y políticas RLS por rol.
  - Al validar cupo de crédito (`credit_limit`), registrar abonos parciales y separar Dinero en Caja vs Deuda.
  - Al implementar la arquitectura Offline-First con almacenamiento local (Hive/Isar) y cola de sincronización.
  - Al programar la lógica de cobro multimoneda (efectivo USD, Pago Móvil, Zelle) y calculadora de vueltos con la tasa activa del día.
  - Al integrar mensajes dinámicos y enlaces directos de WhatsApp (`url_launcher`) para envío de recibos digitales y cobro de deudas.
  - Al consultar métricas de liquidez precalculadas (Capital en la Calle, Índice de Morosidad %).
  - Al configurar flujos de CI/CD para Flutter Web, Windows y generación de APK de Android.
---

# Flutter & Supabase POS Developer (Technical Engine Guide)

Esta skill guía la construcción técnica de aplicaciones POS y financieras multiplataforma (Android, Windows, Web) utilizando **Flutter** y **Supabase (PostgreSQL)**.

---

## 💱 1. `daily-exchange-rate-management` (Gestión Manual Diaria de Tasa BCV/Paralelo)

### Tabla de Tasas e Historización (`store_exchange_rates`)
```sql
CREATE TABLE IF NOT EXISTS public.store_exchange_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rate_bcv NUMERIC(15,4) NOT NULL,
  effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
  updated_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RPC para que el Administrador/Supervisor actualice la Tasa del Día
CREATE OR REPLACE FUNCTION public.actualizar_tasa_diaria(
  p_rate_bcv NUMERIC(15,4),
  p_user_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_role TEXT;
BEGIN
  SELECT role INTO v_role FROM public.users WHERE id = p_user_id;

  IF v_role NOT IN ('ADMIN', 'SUPERVISOR') THEN
    RAISE EXCEPTION 'Solo Administradores o Supervisores pueden cambiar la tasa de cambio de la tienda';
  END IF;

  INSERT INTO public.store_exchange_rates (rate_bcv, effective_date, updated_by, created_at)
  VALUES (p_rate_bcv, CURRENT_DATE, p_user_id, NOW());

  RETURN jsonb_build_object('success', true, 'rate_bcv', p_rate_bcv, 'message', 'Tasa diaria actualizada correctamente');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función RPC para obtener la Tasa Activa actual del Sistema
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
```

---

## 📦 2. `inventory-units-and-combos` (Desarmado Automático de Cajas)

```sql
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
```

---

## 🛒 3. `supplier-purchase-engine` (Recepciones de Compra & CPP)

```sql
CREATE OR REPLACE FUNCTION public.recepcionar_compra_proveedor(
  p_supplier_id UUID,
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
    SET stock = stock + v_new_qty, cost_usd = v_new_cost_usd
    WHERE id = (v_item->>'product_id')::UUID;
  END LOOP;

  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 👥 4. `multi-user-rbac-security` (Roles RBAC y RLS)

```sql
CREATE POLICY "Solo Administradores y Supervisores ven Costos de Compra"
ON public.products
FOR SELECT
TO authenticated
USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) IN ('ADMIN', 'SUPERVISOR')
  OR current_setting('request.jwt.claims', true)::json->>'role' = 'service_role'
);
```

---

## 🏦 5. `credit-sales-cashflow` (Límite de Crédito & Abonos)

```sql
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
    RAISE EXCEPTION 'La venta excede el límite de crédito del cliente';
  END IF;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## ⚠️ Reglas Obligatorias de Backend POS

1. **Gestión de Tasa Diaria:** La tasa oficial del día (BCV/Paralelo) se actualiza de forma manual y centralizada. Solo usuarios con rol Admin/Supervisor pueden cambiarla.
2. **Historización:** Cada transacción guarda su tasa congelada en el momento de la venta.
3. **Costo Promedio Ponderado (CPP):** Toda recepción de compra recalcula el costo unitario atómicamente en PostgreSQL.
4. **Modificación Automática de Base de Datos:** Cada vez que se requiera o se identifique la necesidad de modificar algo en la base de datos (nuevas tablas, columnas, políticas RLS, funciones RPC, etc.), el agente DEBE actualizar el código y los scripts SQL correspondientes (como `supabase/schema.sql`) de forma completamente AUTOMÁTICA, sin esperar confirmación explícita para cada cambio.
