---
name: flutter-ui-design
description: |
  Especialista en diseño de UI/UX, layouts adaptativos y sistema visual estilo POS Moderno (Clean Light POS / Tech Minimalist) para Flutter.
  Úsala al diseñar o construir interfaces gráficas, sistemas visuales, pantallas de autenticación divididas, dashboards con analíticas de riesgo, 
  grillas de punto de venta (POS), modales de cobro multimoneda (USD/VES), indicador y modal de tasa del día (BCV/Paralelo), diálogos de arqueo de caja (Cierre X/Z),
  diálogos de autorización anti-fraude, badging de combos/cajas, tarjetas de cobro moroso por WhatsApp, tarjetas de cupo de crédito/abonos, compras a proveedores (CPP),
  protección de vistas por roles RBAC, alertas de mermas/vencimientos, impresión térmica (58/80mm) y recibos PDF.

  Cuándo usar:
  - Al diseñar pantallas de inicio de sesión divididas (Hero image + Formulario flotante).
  - Al construir tableros/dashboards financieros con tarjetas de métricas (Capital en la calle, Morosidad %, Recaudado vs Proyectado), alertas de stock y gráficos de área.
  - Al implementar la grilla de productos POS (tarjetas de productos con badges, precios y botón '+') y la barra lateral de comanda/orden.
  - Al crear modales de cobro multimoneda con calculadora de vuelto en vivo (USD, Pago Móvil Bs., Zelle).
  - Al diseñar el indicador de Tasa del Día en la barra superior (ej. `Tasa BCV: 36.50 Bs/USD ✏️`) y modal de actualización para Admin/Supervisor.
  - Al diseñar el indicador de Cupo de Crédito del Cliente (Disponible vs Usado) en el POS y modales de abono parcial.
  - Al estructurar vistas de Compras a Proveedores y recálculo visual del Costo Promedio Ponderado (CPP).
  - Al aplicar renderizado condicional de vistas según el Rol RBAC del usuario (Ocultar costos y ganancias a Cajeros).
  - Al diseñar formularios de registro de Mermas (Botellas rotas, Consumo interno) y badges de lotes próximos a vencer (`⚠️ Vence en 15 días`).
  - Al diseñar modales de arqueo de caja (Cierre X/Z) con conteo de billetes y reporte de sobrante/faltante.
  - Al crear diálogos de autorización de anulación con clave de admin y motivo obligatorio.
  - Al diseñar pantallas de Cuentas por Cobrar con clasificación por días de mora (1-7 días 🟡, 8-15 días 🍊, 30+ días 🔴) y botón de cobro en 1 toque por WhatsApp (💬).
---

# Flutter UI & Design System Expert (Clean Modern POS Style)

Esta skill define el sistema de diseño visual, componentes de interfaz y patrones de maquetación en **Flutter** inspirados en plataformas POS modernas de alto nivel (estilo *Pione / Tech Minimalist POS*).

---

## 🎨 1. Sistema de Diseño Visual & Paleta de Colores

### 🎨 Paleta de Colores (Clean Modern Light)
- **Fondo de Pantalla (`Scaffold`):** `#F4F4F5` / `#F8FAFC` (Gris neutro ultrasuave).
- **Tarjetas y Contenedores:** `#FFFFFF` (Blanco puro) con bordes finos de 1px `#E4E4E7` / `#E2E8F0` y esquinas redondeadas (`BorderRadius.circular(16)` a `20`).
- **Botones Primarios y Elementos Activos:** `#18181B` / `#09090B` (Charcoal oscuro de alto contraste).
- **Acentos de Negocio:**
  - 🟢 **Verde Éxito/Ventas/WhatsApp:** `#22C55E` / `#25D366` (Líneas de gráficos, métricas positivas, cobro WhatsApp).
  - 🟡 **Mora Reciente (1-7 días) / Alerta Vencimiento:** Fondo `#FEF9C3`, Texto `#CA8A04`.
  - 🍊 **Mora Intermedia (8-15 días):** Fondo `#FFEDD5`, Texto `#EA580C`.
  - 🔴 **Mora Crítica / Exceso de Cupo / Merma:** Fondo `#FEE2E2`, Texto `#DC2626`.
  - 🟣 **Púrpura Combos / Mayor:** Fondo `#F3E8FF`, Texto `#7E22CE` (Badges de combos 🎁).

---

## 💱 2. Indicador de Tasa del Día & Modal de Actualización Manual (`daily-exchange-rate-management`)

- **Widget Indicador en Barra Superior (Top Bar):**
  - Chip redondeado suave en el header: `🇻🇪 Tasa BCV: 36.50 Bs/USD` con icono de lápiz `✏️`.
