# 📋 Auditoría Técnica Integral del Proyecto: Guagua POS / ERP Comercial Venezuela

**Fecha:** 12 de Octubre de 2026  
**Auditor:** Arquitecto de Software Senior & QA Lead (Flutter + Supabase)  
**Proyecto:** Guagua POS / ERP Comercial  
**Norma de Referencia:** Skill Maestro `erp-venezuela-flutter-supabase` (v1.0)

---

## 1. Resumen Ejecutivo del Estado Actual

El proyecto **Guagua POS** comenzó como un sistema de punto de venta (POS) y administración comercial básica para comercio minorista en Venezuela, con foco en multimoneda (USD / VES a tasa BCV), control de caja (Cierre X/Z) e impresión de tickets térmicos (ESC/POS 58/80mm).

La base técnica construida es sólida en la capa de UI de mostrador y utilidades financieras (`CurrencyEngine`, `PrintSpoolerService`, `ReceiptBuilderService`, `WhatsAppService`). Sin embargo, al auditar el sistema bajo los estándares de un **ERP Comercial Empresarial Multi-Empresa para Venezuela**, se identifican brechas críticas de seguridad (RLS completamente permisivo `USING (true)`), falta de entidad Empresa/Tenant en la base de datos, ventas no atómicas en el servicio outbox, ausencia de Kardex formal de movimientos de stock y falta de una estructura formal de compras y documentos fiscales.

---

## 2. Arquitectura Encontrada

### 2.1 Stack Tecnológico
- **Frontend:** Flutter (Dart SDK ^3.12.2 / 3.13.5), multiplataforma (Android, Windows Desktop, Web).
- **Gestión de Estado:** `flutter_riverpod: ^3.4.3` con patrón `Notifier` y `ConsumerWidget`.
- **Persistencia Local / Offline:** `hive: ^2.2.3` / `hive_flutter: ^1.1.0` (cajas para spooler de impresión y outbox de ventas pendientes).
- **Backend:** Supabase Cloud (PostgreSQL 15+, Supabase Auth, Row Level Security, RPC Functions).
- **Periféricos & Hardware:** `esc_pos_utils_plus`, sockets TCP raw port 9100 para LAN ESC/POS y apertura de gaveta RJ11 `ESC p 0 25 250`.

### 2.2 Estructura de Directorios
```text
lib/
├── core/
│   ├── constants/       (Colores, constantes de Supabase)
│   ├── services/        (Supabase, Outbox, Spooler, Drawer, Receipt, WhatsApp, Audit)
│   ├── theme/           (AppTheme Material 3)
│   └── utils/           (CurrencyEngine, ResponsiveLayout, BarcodeListener)
├── features/
│   ├── auth/            (Login, UserModel, AuthController)
│   ├── cash_shift/      (Apertura, arqueo, Cierre X/Z)
│   ├── credit/          (Gestión de cartera, clientes, mora, abonos)
│   ├── dashboard/       (KPIs, margen bruto, CSV, PDF contable)
│   ├── inventory/       (Productos, combos, mayorista, transferencias)
│   ├── navigation/      (MainLayoutScreen responsive con Drawer / NavigationRail)
│   ├── pos/             (Punto de venta, carrito, cobro multimoneda, IGTF)
│   ├── settings/        (Tasa BCV, sucursal, impresora LAN/USB, datos de pago)
│   └── suppliers/       (Recepción de compras y Costo Promedio Ponderado CPP)
└── shared/
    └── widgets/         (SupervisorAuthDialog)
```

---

## 3. Matriz de Módulos del ERP y Estado Verificado

De los 16 módulos objetivo del ERP comercial:

