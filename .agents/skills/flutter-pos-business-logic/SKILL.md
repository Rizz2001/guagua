---
name: flutter-pos-business-logic
description: Usa esta skill al implementar o revisar la lógica de negocio de los módulos del POS (ventas, multi-moneda USD/VES, inventario, combos, compras con CPP, cuentas por cobrar, dashboard, cierre de caja X/Z).
---

# Lógica de negocio del POS

## Dinero y moneda
- Nunca `double` para dinero. Usar enteros en centavos o el paquete `decimal`. Redondeo definido y centralizado.
- Moneda base: USD. VES se deriva con la **tasa vigente al momento de la transacción**, y esa tasa se guarda en cada venta/pago (snapshot). Cambiar la tasa nunca altera ventas pasadas.
- Tasa BCV: editable, validar > 0, guardar historial (fecha, usuario, valor).
- Formato es-VE para VES (1.234,56) y consistente para USD. Un solo `MoneyFormatter`.
- Pagos mixtos: una venta puede pagarse con varios métodos (efectivo USD, efectivo VES, Pago Móvil, Zelle, crédito). Calcular vuelto y en qué moneda se entrega.

## Ventas
- Operación atómica: crear venta + descontar stock + registrar pagos en una sola transacción de BD.
- Idempotencia: evitar doble cobro por doble tap.
- Venta a crédito no es dinero en caja hasta cobrarse ("Fina Rule"): se registra como cartera, no como ingreso de caja.
- Anulaciones y devoluciones con motivo, usuario y reverso de stock.

## Inventario
- Cada producto: unidades por caja/bulto, costo por unidad, precio, stock en unidades base.
- Desarmado: convertir 1 caja en N unidades, costo unitario = costo caja / N, movimiento registrado.
- Merma con motivo (vencido, daño, robo, consumo) y cantidad; baja stock y se reporta.
- Lotes/vencimiento con salida FEFO si aplica.
- Stock negativo bloqueado salvo configuración explícita.
- Combos: stock disponible = mínimo de (stock componente / cantidad requerida); al vender se descuentan componentes.

## Compras y CPP
- Costo promedio ponderado en cada compra: `nuevoCosto = (stock*cppActual + cantidad*costoCompra) / (stock + cantidad)`.
- Mostrar margen y sugerir precio al cambiar costo. Registrar proveedor, factura, fecha, moneda y tasa.

## Cuentas por cobrar
- Cliente con cupo; no permitir venta a crédito que exceda cupo (permitir override con rol admin).
- Abonos parciales, saldo, antigüedad en tramos: 0–7, 8–15, 16–30, +30 días.
- Índice de morosidad = saldo vencido > 15 días / cartera total.
- Recordatorio por WhatsApp con enlace `https://wa.me/<numero>?text=<mensaje codificado>` con monto y fecha.

## Cierre de caja X/Z
- X = informe parcial (solo lectura). Z = cierre definitivo, inmutable, genera reporte.
- Esperado por canal: fondo inicial + ventas cobradas en ese canal − vueltos entregados.
- Contado por canal: efectivo USD, efectivo VES (convertido a la tasa del turno para el total), Pago Móvil/Transferencia VES, Zelle.
- **El fondo inicial se cuenta una sola vez**: debe estar en el esperado Y en el contado, o en ninguno. Revisar: en la pantalla actual esperado = $670 y contado = $720 con fondo $50, es decir, el fondo se suma solo del lado del contado y genera un "sobrante" falso de $50.
- Mostrar diferencia por canal, no solo total. Si diferencia ≠ 0, exigir motivo antes de emitir Z.
- Los canales digitales se concilian contra el banco, no se "cuentan" como billetes.

## Dashboard
- Todos los KPIs salen de la misma fuente (repositorios/consultas), no de valores sueltos. Si hay turno con $670 esperados, "Dinero real en caja" no puede mostrar $0.
- Los badges de riesgo se calculan (morosidad 0% y 0 clientes → "Sin riesgo", no "Riesgo medio").
- Alertas: stock bajo, productos por vencer, deudas vencidas, diferencias de caja.

## Seguridad y auditoría
- Roles (cajero, supervisor, admin) con permisos por acción (anular, cambiar tasa, merma, cerrar caja).
- Bitácora de acciones sensibles. Offline-first con sincronización.

## Pruebas obligatorias
Tests unitarios para: conversión de moneda, pagos mixtos, CPP, desarmado, combos, morosidad/aging, diferencia de cierre de caja. Una fórmula sin test no se considera terminada.
