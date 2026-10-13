---
name: erp-venezuela-flutter-supabase
description: Diseña, implementa, audita y prueba un ERP comercial de facturación para Venezuela con Flutter y Supabase. Úsalo para construir o mejorar módulos de ventas, facturación, inventario, compras, caja, clientes, proveedores, reportes, permisos, PostgreSQL, RLS, Edge Functions, migraciones y validación fiscal.
---

# Skill maestro: ERP comercial con Flutter + Supabase

## 0. Misión y contexto

Actúa como arquitecto de software, desarrollador Flutter senior, especialista en PostgreSQL/Supabase, QA engineer y responsable de seguridad para un ERP comercial en la nube destinado inicialmente a empresas venezolanas.

Objetivo del producto:
- Una empresa y una sede en el MVP; arquitectura preparada para múltiples empresas y sucursales.
- Entre 1 y 5 usuarios iniciales.
- Interfaz responsive para escritorio, tablet y móvil.
- Facturación y documentos comerciales, productos/servicios, inventario, compras, clientes, proveedores, caja, pagos, cuentas por cobrar/pagar básicas, gastos, reportes, configuración y auditoría.
- Contabilidad inicial administrativa; NO afirmar que existe contabilidad formal completa si no se han implementado libro diario, mayor, plan de cuentas, asientos balanceados y estados financieros.
- Jurisdicción objetivo: Venezuela. No inventar requisitos fiscales ni declarar cumplimiento sin validación profesional y normativa vigente.
- Stack establecido: Flutter + Supabase (PostgreSQL, Auth, Storage, Edge Functions y Realtime cuando sea apropiado).

## 1. Protocolo obligatorio antes de tocar código

1. Inspecciona el repositorio completo: estructura, `pubspec.yaml`, rutas, estado global, tema, widgets, modelos, servicios, pruebas y configuración de Supabase.
2. Inspecciona las migraciones existentes y el esquema real de la base de datos antes de proponer tablas nuevas.
3. Identifica qué está implementado, qué funciona, qué está simulado y qué está incompleto. No asumas que una pantalla conectada visualmente ya persiste datos.
4. Produce un plan breve por etapas con archivos que cambiarán, riesgos, migraciones, pruebas y dependencias.
5. Conserva las convenciones, identidad visual y arquitectura útiles del proyecto existente. No reescribas toda la app ni elimines funciones sin justificarlo.
6. Si falta información fiscal, comercial o de seguridad que cambie la corrección del sistema, crea una decisión pendiente explícita. No inventes datos.
7. Trabaja en cambios pequeños y verificables. Ejecuta análisis estático y pruebas después de cada módulo.
8. No ejecutes operaciones destructivas, despliegues productivos, eliminación de datos ni cambios de políticas de seguridad sin explicar el impacto y obtener autorización.
9. No afirmes que una tarea está terminada si no has revisado el código, ejecutado las verificaciones disponibles y documentado lo que no pudo comprobarse.
10. Mantén `docs/implementation-plan.md`, `docs/decisions.md` y `docs/known-limitations.md` actualizados cuando aplique.

## 2. Reglas no negociables

### Seguridad y Supabase
- Nunca incluir `service_role`, secretos de proveedores ni claves privadas en Flutter, assets, repositorio o configuración distribuida al cliente.
- La app Flutter puede usar la publishable/anon key correspondiente al proyecto, pero la protección real de datos depende de grants mínimos y Row Level Security (RLS).
- Habilitar RLS en todas las tablas expuestas a clientes. Crear políticas explícitas para `SELECT`, `INSERT`, `UPDATE` y `DELETE` según el caso; no usar políticas abiertas como `USING (true)` para datos comerciales privados.
- Verificar permisos en el servidor/base de datos. Ocultar botones en Flutter no es autorización.
- Validar `tenant_id` contra la identidad y membresía del usuario; nunca confiar en un `tenant_id` enviado libremente por el cliente.
- Las funciones privilegiadas se ejecutan solo en servidor/Edge Functions o funciones SQL con permisos cuidadosamente definidos.
- Usar grants mínimos, límites de sesión, validación de entradas, límites de solicitudes y logs sin contraseñas, tokens ni datos sensibles innecesarios.
- Mantener secretos fuera del control de versiones. Documentar variables requeridas en `.env.example` sin valores reales.
- No registrar información fiscal o personal completa en logs de errores si no es imprescindible.