| # | Módulo ERP | Estado Actual | % Funcionalidad Real Verificada | Observaciones Técnicas |
| :-: | :--- | :---: | :---: | :--- |
| **1** | **Autenticación & Configuración Inicial** | 🟡 Parcial | 60% | Auth vía Supabase (`signInWithPassword`, `signUp`). Falta recuperación de contraseña, expiración de sesión y selección de empresa. |
| **2** | **Dashboard Gerencial** | 🟡 Parcial | 65% | Muestra métricas de ventas, capital en calle y margen bruto en tiempo real. Falta filtrado multidimensional y segregación por empresa. |
| **3** | **Empresa & Configuración Multi-Tenant** | 🔴 Inexistente | 0% | No existe tabla `companies` / `tenants`. La app operaba en modo de tienda única con nombre de sucursal local en Hive. |
| **4** | **Usuarios, Roles & Permisos (RBAC)** | 🟡 Parcial | 40% | Roles (`ADMIN`, `SUPERVISOR`, `CASHIER`, `WAREHOUSE`) almacenados como string en `profiles`. Falta tabla de permisos granulares por empresa. |
| **5** | **Productos, Categorías & Servicios** | 🟢 Operativo | 80% | Catálogo en Supabase con precios detal, mayorista, combos y costo. Falta distinción formal entre bien y servicio, SKU separado de código de barras y unidades de medida. |
| **6** | **Clientes & Proveedores** | 🟡 Parcial | 50% | `clients` implementado con límite y deuda. La tabla `suppliers` no existe en PostgreSQL (las compras registran el nombre en texto libre). |
| **7** | **Inventario & Movimientos de Stock (Kardex)** | 🟡 Parcial | 45% | Control de stock simple (+/- directo en `products.stock`). Falta tabla `stock_movements` (Kardex auditable con tipo de movimiento, costo y documento origen). |
| **8** | **Ventas & Presupuestos** | 🟡 Parcial | 65% | Ventas directas en POS con cobro multimoneda. No existe módulo de presupuestos/cotizaciones sin afectación de inventario. |
| **9** | **Facturación & Documentos Fiscales** | 🔴 Pendiente | 15% | Emite tickets térmicos internos de comanda. Falta módulo de documentos fiscales y control de series según normativa SENIAT (debe mantenerse no fiscal hasta homologación). |
| **10** | **Compras & Recepción de Mercancía** | 🟡 Parcial | 50% | Pantalla de compra con RPC `recepcionar_compra_proveedor` para recálculo de CPP. Falta orden de compra, factura de proveedor y cuentas por pagar. |
| **11** | **Pagos, Cobros & Cuentas Pendientes** | 🟢 Operativo | 75% | Cuentas por cobrar con abonos parciales, cálculo de cupo disponible y mensajes WhatsApp con semáforo de mora. Falta cuentas por pagar a proveedores. |
| **12** | **Caja, Apertura, Arqueo & Cierre (X/Z)** | 🟢 Operativo | 85% | Apertura con fondo inicial, cálculo de faltante/sobrante, desglose por método y cierres X/Z persistidos en Supabase. |
| **13** | **Gastos Operativos** | 🔴 Inexistente | 0% | No existe modelo ni pantalla de gastos vinculados a la sesión de caja o cuentas bancarias. |
| **14** | **Reportes Administrativos** | 🟡 Parcial | 55% | Exportación de libro de ventas a CSV y PDF contable. Falta reporte de Kardex, antigüedad de deudas detallada y conciliación de caja. |
| **15** | **Auditoría & Trazabilidad** | 🟡 Parcial | 60% | Tabla `audit_logs` con autorización de supervisor (anulaciones, apertura de gaveta). Falta auditoría global de cambios a nivel de entidades. |
| **16** | **Integraciones Externas** | 🟡 Parcial | 50% | WhatsApp Web/App (`wa.me`) con enlace estructurado y hardware ESC/POS en red local. |

---

## 4. Problemas Críticos de Seguridad Identificados (P0)

1. **Políticas Row-Level Security (RLS) Permisivas:**
   - En `supabase/schema.sql`, las tablas `products`, `categories`, `clients`, `debts`, `cash_shifts`, `sales`, `sale_items`, `spoilage_logs`, `audit_logs` y `stock_transfers` poseen políticas con:
     ```sql
     CREATE POLICY "Permitir todo en ..." ON public.... FOR ALL TO public USING (true) WITH CHECK (true);
     ```
   - **Impacto:** Cualquier atacante anónimo con la clave pública de Supabase puede ejecutar `DELETE FROM sales`, alterar precios de productos o borrar clientes sin autenticación.
   - **Corrección requerida:** Migrar a `TO authenticated`, verificar membresía en la empresa (`company_id`), y restringir `INSERT/UPDATE/DELETE` según el rol verificado en el servidor.

