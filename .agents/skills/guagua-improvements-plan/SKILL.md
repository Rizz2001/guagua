---
name: guagua-improvements-plan
description: Plan maestro de implementación para las 4 grandes mejoras de arquitectura (Vuelto Cruzado, Estampado de Tasa, Desarmado Automático, Cola de Impresión).
---

# 🚀 Plan Maestro de Mejoras: Guagua POS

Este skill contiene el mapa de ruta obligatorio para implementar las 4 grandes mejoras arquitectónicas en el sistema Guagua. Cuando se trabaje en cualquiera de estas mejoras, debes seguir este orden y reglas estrictas.

## 📋 Fases del Plan

### Fase 1: Calculadora de Vuelto Cruzado Inteligente 🧮
**Objetivo:** Permitir pagos multimoneda complejos (Ej: Dando un billete $20 + 50 Bs -> Dar vuelto de $2 y 10 Bs) en el modal de cobro.
**Reglas:**
- **UI:** El modal (`payment_modal_dialog.dart`) debe ser extremadamente limpio (Tech Minimalist). Mostrar claramente "Faltante" y "Sugerencia de Vuelto".
- **Lógica:** Actualizar `currency_engine.dart` para soportar `calcularVuelto(pagos[], totalUSD, tasaBCV, fondoCajaBs, fondoCajaUSD)`.
- **Responsive:** Usar `FittedBox` para todos los montos mostrados en pantalla. Cero pixel overflows.

### Fase 2: Estampado Inmutable de Tasa de Cambio 🔒
**Objetivo:** Proteger la venta ante cambios de tasa (BCV/Paralelo) mientras se está offline.
**Reglas:**
- Todo modelo que viaje a Hive/Supabase (CartItem, Sale, Order) debe "congelar" la tasa de cambio en el segundo que se presionó "Cobrar".
- Agregar campos: `exchangeRate`, `usdPriceAtSale`, `bsPriceAtSale`.
- Al sincronizar (Outbox), NUNCA usar la tasa actual de Supabase, sino la que viene en la orden.

### Fase 3: Desarmado Automático (RPC Supabase) 📦
**Objetivo:** Vender unidades sueltas aunque el sistema diga que quedan 0, descontando automáticamente de las cajas disponibles.
**Reglas:**
- La lógica fuerte va en PostgreSQL mediante funciones RPC (`supabase.rpc()`).
- Flujo Atómico: `BEGIN -> restar caja -> sumar 12 uds -> descontar venta -> COMMIT`.
- Reflejar inmediatamente el cambio en `inventory_controller.dart`.

### Fase 4: Cola de Impresión Local (Print Spooler) 🖨️
**Objetivo:** No perder la factura (ni el ticket visual) si la impresora se atasca o queda sin papel.
**Reglas:**
- Usar Hive para crear una caja `print_queue`.
- Crear un `print_spooler_service.dart` que intente imprimir y, si falla el hardware, guarde en la cola.
- Proveer un botón/snackbar visual amarillo para "Reintentar Impresión".

## 🛡️ Principios Transversales para Todas las Fases
1. **Zero Dead Code:** Elimina todo el código viejo reemplazado durante estas fases.
2. **Strict No Mock Data:** Nada de variables estáticas para simular, usar siempre Riverpod y estados asíncronos.
3. **Refactorización Atómica:** Actualiza todos los llamados a una función si cambias su firma.