### Integridad transaccional
- Las operaciones que cambian varios registros financieros o de inventario deben ejecutarse atómicamente en PostgreSQL mediante funciones RPC/SQL o un flujo de servidor apropiado. No repartir una venta crítica en múltiples llamadas Flutter que puedan fallar a mitad de camino.
- Usar claves de idempotencia o una estrategia equivalente para evitar facturas, pagos, movimientos de stock o recepciones duplicados por doble clic, reintentos o mala conexión.
- No confiar en importes, impuestos, costos, permisos ni disponibilidad de stock calculados únicamente en Flutter; recalcular y validar en servidor.
- No borrar físicamente documentos emitidos, pagos conciliados ni movimientos históricos. Corregir mediante reversos o documentos de ajuste autorizados.
- No actualizar en silencio una factura emitida cuando cambia el catálogo, la dirección del cliente o una tasa fiscal.
- Definir reglas de concurrencia y bloquear filas/secuencias cuando sea necesario.
- Registrar quién, cuándo, qué entidad y qué operación cambió. La auditoría no debe poder editarse desde el cliente.
- Dinero: `NUMERIC/DECIMAL` en PostgreSQL y tipo decimal seguro en Dart. No usar `double` como fuente autoritativa para importes. Definir precisión y redondeo por moneda y documento.
- Usar UTC para timestamps técnicos y una zona horaria configurada para fechas comerciales.

### Calidad y diseño
- No crear botones decorativos sin acción funcional, enlaces rotos, datos demo mezclados con producción ni pantallas que aparenten guardar sin persistir.
- Toda pantalla debe tener estados de carga, vacío, éxito y error; evitar loaders infinitos.
- Formularios con validación, mensajes claros, prevención de doble envío y confirmación para acciones sensibles.
- Diseño coherente, accesible, responsive, con contraste suficiente, foco de teclado, etiquetas y tamaños táctiles adecuados.
- No introducir dependencias sin explicar por qué son necesarias.
- No duplicar modelos, servicios ni reglas de negocio en varios módulos.

## 3. Arquitectura Flutter recomendada

Adapta la estructura existente si ya está bien organizada. Para una app nueva, usar arquitectura por funcionalidad y separación de responsabilidades:

```text
lib/
  app/
    app.dart
    router.dart
    theme/
    config/
  core/
    errors/
    formatting/
    validation/
    security/
    widgets/
    services/
  features/
    auth/
    dashboard/
    company/
    users_roles/
    customers/
    suppliers/
    products/
    inventory/
    sales/
    fiscal_documents/
    purchases/
    payments/
    cash_register/
    expenses/
    receivables_payables/
    reports/
    audit/
    settings/
  shared/
    models/
    repositories/
```

Dentro de cada feature, preferir `data/`, `domain/` y `presentation/` cuando la complejidad lo justifique. No crear capas vacías por dogma.

- UI: widgets y páginas; no contener reglas financieras críticas.
- Estado: usar la solución ya adoptada por el proyecto. Si no hay una, evaluar Riverpod como opción, evitando mezclar varios patrones.
- Repositorios: abstraer consultas y operaciones de Supabase.
- Modelos: conversión tipada, validación y manejo explícito de campos nulos.
- Navegación: rutas con protección de sesión y permisos; redirección segura después del login.
- Errores: convertir errores técnicos en mensajes útiles y mantener detalles técnicos solo en logs protegidos.
- Formularios: separar borrador, validación, envío y estado final.
- Responsive: navegación lateral en escritorio y navegación compacta en móvil; tablas adaptables o vistas tipo lista en pantallas estrechas.
- Accesibilidad: navegación por teclado en web, semántica, labels y escalado de texto.

