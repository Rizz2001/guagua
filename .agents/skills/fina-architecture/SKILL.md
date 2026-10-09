---
name: fina-architecture
description: |
  Arquitecto del Sistema Administrativo y Financiero (Fina Clone). Mantiene el contexto global, 
  la arquitectura de módulos, resiliencia offline-first, motor de pagos multimoneda venezolano (FX/vueltos),
  gestión manual diaria de tasa de cambio (BCV/Paralelo), impresión térmica, control de caja (cierre X/Z con fondo inicial), 
  lector de código de barras, auditoría anti-fraude, combos/desarmado de cajas a unidades, precios dinámicos (mayor/detal), 
  recibos/cobro por WhatsApp, analíticas de riesgo/cartera (VIEWRPC), regla de oro de flujo de caja vs crédito (credit-sales-cashflow), 
  compras a proveedores (CPP), matriz de roles RBAC, control de mermas/lotes, despliegue CI/CD y transacciones atómicas PostgreSQL/Supabase para Android y PC.

  Cuándo usar:
  - Al definir la estructura de módulos (Ventas, Inventario, Cuentas por Cobrar, Cierre de Caja, Analíticas de Crédito).
  - Al tomar decisiones de arquitectura sobre sincronización offline-first (Hive/Isar -> Supabase).
  - Al diseñar funciones RPC en Supabase para transacciones atómicas de venta, desarmado automático de cajas e inventario.
  - Al implementar la lógica multimoneda (USD/VES), tasa diaria del día (BCV/Paralelo), pagos divididos y vuelto cruzado.
  - Al estructurar desarmado de cajas (1 caja = 12 unidades), combos promocionales y escalas de precios (Detal, Mayor, Distribuidor).
  - Al validar límites de crédito por cliente (`credit_limit`), abonos parciales y separar Dinero en Caja vs Cuentas por Cobrar.
  - Al configurar recepción de compras de proveedores con recálculo de Costo Promedio Ponderado (CPP).
  - Al definir permisos y roles RBAC (Administrador, Supervisor, Cajero, Bodeguero) con RLS estricto.
  - Al registrar mermas, botellas rotas, consumo interno y control de fechas de vencimiento por lote.
  - Al configurar envío de recibos digitales y cobro automático de cartera morosa por WhatsApp (`wa.me/...`).
  - Al diseñar el Cierre Z de turno con fondo inicial obligatorio ($50) y desglose por canal (Efectivo USD/Bs, Pago Móvil, Punto, Zelle).
  - Al diseñar métricas financieras de liquidez, índice de morosidad (%) y capital colocado en la calle mediante vistas SQL optimizadas.
  - Al configurar flujos de despliegue continuo (CI/CD con Cloudflare Pages / Netlify / APKs directas).
---

# Arquitecto del Sistema Administrativo (Fina Clone)

Esta skill mantiene el contexto global, la arquitectura de resiliencia y las reglas de negocio del sistema administrativo y financiero multiplataforma (Android y PC) construido con **Flutter** y **Supabase**.

---

## 🛠️ Stack Tecnológico Principal

- **Frontend / UI:** Flutter (con diseño responsivo para Android, Windows y Web).
- **Almacenamiento Local (Offline-First):** Hive / Isar / SQLite para caché local y cola de salida (*Outbox Queue*).
- **Backend / Base de Datos:** Supabase (PostgreSQL) con Funciones RPC, Vistas SQL agregadas y Row Level Security (RLS).
- **Gestión de Estado:** Riverpod (`AsyncValue`, `StreamProvider`, StateNotifier).
- **Impresión & Hardware:** Driver ESC/POS (Bluetooth Android / USB Windows), `pdf` package, `HardwareKeyboard` (PC), `mobile_scanner` (Android).
- **Integraciones Externas:** WhatsApp API / URLs universales (`url_launcher`).
- **Despliegue & CI/CD:** Cloudflare Pages / Netlify (Flutter Web/Windows) + Compilación automatizada APK de Android.

---

## 📌 Módulos y Reglas de Negocio Clave

