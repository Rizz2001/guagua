---
name: cash-shift-analytics
description: |
  Especialista en el manejo de sesiones de caja (Cierre X, Cierre Z), fondos iniciales de cambio (sencillo) 
  y conciliación del flujo de dinero físico vs. digital.
---

# Cash Shift Analytics (Control de Turnos de Caja)

Al desarrollar la lógica de Cierres de Caja y Sesiones de Cajeros, respeta estas normativas:

## 🔐 1. Bloqueo por Turno Cerrado
- **Regla de Oro:** La pantalla de POS debe estar BLOQUEADA o deshabilitada si el usuario activo no tiene un turno de caja abierto (`status = 'OPEN'`) en la tabla `cash_shifts`.
- Todo cajero, al iniciar su jornada, debe declarar el "Fondo Inicial" (Dinero sencillo en caja para dar vueltos, ej. $20 en billetes de $1).

## 🧮 2. Arqueo Ciego y Diferencias
- Al cerrar el turno (Cierre Z), el sistema le debe pedir al cajero que declare **cuánto dinero físico** cuenta en la gaveta, SIN mostrarle cuánto dice el sistema que debería haber.
- Una vez declarado, el sistema calcula la diferencia (Faltante o Sobrante).

## 📊 3. Separación Estricta de Canales
- El arqueo debe desglosar obligatoriamente el dinero por canales para su auditoría:
  - Efectivo Físico Dólares.
  - Efectivo Físico Bolívares.
  - Transferencias/Pago Móvil (Bolívares).
  - Transferencias Zelle (USD).
- La sumatoria de las ventas en cada canal menos los vueltos entregados en físico, determinará la caja teórica.