## 4. Supabase: organización del backend

Usar:
- PostgreSQL para datos transaccionales.
- Supabase Auth para identidad y sesiones.
- RLS + grants mínimos para aislamiento y autorización.
- Storage privado para documentos y archivos.
- Edge Functions para integraciones externas, notificaciones, tareas privilegiadas o lógica que requiera secretos.
- Realtime solo donde aporte valor real; no usarlo como sustituto de consistencia transaccional.
- Migraciones SQL versionadas en el repositorio. No depender exclusivamente de cambios manuales en el Dashboard.
- Tipos generados para mantener Flutter sincronizado con el esquema cuando la herramienta del proyecto lo permita.

Estructura sugerida:

```text
supabase/
  config.toml
  migrations/
  functions/
    issue-document/
    send-document/
    payment-webhook/
  seed.sql
docs/
  architecture.md
  data-dictionary.md
  fiscal-compliance-checklist.md
  permissions-matrix.md
  test-plan.md
  implementation-plan.md
```

Las funciones Edge deben validar JWT/identidad cuando corresponda, validar payloads, aplicar autorización, evitar repetir operaciones y devolver errores estructurados. No usar Edge Functions para reemplazar constraints o transacciones que PostgreSQL puede garantizar mejor.

## 5. Modelo de datos de referencia

Inspecciona primero el esquema existente y adapta nombres antes de crear migraciones. Incluir `tenant_id` en entidades comerciales para preparar el aislamiento multiempresa. Crear `company_memberships` o una estructura equivalente que relacione usuarios y empresas.

### Identidad y configuración
- `tenants`: id UUID, legal_name, trade_name, rif, address, phone, email, status, created_at.
- `company_memberships`: tenant_id, user_id, status, joined_at.
- `profiles`: user_id, display_name, email/contacto no sensible.
- `roles`: id, tenant_id, code, name.
- `permissions`: code, description.
- `role_permissions`: role_id, permission_code.
- `user_roles`: tenant_id, user_id, role_id.
- `company_settings`: tenant_id, timezone, locale, base_currency, logo_path, document_preferences.
- `tax_rates`: código, tasa NUMERIC, clasificación, vigente_desde, vigente_hasta, estado y evidencia de aprobación.
- `document_sequences`: tenant_id, document_type, series, next_number, estado y configuración; actualizar bajo bloqueo transaccional.

### Catálogos
- `customers`: tenant_id, tipo_identificacion, identificacion, nombre_legal, nombre_comercial, dirección, teléfono, email, condiciones de crédito, límite y estado.
- `suppliers`: tenant_id, rif/identificación, nombre, contactos, dirección, condiciones de pago y estado.
- `product_categories`: tenant_id, nombre, parent_id opcional.
- `units_of_measure`: código, nombre, precisión.
- `products`: tenant_id, sku, barcode, nombre, descripción, tipo (`stock` o `service`), categoría, unidad, costo de referencia, precio, tax_code, stock_minimum, activo.
- Definir unicidad de SKU/código de barras por empresa cuando corresponda.

### Ventas y documentos
- `sales`: tenant_id, customer_id nullable según regla, status, fecha, moneda, subtotal, descuentos, impuestos, total, saldo, creado_por, idempotency_key.
- `sale_items`: sale_id, product_id nullable para conceptos históricos específicos, descripción_snapshot, sku_snapshot, quantity NUMERIC, unit_price NUMERIC, discount_amount, taxable_base, tax_rate_snapshot, tax_amount, line_total.
- `fiscal_documents`: tenant_id, source_sale_id, document_type, status, internal_id, fiscal_number/control_number si aplica, issuer_snapshot JSONB controlado, customer_snapshot JSONB, currency, exchange_rate si aplica, totals, issued_at, voided_at, external_provider_reference, payload_hash y metadata mínima.
- `fiscal_document_items`: document_id, descripción, cantidad, precio, descuentos, base, código/tasa fiscal histórica, impuesto y total.
- `document_relations`: documento_origen, documento_destino, tipo_relación, motivo; usar para notas de crédito/débito y referencias.
- Separar estado comercial del estado fiscal. Un documento puede estar en borrador, pendiente de emisión, emitido, rechazado o anulado según el flujo legal aplicable.

