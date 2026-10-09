---
name: client-credit-engine
description: |
  Especialista en el módulo de Cuentas por Cobrar (Fiado), gestión de límites de crédito, amortización de deudas, 
  y cobranza automatizada vía WhatsApp.
---

# Client Credit Engine (Motor de Deudas y Cobranzas)

Al desarrollar el módulo de clientes, créditos y deudas, aplica estas reglas de negocio:

## 🚫 1. Bloqueo de Límite de Crédito
- Todo cliente tiene un `credit_limit` asignado.
- Antes de procesar cualquier venta con método de pago "CRÉDITO", el controlador frontend debe verificar localmente el saldo o confiar en el RPC `validar_cupo_credito` de la base de datos para bloquear transacciones que excedan el límite asignado.

## 💸 2. Abonos Parciales (Amortización)
- Un cliente no está obligado a pagar una factura completa. El sistema debe permitir registrar "Abonos" a su deuda global o a una factura específica (`pending_amount_usd`).
- Si el `pending_amount_usd` llega a cero, el sistema marca automáticamente la factura como `is_paid = true`.

## 💬 3. Cobranza Integrada (WhatsApp)
- En la tabla y vista de Cuentas por Cobrar, debe existir siempre un botón de "Notificar".
- Este botón usará el paquete `url_launcher` para abrir WhatsApp (`wa.me/+58...`) con un mensaje dinámico pre-generado. 
- *Ejemplo de mensaje:* "Hola {Nombre}, le recordamos que tiene un saldo pendiente de {Deuda} USD en {NombreTienda}. Agradecemos su pronto pago."
