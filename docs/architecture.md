# 🏛️ Arquitectura del Sistema: Guagua ERP Comercial Venezuela

**Versión:** 2.0 (Enterprise ERP Edition)  
**Stack:** Flutter + Supabase (PostgreSQL 15+, Auth, Storage, Edge Functions)

---

## 1. Visión General de la Arquitectura

```mermaid
graph TD
    subgraph Frontend [Flutter Multiplataforma (Desktop / Mobile / Web)]
        UI[Pantallas & Widgets UI]
        State[Riverpod Notifiers & State Management]
        Repos[Repositories & API Layer]
        Offline[Hive Offline Storage & Outbox Queue]
    end

    subgraph Hardware [Hardware de Mostrador]
        Printers[Impresoras Térmicas ESC/POS LAN/USB]
        Drawer[Gaveta de Dinero RJ11]
        Scanner[Lector Código de Barras USB/BT]
    end

    subgraph Backend [Supabase Cloud BaaS]
        Auth[Supabase Auth (JWT)]
        Postgres[(PostgreSQL 15+ Database)]
        RLS[Row Level Security & Membership Engine]
        RPC[Funciones SQL Atómicas ACID]
        Storage[Supabase Private Storage]
    end

    UI --> State
    State --> Repos
    Repos --> Offline
    Offline -.->|Sincronización Outbox| Backend
    Repos --> Backend
    UI --> Hardware
    Backend --> Auth
    Backend --> Postgres
    Postgres --> RLS
    Postgres --> RPC
```

---

## 2. Aislamiento Multi-Tenant y Seguridad por Empresa

Para garantizar que un usuario de la "Empresa A" jamás pueda ver ni alterar datos de la "Empresa B":

1. **Entidad Empresa (`companies`):**
   - Cada empresa posee identidad legal: RIF, Razón Social, Nombre Comercial, Dirección Fiscal, Teléfono, Moneda Base y Parámetros.
2. **Membresías (`company_memberships`):**
   - Vincula `company_id` con `user_id` (`auth.users`) y define el rol del usuario en esa empresa (`ADMIN`, `SUPERVISOR`, `CASHIER`, `WAREHOUSE`).
3. **Columna `company_id` en todas las tablas transaccionales:**
   - `products`, `categories`, `clients`, `debts`, `sales`, `sale_items`, `cash_shifts`, `stock_transfers`, `audit_logs`, `suppliers`, `stock_movements`.
4. **Funciones de Seguridad Helper en PostgreSQL:**
   ```sql
   CREATE OR REPLACE FUNCTION public.get_user_company_ids(p_user_id UUID)
   RETURNS SETOF UUID AS $$
     SELECT company_id FROM public.company_memberships 
     WHERE user_id = p_user_id AND status = 'ACTIVE';
   $$ LANGUAGE sql SECURITY DEFINER STABLE;
   ```
5. **Políticas RLS Estrictas:**
   - Las consultas directas por PostgREST solo retornan filas donde `company_id` pertenece a las empresas autorizadas del usuario autenticado:
   ```sql
   CREATE POLICY "Aislamiento por empresa" ON public.products
     FOR ALL TO authenticated
     USING (company_id IN (SELECT get_user_company_ids(auth.uid())))
     WITH CHECK (company_id IN (SELECT get_user_company_ids(auth.uid())));
   ```

---

## 3. Integridad Transaccional y Reglas Financieras

1. **Precios y Moneda:**
   - La base de datos opera con `NUMERIC(15,2)` para importes monetarios y `NUMERIC(15,4)` para tasas de cambio oficial BCV.
   - Todo cálculo fiscal o financiero sensible se valida y recalcula en el servidor (PostgreSQL) para evitar manipulación en cliente.
2. **Venta Atómica Idempotente:**
   - Toda venta generada en el POS se procesa mediante una función RPC transaccional:
     - Bloquea stock con `FOR UPDATE`.
     - Inserta cabecera y detalle.
     - Aplica desarmado automático de cajas si faltan unidades.
     - Afecta la sesión de caja activa.
     - Si es a crédito, valida y actualiza la deuda del cliente.
     - Todo ocurre dentro de una transacción atómica `BEGIN ... COMMIT`.
3. **Inmutabilidad de Documentos Emitidos:**
   - Las ventas confirmadas jamás se eliminan físicamente (`DELETE`). Cualquier anulación genera un evento en `audit_logs` con supervisor responsable y motivo.

---

## 4. Gestión del Estado en Flutter

- **Riverpod 3.x:**
  - `authProvider`: Maneja sesión de usuario, perfil activo y empresa activa.
  - `companyProvider`: Empresa seleccionada, RIF, configuración fiscal y moneda.
  - `posProvider`: Carrito en memoria, descuentos, selector de cliente y cálculo multimoneda.
  - `inventoryProvider`: Productos, precios mayoristas, combos y transferencias.
  - `cashShiftProvider`: Sesión de caja abierta, arqueo y cierres X/Z.
  - `creditProvider`: Clientes, saldos por cobrar y abonos.