### Inventario y compras
- `stock_locations`: tenant_id, nombre; aunque el MVP tenga un almacén, modelarlo de forma extensible.
- `stock_balances`: tenant_id, location_id, product_id, quantity NUMERIC, updated_at; unique por ubicación/producto.
- `stock_movements`: tenant_id, location_id, product_id, movement_type, quantity_delta, unit_cost, source_type, source_id, created_by, created_at, reversal_of nullable.
- `purchase_orders`, `purchase_order_items`, `goods_receipts`, `goods_receipt_items`.
- `supplier_bills`: proveedor, referencia, fecha, vencimiento, moneda, subtotal, impuestos, total, saldo y estado.
- No aumentar stock por una orden de compra; aumentar solo al confirmar recepción. Evitar registrar dos veces la misma recepción.

### Pagos y caja
- `payments`: tenant_id, direction, method, amount, currency, reference, status, occurred_at, created_by, idempotency_key.
- `payment_allocations`: payment_id, receivable/payable reference, amount_applied. Garantizar que las aplicaciones no excedan el pago ni el saldo del documento.
- `cash_sessions`: tenant_id, opened_by, opened_at, opening_amount, closed_by, closed_at, expected_amount, counted_amount, difference, status.
- `cash_movements`: cash_session_id, type, method, amount, reference, created_by.
- `expenses`: tenant_id, category, description, date, amount, currency, payment_id nullable, status, created_by.
- Distinguir cobro de cliente, pago a proveedor, transferencia entre cuentas, gasto, retiro y ajuste. No sumar todos como “ingreso” sin clasificación.

### Auditoría y soporte
- `audit_logs`: tenant_id, actor_user_id, action, entity_type, entity_id, timestamp, request_id, changes JSONB filtrado.
- `idempotency_records` o campos equivalentes en operaciones críticas.
- `integration_events`: proveedor, tipo, referencia externa, estado, intentos, último error no sensible, timestamps.
- No guardar tokens, contraseñas, secretos ni datos completos de tarjetas en auditoría.

### Reglas SQL
- Usar UUID, `created_at`, `updated_at` y `created_by` donde corresponda.
- `NOT NULL`, `CHECK`, `UNIQUE`, FK e índices adecuados.
- Evitar cascadas destructivas sobre documentos financieros.
- Para documentos emitidos, conservar snapshots históricos.
- Crear vistas de reportes solo si no exponen datos que las RLS no protegen. Revisar cuidadosamente `SECURITY DEFINER`, sus `search_path`, permisos y políticas.
- Nunca permitir que el cliente cambie `tenant_id`, totales definitivos, estado fiscal o secuencias directamente sin una operación autorizada.

## 6. RLS y permisos: requisitos de implementación

Para cada tabla:
1. Habilitar RLS.
2. Definir qué usuarios pueden leer, insertar, actualizar o eliminar.
3. Crear helpers SQL seguros para verificar membresía y permisos si ayudan a evitar duplicación.
4. Evitar recursión entre políticas RLS.
5. Probar acceso con usuarios de dos empresas distintas y con roles distintos.
6. Probar acceso sin sesión.
7. Probar llamadas directas a Data API, no solo la interfaz Flutter.

Matriz base:
- `owner/admin`: configuración de empresa y usuarios; permisos sensibles auditados.
- `sales`: clientes necesarios para venta, productos activos, presupuestos y ventas; sin acceso a costos ni reportes confidenciales salvo autorización.
- `inventory`: productos, recepción y movimientos; no autoriza emitir notas de crédito ni alterar pagos.
- `finance`: cobros/pagos, gastos, cuentas pendientes y reportes financieros según permiso.
- `viewer/auditor`: solo lectura de las entidades autorizadas.
- Las acciones de emisión fiscal, reversos, ajustes de stock y cierre de caja requieren permisos explícitos.

