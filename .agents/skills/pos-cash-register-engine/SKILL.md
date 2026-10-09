---
name: pos-cash-register-engine
description: |
  Especialista en la lógica de la caja registradora (POS), facturación multimoneda y cobros en entornos hiperinflacionarios (Venezuela).
  Incluye reglas estrictas para el cálculo de vueltos mixtos, congelación de tasas de cambio, renderizado seguro de montos (FittedBox)
  y registro atómico de ventas mediante Supabase.
---

# POS Cash Register Engine (Reglas de Facturación y Cobro)

Al desarrollar la pantalla, controladores o lógica de Punto de Venta (POS), DEBES seguir estrictamente estas reglas:

## 💱 1. Lógica Multimoneda y Tasa de Cambio
- **Tasa Congelada:** Toda venta (`sales`) debe registrar obligatoriamente la tasa de cambio (`exchange_rate`) vigente en el segundo exacto de la transacción. Si la tasa cambia al día siguiente, el historial de facturas debe conservar la tasa vieja.
- **Visualización Dual Obligatoria:** Todos los totales y subtotales en la interfaz de caja deben mostrarse SIEMPRE en ambas monedas (USD y VES).

## 💵 2. Pagos Mixtos y Vueltos Complejos
- El sistema debe permitir pagos combinados (Ej. Total: $10 -> Paga $5 en efectivo y el equivalente a $5 en Pago Móvil Bs).
- **Calculadora de Vueltos:** Al recibir efectivo (USD o BS), si el monto ingresado supera el total, el sistema debe calcular el vuelto y permitir al cajero elegir cómo entregar ese vuelto (ej. Vuelto en Bs o Vuelto en USD físico).

## 🛡️ 3. Reglas de Renderizado en Flutter (UI Segura)
- **Cero Desbordamiento Visual:** Los precios en moneda local (VES) suelen tener muchos dígitos. Es OBLIGATORIO envolver cualquier texto que muestre un precio final dentro de un widget `FittedBox(fit: BoxFit.scaleDown)` o usar `TextOverflow.ellipsis` para evitar la pantalla roja de `RenderFlex overflowed`.

## 📦 4. Integración con Desarmado de Cajas
- Al confirmar el cobro, el controlador debe llamar de manera transparente a la función RPC `desarmar_caja_si_es_necesario` en Supabase por cada producto tipo unidad vendido, para garantizar que el stock cuadre sin intervención manual.