2. **Ausencia de Aislamiento Multi-Tenant en Backend:**
   - Las entidades comerciales no contienen columna `company_id` o `tenant_id`. Si se registran dos empresas, sus datos estarían mezclados en las mismas tablas.
   - **Corrección requerida:** Crear entidad `companies` y `company_memberships`, vincular cada tabla a `company_id` y validar en RLS con `auth.uid()`.

3. **Inseguridad en Creación de Perfil de Usuario (`auth_controller.dart`):**
   - El método `register` inserta directamente en `public.profiles` desde Flutter (`client.from('profiles').insert(...)`). Si el cliente falla o es interceptado, el rol puede ser manipulado.
   - **Corrección requerida:** Implementar un Trigger SQL en PostgreSQL sobre `auth.users` (`on_auth_user_created`) para crear el perfil automáticamente en el servidor con rol seguro por defecto.

---

## 5. Problemas de Integridad Transaccional de Datos

1. **Venta no Atómica en `OutboxService` (`outbox_service.dart`):**
   - Actualmente se realiza un `insert` en `sales`, luego un bucle `for` de inserts en `sale_items`, y luego llamadas RPC individuales a `desarmar_caja_si_es_necesario`.
   - Si la conexión se interrumpe durante el bucle, la venta queda huérfana en la base de datos y fallará en el próximo reintento por duplicado de `invoice_number`.
   - **Corrección requerida:** Crear una función RPC PostgreSQL atómica `registrar_venta_completa(p_sale_data JSONB)` que inserte venta, ítems, actualice stock y registre auditoría en una única transacción ACID.

2. **Falta de `stock_movements` (Kardex Formal):**
   - El inventario se modifica directamente sobre `products.stock`. Si hay una discrepancia contable, no es posible reconstruir el historial exacto de entradas y salidas de una fecha anterior.
   - **Corrección requerida:** Crear tabla `stock_movements` con `quantity_delta`, `cost_usd`, `movement_type`, `reference_id` y `created_by`.

3. **Uso de Tipos Flotantes en UI sin Redondeo Servidor:**
   - Cálculos en Dart con `double` pueden generar desvíos de precisión IEEE 754 (ej. `1.20 * 6 = 7.199999999999999`).
   - **Corrección requerida:** Validar y recalcular todos los subtotales, IGTF y totales en PostgreSQL con `NUMERIC(15,2)`.

---

## 6. Riesgos de Modificar el Código Existente

- **Riesgo 1 (Pérdida de datos existentes):** Hay 1 usuario y registros existentes en Supabase. Cualquier migración debe ser **aditiva y no destructiva** (`ADD COLUMN IF NOT EXISTS`, migrar datos existentes a una empresa por defecto).
- **Riesgo 2 (Regresión en pantallas POS operativas):** Las pantallas `pos_screen.dart`, `cash_shift_screen.dart` y `credit_management_screen.dart` están funcionando correctamente. Cualquier refactorización debe preservar sus contratos y pruebas unitarias.

---

## 7. Plan Priorizado de Mejoras (P0, P1, P2)

### 🔴 P0 — Seguridad, Autenticación y Aislamiento de Datos (Inmediato)
1. Crear esquema de Multi-Tenancy: tablas `companies` y `company_memberships`.
2. Asignar datos existentes a la empresa por defecto (`company_id`).
3. Reemplazar las políticas RLS abiertas `USING (true)` por políticas estrictas basadas en membresía y rol (`TO authenticated`).
4. Trigger en Supabase para creación segura de perfiles en `auth.users`.
5. Actualizar `AuthController` y `UserModel` para incluir membresía de empresa activa.

### 🟡 P1 — Fundamentos del Negocio ERP
1. Transacción atómica RPC para registro de ventas e inventario (`registrar_venta_transaccional`).
2. Tabla de proveedores (`suppliers`) y cuentas por pagar.
3. Tabla de movimientos de inventario (`stock_movements` / Kardex) con recálculo transaccional de CPP.
4. Módulo de presupuestos / cotizaciones sin descuento de stock.
5. Módulo de gastos operativos (`expenses`) vinculados a caja.

### 🟢 P2 — Fiscalidad, Automatización y Reportes Avanzados
1. Checklist y marco documental de cumplimiento fiscal venezolano (`docs/fiscal-compliance-checklist.md`).
2. Mantenimiento de documentos no fiscales claramente etiquetados hasta homologación formal.
3. Reportes contables avanzados y exportaciones multidimensionales.