No confiar en un rol recibido en el JSON del cliente. Resolver la identidad desde `auth.uid()` y validar membresía/permiso en PostgreSQL o en el backend seguro.

## 7. Módulos y acciones de usuario

### 7.1 Inicio de sesión y configuración inicial
- Login, logout, recuperación de contraseña y manejo de sesión expirada.
- Invitación/alta de usuarios solo por usuario autorizado.
- Asistente inicial para datos legales, RIF, dirección, zona horaria, moneda, logo y parámetros.
- No permitir que una cuenta sin empresa configurada emita documentos.
- Mostrar errores recuperables y permitir reintento seguro.

### 7.2 Dashboard
- Filtros por período; aclarar si fechas son locales o UTC.
- KPIs: ventas netas, cobros, cuentas pendientes, compras, gastos, alertas de inventario.
- Distinguir ventas facturadas de presupuestos y documentos anulados.
- No llamar “utilidad neta” a ventas menos costos si no están incluidos todos los gastos y ajustes contables.
- Cada tarjeta debe navegar a un reporte filtrado que explique el valor mostrado.
- Manejar empresa nueva sin datos con estados vacíos y CTA útiles.

### 7.3 Productos
- Listar, buscar, filtrar por categoría/estado y paginar en servidor.
- Crear/editar con SKU, barcode, tipo, unidad, costo, precio, impuesto, mínimo de stock y descripción.
- Validar SKU y barcode duplicados.
- Desactivar en vez de borrar si ya hay historial.
- No modificar el snapshot de documentos pasados.
- Mostrar historial de precio/costo si se implementa; no inventarlo si no existe.

### 7.4 Clientes y proveedores
- CRUD permitido por permisos, búsqueda por identificación/nombre y validación de duplicados.
- Mostrar historial de ventas/compras, saldos y contactos.
- Manejar campos fiscales opcionales según tipo de cliente y operación, sujeto a revisión legal.
- No exponer listas completas de clientes a roles que no las necesitan.
- Evitar borrado si existen documentos; usar estado inactivo.

### 7.5 Presupuestos y ventas
- Flujo: borrador → validar cliente/productos/precios → calcular en servidor → confirmar → emitir documento aplicable → registrar inventario/pagos → imprimir/enviar.
- Permitir presupuesto sin afectar inventario ni saldos.
- Conversión de presupuesto a venta idempotente.
- Mostrar disponibilidad de stock informativa; revalidar al confirmar.
- Soportar descuentos autorizados y motivo cuando excedan límites.
- Separar venta de contado, crédito, pago parcial y pago mixto.
- Si hay error, mostrar estado real recuperado desde backend y no asumir que la operación falló o tuvo éxito.
- Evitar doble submit en UI y usar idempotencia en backend.

### 7.6 Facturación y documentos fiscales
- Diferenciar documentos comerciales internos de documentos fiscales.
- Estados claros: borrador, pendiente, emitido, rechazado, anulado o estado específico que exija el proveedor/norma.
- Numeración fiscal nunca generada libremente en Flutter; seguir mecanismo autorizado.
- Generar PDF solo con datos confirmados y sin alterar el documento original.
- Las notas de crédito/débito deben referenciar documento origen, motivo, cantidades/importes y autorización.
- No habilitar “eliminar factura”. Ofrecer acciones legales configuradas y auditadas.
- Conservar resultado de proveedor externo, número/control, fecha y evidencia que corresponda.
- Si el proveedor falla, usar estado pendiente/error y una estrategia de reintento que no emita dos veces.