### 1. ⚙️ `supabase-db-engine` (Transacciones Atómicas y RPC Server-Side)
- **NUNCA descontar inventario desde el cliente (Flutter) con múltiples llamadas HTTP.**
- **Funciones RPC Obligatorias:** Registro de ventas y deducción de stock en PostgreSQL atómico (`CREATE FUNCTION registrar_venta(...)`).
- **Seguridad Concurrente & RLS:** RLS obligatorio en todas las tablas (`sales`, `inventory`, `payments`, `debts`, `cash_shifts`).

### 2. 📡 `offline-first-sync` (Resiliencia ante Caídas de Internet)
- **Cero Congelamiento en Caja:** Catálogo y precios disponibles al instante en almacenamiento local (Hive/Isar).
- **Cola de Salida (*Outbox Queue*):** Las ventas offline se guardan en la cola y se sincronizan automáticamente con Supabase al recuperar la señal.

### 3. 🇻🇪 `venezuela-fx-pos-engine` & `daily-exchange-rate-management` (Gestión Manual Diaria de Tasa)
- **Doble Referencia Monetaria:** Moneda base de cálculo (USD) y moneda local de circulación (VES/Bs.).
- **Actualización Manual Diaria de Tasa:** El Administrador/Supervisor ajusta manualmente la Tasa Oficial del Día (ej. Tasa BCV: `36.50 Bs/USD` o Paralelo) al iniciar la jornada o durante el día.
- **Historización de Tasa (`store_exchange_rates`):** Cada venta guarda la tasa congelada del instante exacto de la transacción. Cambios de tasa posteriores no alteran ventas pasadas.
- **Pagos Divididos (Factura Única):** Cobro combinado en una sola venta (USD efectivo + Bs Pago Móvil + Zelle + Tarjeta).
- **Calculadora de Vueltos Mixtos:** Cálculo de cambio sin discrepancias por redondeo decimal.

### 4. 🖨️ `pos-hardware-receipts` & Recibos Digitales WhatsApp
- **Comprobante Térmico:** Recibos de 58mm y 80mm usando comandos ESC/POS (Bluetooth Android / USB Windows).
- **Recibo Digital por WhatsApp:** Envío del comprobante de venta o archivo PDF vectorial directamente al WhatsApp del cliente con 1 solo toque (`wa.me/...`).

### 5. 💵 `pos-cash-shift-control` (Cierre y Arqueo de Caja X/Z con Fondo Inicial)
- **Apertura de Turno Obligatoria:** Declaración inicial del fondo de caja (ej. $50 USD / Bs para dar vuelto).
- **Movimientos Manuales (`cash_movements`):** Registro explícito de entradas y salidas de efectivo (gastos menores, fletes).
- **Cierre Z al Centavo:** Separación exacta del dinero esperado vs contado en **Efectivo USD**, **Efectivo Bs**, **Pago Móvil**, **Punto de Venta** y **Zelle**, detectando sobrantes o faltantes al centavo.

### 6. 🔍 `pos-barcode-events` (Lector de Códigos de Barra PC & Android)
- **Captura Global en PC/Windows:** Listener de teclado global (`HardwareKeyboard`) que detecta escáner USB sin requerir clic en la barra de búsqueda.
- **Escaneo Óptico en Android:** Cámara nativa usando `mobile_scanner`.

### 7. 🛡️ `audit-anti-fraud` (Trazabilidad y Anulaciones Anti-Fraude)
- **PROHIBIDO ELIMINAR (`DELETE`) REGISTROS:** Usar únicamente *soft-deletes* (`is_deleted`) o notas de crédito.
- **Bitácora de Auditoría (`audit_logs`):** Anulaciones o cambios de precio requieren autorización con registro inmutable y reversión de stock.

### 8. 📦 `inventory-units-and-combos` (Desarmado Automático de Cajas y Combos)
- **Desarmado Automático de Cajas:** Si el cajero vende 1 unidad detal y no hay unidades sueltas, la RPC en PostgreSQL desarma automáticamente 1 caja (ej. 1 Caja = 12 Unidades), añade 12 unidades al stock detal y descuenta la unidad vendida en la misma transacción atómica.
- **Combos Promocionales:** Artículos agrupados (ej. Ron + Refresco + Hielo) a precio único que descuentan las unidades individuales correspondientes en tiempo real.

### 9. 🏷️ `dynamic-pricing-engine` (Listas de Precios: Detal, Mayor y Distribuidor)
- **Escalas de Precios:** Configuración de listas (Precio Detal, Precio Mayor, Precio Distribuidor).
- **Cambio Automático por Volumen:** El sistema aplica automáticamente el precio al mayor en el carrito cuando la cantidad supera el umbral preestablecido (ej. `>= 6 unidades`).

