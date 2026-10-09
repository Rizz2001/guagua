---
name: inventory-management-engine
description: |
  Especialista en la lógica de almacén, jerarquías de productos (Cajas/Unidades), protección de costos y compras a proveedores.
  Aplica reglas de negocio sobre el Costo Promedio Ponderado (CPP) y permisos de visualización por roles (RBAC).
---

# Inventory Management Engine (Reglas de Inventario y Costos)

Al desarrollar pantallas o controladores relacionados con el Catálogo, Inventario y Compras, DEBES aplicar las siguientes reglas:

## 🔒 1. Privacidad de Costos y Ganancias (RBAC)
- **Regla Estricta de Visualización:** Nunca se debe mostrar el Costo de Compra (`cost_usd`) ni el Margen de Ganancia a usuarios con el rol `CASHIER`. Estos datos solo son visibles para `ADMIN` o `SUPERVISOR`.
- Renderiza componentes condicionalmente comprobando el rol del usuario en la sesión actual.

## 📦 2. Jerarquía Padre-Hijo (Cajas a Unidades)
- Todo producto puede ser independiente o tener un `parent_box_id`.
- La UI para crear productos debe permitir al usuario marcar un producto como "Unidad detallada" y seleccionar cuál es su "Caja Padre", además de definir cuántas unidades trae (`units_per_box`).
- Jamás permitas que un producto sea su propia caja padre (validación de bucle infinito).

## 📥 3. Compras y Costo Promedio Ponderado (CPP)
- **Prohibido Sobrescribir Costos:** Al ingresar nueva mercancía de un proveedor, el sistema no debe simplemente actualizar el precio de costo a lo loco.
- Se DEBE utilizar obligatoriamente la función RPC de Supabase (`recepcionar_compra_proveedor`) para que el motor SQL recalcule matemáticamente el Costo Promedio Ponderado basándose en el inventario actual y la mercancía entrante.

## 📉 4. Gestión de Mermas (Spoilage)
- La salida de inventario por robo, daño o consumo interno debe registrarse obligatoriamente en la tabla `spoilage_logs` indicando el motivo y quién lo reportó, separándolo completamente de una venta regular.