### 7.7 Inventario
- Kardex por producto y período.
- Movimientos con origen, tipo, cantidad, costo y usuario.
- Recepción de compra aumenta stock; presupuesto no cambia stock.
- Venta confirmada reduce stock según política de emisión/entrega definida.
- Devolución aumenta stock solo después de inspección/aceptación.
- Ajustes requieren permiso, motivo y auditoría.
- Evitar stock negativo salvo política explícita.
- Transacciones y bloqueo de fila/actualización atómica para prevenir sobreventa.
- El método de costo debe estar definido y probado; para promedio ponderado recalcular de forma transaccional con recepciones válidas y documentar ajustes/devoluciones.

### 7.8 Compras
- Orden de compra opcional; recepción separada.
- Comparar cantidades ordenadas, recibidas y facturadas.
- Registrar discrepancias, devoluciones al proveedor y documentos adjuntos.
- Actualizar stock solo por recepción confirmada.
- Crear deuda del proveedor al registrar la factura válida, evitando duplicados por proveedor + referencia según la política definida.
- Pagos parciales y saldo pendiente.

### 7.9 Caja, pagos y cuentas pendientes
- Abrir caja con monto inicial y usuario responsable.
- Cada movimiento registra método, importe, dirección, referencia y documento relacionado.
- Pago mixto se compone de varias líneas que suman exactamente el importe aplicado, respetando redondeo.
- Evitar que el total aplicado exceda la deuda ni el monto recibido.
- Cierre compara monto esperado por método con monto contado/confirmado.
- Diferencias requieren motivo y permiso según umbral.
- Reversos generan registros compensatorios; no borrar movimientos históricos.
- No afirmar conciliación bancaria automática si solo se importa un archivo o se registra una referencia manual.

### 7.10 Gastos
- Categoría, descripción, fecha, importe, moneda, proveedor opcional, método de pago y adjunto.
- Aprobar/rechazar según rol si se configura.
- Evitar duplicar el gasto al vincular un pago.
- Reportar por categoría/período; distinguir flujo de caja y gasto devengado si el sistema no implementa contabilidad de devengo.

### 7.11 Reportes
- Ventas brutas, descuentos, devoluciones y ventas netas claramente definidas.
- Cobros no equivalen a ventas; presentar por separado.
- Compras no equivalen necesariamente a costo de ventas.
- Reporte de stock basado en movimientos y saldo consistente.
- Cuentas por cobrar/pagar con fecha de corte y vencimientos.
- Filtros, paginación y exportación con permiso.
- Probar sumas del reporte contra registros de origen.
- Proteger vistas y funciones para que respeten RLS y `tenant_id`.

### 7.12 Auditoría
- Registrar emisión, anulación, nota de crédito, cambios fiscales, ajustes de stock, pagos, reversos, cambios de roles, exportaciones y cierre de caja.
- Guardar antes/después solo para campos relevantes, filtrando secretos y datos innecesarios.
- Usuario, timestamp, entidad, acción, motivo y request/correlation ID.
- Los usuarios de negocio no pueden editar o borrar auditoría.

### 7.13 Configuración
- Datos empresariales, logo, moneda, zona horaria, formatos de fecha/número.
- Series documentales solo según reglas autorizadas.
- Tasas fiscales con vigencia y aprobación; no hardcodear alícuotas.
- Métodos de pago configurables.
- Políticas de crédito, stock negativo, descuentos, cierre de caja y devoluciones.
- Cambios sensibles requieren permiso, confirmación y auditoría.

## 8. Requisitos fiscales de Venezuela: puerta de control obligatoria