### 10. 🛒 `supplier-purchase-engine` (Compras, Proveedores y Costo Promedio Ponderado - CPP)
- **Órdenes de Compra a Proveedores:** Registro de recepciones de mercancía con costos de compra actualizados.
- **Recálculo Automático de CPP:** Al recibir nuevo stock, PostgreSQL recalcula atómicamente el Costo Promedio Ponderado:
  $$\text{Nuevo Costo} = \frac{(\text{Stock Actual} \times \text{Costo Actual}) + (\text{Cant. Comprada} \times \text{Costo Compra})}{\text{Stock Actual} + \text{Cant. Comprada}}$$

### 11. 👥 `multi-user-rbac-security` (Matriz de Roles y Permisos Granulares)
- **Roles Definidos:** `Administrador`, `Supervisor`, `Cajero` y `Bodeguero`.
- **Protección de Costos y Tasa:** El rol **Cajero** tiene prohibido visualizar costos de compra, utilidad neta o alterar la tasa de cambio del día.
- **Requerimiento de Supervisor:** Las anulaciones, descuentos manuales o ventas que sobrepasen el cupo de crédito requieren PIN/autorización de Supervisor o Admin.

### 12. 📉 `spoilage-and-batch-control` (Mermas, Daños y Control de Vencimientos)
- **Ajustes de Inventario (`inventory_adjustments`):** Registro de botellas rotas, mercancía dañada o consumos internos con imputación contable a gastos.
- **Alertas de Vencimiento por Lote:** Monitoreo de fechas de vencimiento notificando lotes próximos a vencer (15-30 días).

### 13. 🏦 `credit-sales-cashflow` (Regla de Oro: Flujo de Caja Real vs Cuentas por Cobrar)
- **Regla de Oro Contable:** "Una venta no es dinero en caja hasta que se paga".
- **Límite de Crédito (`credit_limit`):** Perfil de cliente con límite de crédito configurado. Bloqueo en servidor si $(\text{Deuda Actual} + \text{Venta a Crédito}) > \text{Límite}$.
- **Abonos Parciales:** Registro de abonos que reducen la deuda e ingresan el dinero a la caja del turno activo.

### 14. 📲 `debt-collection-automation` (Gestión de Cobranza por WhatsApp)
- **Clasificación por Antigüedad:** Agrupación automática de deudores (vencidas a 1-7 días 🟡, 8-15 días 🍊, 30+ días 🔴).
- **Plantillas Dinámicas:** Mensajes formateados automáticamente con saldo pendiente en USD y equivalencia en Bs.
- **Cobro por WhatsApp en 1 Tocar:** Integración de enlaces de WhatsApp (`wa.me/...`) en Flutter.

### 15. 📈 `credit-portfolio-analytics` (Métricas de Riesgo y Liquidez)
- **Métricas Financieras Críticas:** Capital Colocado en la Calle (USD / Bs), Índice de Morosidad (%), Cobros Proyectados vs. Recaudados de la semana.
- **Optimización SQL Increíble:** Uso obligatorio de Vistas PostgreSQL (`CREATE VIEW ...`) y Funciones RPC de agregación precalculadas.

### 16. 🚀 `flutter-ci-cd-deploy` (Despliegue y Actualizaciones Automatizadas)
- **Sin Fricción de Actualización:** Automatización de compilaciones sin requerir visitas equipo por equipo.
- **Flutter Web/Windows:** Despliegue continuo en Cloudflare Pages / Netlify.
- **Android APK Directo:** Generación automatizada de APKs para descarga directa e instalación rápida en dispositivos de administración y caja.

---

## ⚡ Directrices de Desarrollo

1. **Exactitud sobre Estética Inicial:** Priorizar la integridad de los datos financieros sobre adornos visuales tempranos.
2. **Tipos Monetarios Exactos:** **NUNCA** usar tipos de punto flotante (`float`, `double precision`) para montos monetarios en PostgreSQL; usar siempre `numeric(15,2)` / `decimal`.
3. **Optimizado para Uso Intensivo (POS):** Diseñar la UI con atajos de teclado en PC/Windows y botones táctiles grandes en Android.
