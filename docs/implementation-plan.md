# 🗺️ Plan Maestro de Implementación ERP: Fases y Entregables

**Metodología:** Iteraciones atómicas, seguras y verificables (Skill `erp-venezuela-flutter-supabase`).

---

## 📌 Resumen de Fases

```mermaid
graph TD
    P0[Fase 1: Fundamentos de Seguridad, Multi-Tenant & Auth (P0)] --> P1A[Fase 2: Catálogos Core (Empresas, Proveedores, Clientes, Productos) (P1)]
    P1A --> P1B[Fase 3: Inventario Transaccional & Kardex (P1)]
    P1B --> P1C[Fase 4: Ventas Atómicas, Presupuestos & Outbox Seguro (P1)]
    P1C --> P1D[Fase 5: Cuentas por Cobrar/Pagar, Gastos & Caja (P1)]
    P1D --> P2A[Fase 6: Marco Fiscal Documental & Puerta SENIAT (P2)]
    P2A --> P2B[Fase 7: Reportes Multidimensionales & Hardening (P2)]
```

---

## 📋 Detalle de Fases de Trabajo

### 🔴 FASE 1: Fundamentos de Seguridad, Multi-Tenant & Auth Robusta (P0) — *EN EJECUCIÓN*
- **Objetivo:** Blindar la base de datos, implementar aislamiento multi-empresa real y cerrar políticas RLS abiertas.
- **Entregables:**
  - Migración SQL `20261013000000_erp_core_multitenant_auth.sql`:
    - Creación de tabla `public.companies` y `public.company_memberships`.
    - Registro de empresa por defecto `Guagua Enterprise C.A.` para datos históricos.
    - Columna `company_id` en todas las tablas transaccionales existentes con migración de datos limpia.
    - Funciones helper de seguridad: `get_user_company_ids` y `is_company_member`.
    - Reemplazo total de políticas RLS `USING (true)` por políticas estrictas `TO authenticated` restringidas a la empresa activa.
  - Modelos Flutter:
    - `CompanyModel` y `CompanyMembershipModel`.
  - Controladores Flutter:
    - `CompanyController` para contexto global de empresa activa.
    - Actualización de `AuthController` para cargar membresías y empresa en la sesión.
  - Header adaptativo con selector/indicador de empresa activa y rol.
  - Tests automatizados de aislamiento y autenticación.

---

### 🟡 FASE 2: Catálogos Core ERP (P1)
- **Objetivo:** Estructurar maestros comerciales formales.
- **Entregables:**
  - Creación de tabla `public.suppliers` con RIF, dirección fiscal, teléfono, condiciones de pago.
  - Modelo `SupplierModel` y refactorización de `supplier_purchases_screen.dart` para enlazar proveedores reales.
  - Separación en `products` de SKU vs Código de barras y tipo de producto (`bien` vs `servicio`).
  - Creación de tabla `units_of_measure` (Unidades, Cajas, Kilos, Litros).

---

### 🟡 FASE 3: Inventario Transaccional & Kardex (P1)
- **Objetivo:** Trazabilidad absoluta de inventario.
- **Entregables:**
  - Creación de tabla `public.stock_movements` (Kardex: fecha, producto, cantidad, costo unitario, tipo de movimiento, documento origen, usuario).
  - Recálculo de Costo Promedio Ponderado (CPP) registrado en el Kardex al recibir compras de proveedores.
  - Pantalla de consulta de Kardex por producto y rango de fechas.

---

### 🟡 FASE 4: Ventas Atómicas, Presupuestos & Outbox Idempotente (P1)
- **Objetivo:** Cero inconsistencias en ventas y soporte para cotizaciones.
- **Entregables:**
  - Función RPC `registrar_venta_atomica_v2` con clave de idempotencia (`idempotency_key`), inserción atómica de ítems y actualización de stock.
  - Refactorización de `OutboxService` para enviar la venta completa en un solo llamado RPC atómico.
  - Módulo de **Presupuestos / Cotizaciones** (ventas en borrador que no descuentan stock ni crean deudas).
  - Conversión de presupuesto a venta en un toque.

---

### 🟡 FASE 5: Finanzas: Cuentas por Cobrar/Pagar, Gastos & Caja (P1)
- **Objetivo:** Control total del flujo de caja comercial.
- **Entregables:**
  - Cuentas por pagar a proveedores derivadas de recepciones de mercancía.
  - Módulo de **Gastos Operativos** (`expenses`) clasificados por categoría con pago directo desde la caja activa.
  - Conciliación de arqueo de caja con desglose de gastos y cobranzas.

---

### 🟢 FASE 6: Marco Fiscal Documental & Puerta SENIAT (P2)
- **Objetivo:** Cumplimiento normativo estricto sin falsas declaraciones.
- **Entregables:**
  - Lista de verificación en `docs/fiscal-compliance-checklist.md`.
  - Mantenimiento explícito de documentos internos como **"Documento No Fiscal / Comanda Interna"** hasta la homologación.
  - Tabla `document_sequences` con bloqueo transaccional para control de numeración.

---

### 🟢 FASE 7: Reportes Multidimensionales & Hardening (P2)
- **Objetivo:** Analítica gerencial y preparación para producción.
- **Entregables:**
  - Reporte de Ganancias Reales (Ventas Netas - Costos de Venta Kardex - Gastos Operativos).
  - Reporte de Antigüedad de Saldos por Cobrar (Aging Report 0-7, 8-15, 16-30, 30+).
  - Auditoría global de seguridad y pruebas de carga.