- **Modal de Actualización Manual de Tasa:**
  - Diálogo emergente interactivo para ingresar el nuevo valor de la tasa en **Bs/USD**.
  - Muestra la última fecha y hora de modificación (`Última actualización: Hoy 08:30 AM`).
  - **Control RBAC:** Si el usuario es Cajero, el ícono `✏️` está deshabilitado y requiere ingresar clave de Administrador/Supervisor para guardar cambios.

---

## 👥 3. Interfaz Adaptativa por Roles RBAC (`multi-user-rbac-security`)

- **Protección de Datos Sensibles:**
  - **Rol Cajero:** Oculta tarjetas de Margen de Ganancia Neta, Costo de Compra del Proveedor (`cost_usd`) y deshabilita la opción de editar la tasa de cambio del día.
  - **Rol Administrador / Supervisor:** Muestra métricas financieras completas, Costo Promedio Ponderado (CPP) y botón de configuración de tasas.

---

## 🛒 4. Compras, Mermas y Fechas de Vencimiento (`supplier-purchase-engine` & `spoilage-and-batch-control`)

- **Formulario de Compras a Proveedores:** Tabla de recepción de artículos con costo en USD y recálculo visual del Costo Promedio Ponderado (CPP).
- **Control de Lotes y Vencimientos:** Tag `⚠️ Lote 104 - Vence en 15 días` en productos.
- **Modal de Registro de Merma:** Selector de motivo (`Rotura / Daño`, `Vencido`, `Consumo Interno`).

---

## 💳 5. Indicador de Límite de Crédito & Abonos Parciales (`credit-sales-cashflow`)

- **Widget de Límite de Crédito en POS:** `Disponible: $80.00` / `Límite Total: $200.00` con barra de progreso de consumo.
- **Modal de Abonos Parciales:** Input de abono (USD o Bs.) ingresado a la caja activa.

---

## 📈 6. Métricas de Riesgo y Liquidez en Dashboard (`credit-portfolio-analytics`)

- Tarjetas de Capital Colocado en la Calle, Índice de Morosidad % y Recaudado vs Proyectado.

---

## 📲 7. Tarjetas de Gestión de Cobranza por WhatsApp (`debt-collection-automation`)

- Clasificación por antigüedad de mora (1-7d, 8-15d, 30d+) y botón `Cobrar por WhatsApp 💬`.

---

## 💵 8. Modal de Cobro Multimoneda & Vueltos Mixtos (`venezuela-fx-pos-engine`)

- Total USD destacado, equivalente en Bs. a tasa del día, métodos de pago simultáneos y calculadora de vuelto en vivo.

---

## 📦 9. Visualización de Combos y Precios Dinámicos (`inventory-units-and-combos` & `dynamic-pricing-engine`)

- Badges `🎁 Combo 3in1` y `📦 Caja x12`. Indicador `🏷️ Precio al Mayor Aplicado`.

---

## 🏦 10. Modal de Apertura, Arqueo y Cierre de Caja X/Z (`pos-cash-shift-control`)

- Formulario de conteo de billetes en USD y Bs. Comparativo de arqueo X/Z.

---

## 💻 11. Componentes Flutter Listos para Usar

### 📌 Tarjeta de Producto POS con Soporte para Combos y Cajas
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PosProductCard extends StatelessWidget {
  final String title;
  final String price;
  final String imageUrl;
  final VoidCallback onAdd;
  final List<String> tags;
  final bool isCombo;

  const PosProductCard({
    super.key,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.onAdd,
    this.tags = const [],
    this.isCombo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCombo ? const Color(0xFFC084FC) : const Color(0xFFE4E4E7),
          width: isCombo ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isCombo)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('🎁 COMBO', style: TextStyle(fontSize: 10, color: Color(0xFF7E22CE), fontWeight: FontWeight.bold)),
                    ),
                  ...tags.map((t) => Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(t, style: const TextStyle(fontSize: 10)),
                  )),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: const Color(0xFF09090B),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 16),
                    ),
                  ),
                  Text(
                    '\$$price',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF09090B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 36,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 70,
                  color: const Color(0xFFF4F4F5),
                  child: const Icon(Icons.local_cafe, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## ⚠️ Reglas Obligatorias de UI POS

1. **Sin sombras pesadas:** Usar bordes finos de 1px (`#E4E4E7`) en lugar de `BoxShadow` oscuros.
2. **Esquinas Redondeadas Consistentes:** Usar `Radius 14px` para elementos internos, `18px` para tarjetas y `24px` para modales.
3. **Botones de Alta Visibilidad:** Los botones primarios de checkout/login deben ser de ancho completo con color `#18181B` y texto en blanco `#FFFFFF`.
4. **Resistencia a Fallos de Red:** Los estados de carga e indicadores de sincronización offline deben integrarse con insignias suaves en la barra superior.