El skill no es asesoría jurídica ni certifica cumplimiento. Antes de habilitar emisión en producción:
1. Identificar el tipo de contribuyente, actividad, obligaciones y modalidad de emisión aplicable.
2. Revisar la normativa vigente del SENIAT y sus modificaciones a la fecha de lanzamiento con contador/asesor tributario.
3. Determinar si aplica máquina fiscal, formas autorizadas, imprenta digital autorizada u otro mecanismo permitido.
4. Validar requisitos de RIF, identificación del comprador, numeración, número de control, datos impresos/digitales, conservación, contingencias y documentos relacionados.
5. Validar IVA, exenciones/exoneraciones, IGTF, retenciones, ISLR, moneda extranjera, tasa de cambio y redondeo según cada supuesto.
6. Verificar la normativa vigente de proveedores/sistemas de facturación; no asumir que una providencia anterior sigue vigente.
7. Documentar en `docs/fiscal-compliance-checklist.md`: norma, artículo/requisito, fuente oficial, fecha de consulta, responsable, decisión, evidencia y fecha de próxima revisión.
8. Mantener entorno de pruebas y pruebas de aceptación fiscal.
9. No mostrar etiquetas como “fiscalmente válido”, “homologado” o “autorizado por SENIAT” sin evidencia documental válida.
10. Si no está validado el régimen, mantener la emisión fiscal desactivada y permitir solo borradores/documentos internos claramente identificados como no fiscales.

Las tasas, series, control numbers y reglas fiscales nunca deben asumirse a partir de ejemplos, capturas de pantalla o código de terceros.

## 9. UX y detalles visuales

- Apariencia de software empresarial moderno, sobrio y consistente; evitar estética de plantilla generada sin criterio.
- Navegación principal por módulos; sidebar en escritorio, drawer/nav adaptado en móvil.
- Header con empresa activa, usuario, alertas y acciones globales.
- Tablas con búsqueda, filtros, orden, paginación, columnas adaptables y menú de acciones.
- Formularios con labels persistentes, validación junto al campo, ayudas y confirmación al abandonar cambios sin guardar.
- Diálogos para confirmar operaciones irreversibles; mostrar impacto concreto.
- Usar colores semánticos de estado sin depender únicamente del color.
- Tablas y facturas deben ser legibles al imprimir; definir layout de impresión y márgenes.
- Los totales deben estar claramente separados de las líneas; moneda y formato consistentes.
- Soportar loading skeleton, empty state, error con reintento y feedback de éxito.
- Evitar actualizaciones optimistas en operaciones fiscales/financieras críticas, salvo que el estado sea reconciliado con servidor.
- Mantener una jerarquía visual consistente, espacios, tipografía y componentes reutilizables.
- Probar anchuras de 360 px, tablet y escritorio; no permitir desbordamiento horizontal accidental.

## 10. Plan de implementación incremental

No implementar todo en un único cambio. Ejecutar etapas con commits pequeños y pruebas.

### Etapa 0 — Auditoría
- Inventariar código, rutas, dependencias, pantallas y esquema Supabase.
- Documentar deuda técnica, funcionalidades reales, datos demo y riesgos.
- Entregable: plan por archivos, migraciones y criterios de aceptación.

### Etapa 1 — Fundamentos
- Configuración de entorno, cliente Supabase, Auth, perfil, tenant/membresía, navegación protegida, tema y manejo de errores.
- Migraciones iniciales, RLS y pruebas de aislamiento.
- No pasar a datos comerciales hasta validar permisos.

### Etapa 2 — Catálogos
- Productos, clientes, proveedores, categorías, unidades, búsqueda, filtros, formularios y desactivación.
- Pruebas de duplicados, permisos y validación.

### Etapa 3 — Inventario y compras
- Ubicaciones, saldos, movimientos, órdenes, recepciones, facturas de proveedor.
- Pruebas de concurrencia, idempotencia y no duplicación.

### Etapa 4 — Ventas y documentos
- Presupuestos, ventas, snapshots, cálculo en servidor, emisión según régimen validado, notas de crédito/débito.
- No habilitar emisión fiscal real antes de la puerta fiscal.

### Etapa 5 — Pagos y caja
- Pagos, aplicaciones, saldos, gastos, aperturas/cierres y reversos.
- Pruebas de sumas, saldos, pagos mixtos y cierres.

### Etapa 6 — Reportes y auditoría
- Dashboard, reportes con filtros, exportación, auditoría y conciliación de totales.

### Etapa 7 — Hardening y despliegue
- RLS review, pruebas de permisos, rendimiento, respaldos, restauración, monitoreo, manuales y aceptación de usuario.
- Despliegue gradual; documentar rollback.

## 11. Pruebas obligatorias

### Unitarias
- Cálculo de cantidades, descuentos, base imponible, impuestos, redondeo y total.
- Aplicación de pagos, saldos y vencimientos.
- Validación de stock y costos.
- Formato de moneda/fechas.
- Permisos de presentación y estados de formularios.

### Integración
- Venta completa con inventario, documento y pago.
- Venta a crédito y abonos.
- Compra con recepción y cuenta por pagar.
- Devolución y nota de crédito.
- Pago mixto, reverso y cierre de caja.
- Migraciones desde base limpia y actualización desde versión anterior.

### Seguridad
- Sin sesión no se accede a datos privados.
- Usuario A no accede a tenant B.
- Vendedor no puede leer costos ni cambiar roles.
- Llamadas directas a API no eluden permisos.
- Ninguna clave privilegiada aparece en el bundle, logs o repositorio.
- RLS probada con roles reales, no solo como administrador.

### Resiliencia
- Doble clic, timeout, reintento y pérdida de conexión durante una operación.
- Dos usuarios venden la última unidad simultáneamente.
- Proveedor fiscal o correo no disponible.
- Fallo parcial, restauración de backup y reintento idempotente.
- Grandes listados paginados y búsquedas sin bloquear la interfaz.

### Fiscal
- Casos de prueba aprobados por asesor tributario para cada tipo documental.
- Tasa y datos históricos preservados.
- Rechazo del proveedor externo no crea un documento falsamente emitido.
- No se duplica numeración ni emisión al reintentar.
- Evidencia de validación y contingencia documentada.

## 12. Comandos de verificación y definición de terminado

Inspecciona los scripts reales del proyecto y ejecuta los comandos disponibles, habitualmente:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Si existe configuración para builds, ejecuta al menos el target principal soportado. No inventes resultados si no puedes ejecutar los comandos.

Para Supabase:
- Revisar migraciones en una base de pruebas limpia.
- Ejecutar tests SQL/RLS y flujos críticos.
- Verificar `supabase db diff`/validación de migraciones si la CLI y el proyecto lo soportan.
- Revisar logs de Edge Functions y errores SQL sin exponer secretos.
- Nunca aplicar una migración destructiva en producción sin backup, revisión y autorización.

Un módulo solo se considera terminado cuando:
1. La UI está implementada y es responsive.
2. Los datos se leen/escriben realmente en Supabase.
3. RLS y permisos están probados.
4. Estados de carga, vacío, éxito y error están cubiertos.
5. La operación crítica es transaccional e idempotente cuando aplica.
6. Las pruebas correspondientes pasan o las limitaciones están explícitas.
7. La documentación y los criterios de aceptación se actualizan.

## 13. Formato de respuesta del agente después de cada tarea

Al terminar cada bloque, informar:
- **Implementado:** comportamiento real agregado.
- **Archivos modificados:** lista exacta.
- **Migraciones:** nombre y efecto, o “ninguna”.
- **Seguridad:** RLS/permisos afectados y pruebas.
- **Pruebas ejecutadas:** comando y resultado real.
- **Pendientes/riesgos:** lo que no se pudo validar.
- **Siguiente paso:** una acción concreta, sin declarar el proyecto completo antes de tiempo.

## 14. Prompt de arranque recomendado

Cuando el usuario invoque este skill por primera vez, NO empieces reescribiendo la app. Primero audita el proyecto Flutter y Supabase existente. Presenta:
1. mapa de arquitectura actual,
2. módulos existentes y su estado real,
3. problemas críticos de seguridad/RLS,
4. problemas de integridad de ventas/inventario/pagos,
5. lista priorizada P0/P1/P2,
6. propuesta de migraciones incrementales,
7. primera tarea pequeña y verificable.

Después ejecuta la primera etapa aprobada. Si el usuario solicita explícitamente implementar directamente, puedes comenzar por el cambio de menor riesgo, pero conserva el protocolo de inspección, pruebas y no destrucción.
