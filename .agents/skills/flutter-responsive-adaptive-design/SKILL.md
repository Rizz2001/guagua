---
name: flutter-responsive-adaptive-design
description: |
  Especialista en diseño adaptativo y responsivo en Flutter para Android (Mobile), PC Windows (Desktop) y Web.
  Úsala al implementar layouts flexibles, maquetación multipantalla, cálculo dinámico de columnas (GridView/Wrap),
  breakpoints de pantalla (Mobile < 600px, Tablet 600-1024px, Desktop > 1024px), prevención de desbordamientos visuales (Pixel Overflow),
  escalado de fuentes y componentes adaptativos (NavigationRail vs BottomNavigationBar).

  Cuándo usar:
  - Al estructurar pantallas que deben funcionar igual de bien en teléfono Android, Tablet y PC de escritorio.
  - Al definir breakpoints de pantalla y adaptar layouts de 1, 2 o 3 columnas.
  - Al solucionar errores de renderizado horizontal o vertical (`RenderFlex overflowed by X pixels`).
  - Al implementar componentes de navegación adaptativa (Sidebar en Desktop, Drawer/BottomNav en Mobile).
  - Al ajustar grillas de productos POS (`GridView.builder`) con `crossAxisCount` y `childAspectRatio` dinámicos via `LayoutBuilder`.
  - Al asegurar que todos los montos y textos de precios utilicen `FittedBox(fit: BoxFit.scaleDown)` para evitar desbordamientos en pantallas pequeñas.
---

# Flutter Responsive & Adaptive Design System Expert

Esta skill establece las reglas de oro, patrones de maquetación y utilidades en **Flutter** para garantizar que la aplicación **Guagua POS** renderice impecablemente en cualquier tamaño de pantalla (Mobile Android, Tablet, PC Windows y Navegadores Web) con **Cero Bugs Visuales (`Zero Pixel Overflow`)**.

---

## 📱 1. Breakpoints Estándar del Sistema

El diseño adaptativo se rige por 3 puntos de quiebre (`Breakpoints`) universales:

| Categoría | Ancho de Pantalla (`width`) | Estrategia de Disposición (Layout) | Navegación |
| :--- | :--- | :--- | :--- |
| **Mobile** | `< 600 px` | 1 columna apilada verticalmente. Modales full-screen. | `BottomNavigationBar` o `Drawer` colapsable. |
| **Tablet / Laptop** | `600 px - 1024 px` | 2 columnas (Contenido principal + Panel secundario). | `NavigationRail` compacto (solo iconos). |
| **Desktop POS** | `> 1024 px` | 3 columnas / Grilla expandida + Sidebar lateral fijo. | `Sidebar` expandido con nombres y roles. |

---

## 🛠️ 2. Patrones Antidesbordamiento (Zero Pixel Overflow Rules)

### 🔴 Regla 1: Precios y Montos Numéricos
Cualquier celda o etiqueta que renderice precios en USD o Bs. **NUNCA** debe usar un ancho rígido sin protección.
- **Solución Obligatoria:** Envolver siempre el texto del monto en `FittedBox`:
```dart
Flexible(
  child: FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      CurrencyEngine.formatUsd(amount),
      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20),
    ),
  ),
)
```

### 🔴 Regla 2: Textos Largos e Iconos en Filas (`Row`)
En filas (`Row`) donde coexisten íconos y descripciones largas (ej. subtítulos de tarjetas, nombres de productos):
- **Solución Obligatoria:** Envolver el `Text` en un `Expanded` o `Flexible` y definir `overflow: TextOverflow.ellipsis`:
```dart
Row(
  children: [
    const Icon(Icons.shield_outlined, size: 18),
    const SizedBox(width: 8),
    Expanded(
      child: Text(
        'RBAC • Transacciones Atómicas • Sincronización Offline',
        style: TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
)
```

### 🔴 Regla 3: Botones de Cabecera y Filtros de Categoría
No usar `Row` rígido para contenedores de botones en headers cuando la pantalla puede encogerse.
- **Solución Obligatoria:** Utilizar `Wrap` con `spacing` y `runSpacing`:
```dart
Wrap(
  spacing: 12,
  runSpacing: 12,
  alignment: WrapAlignment.spaceBetween,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: [
    StoreTitleBadge(),
    ExchangeRateBadge(),
    SearchInputBox(),
  ],
)
```

---

## 📐 3. Grilla POS Dinámica Adaptativa (`LayoutBuilder`)

Para las tarjetas de catálogo POS en `PosScreen` o `InventoryScreen`, la grilla debe adaptar su número de columnas (`crossAxisCount`) y relación de aspecto (`childAspectRatio`) según el espacio disponible en la tarjeta padre:

```dart
Expanded(
  child: LayoutBuilder(
    builder: (context, constraints) {
      final double width = constraints.maxWidth;
      final int crossAxisCount = width > 900 ? 4 : (width > 650 ? 3 : (width > 400 ? 2 : 1));
      final double aspectRatio = width > 900 ? 1.35 : (width > 650 ? 1.25 : 1.1);

      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return PosProductCard(product: products[index]);
        },
      );
    },
  ),
)
```

---

## 🧩 4. Widget Reutilizable: `ResponsiveLayout`

Componente utilitario para alternar automáticamente la vista según el breakpoint actual:

```dart
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width <= 1024;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width > 1024;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return desktop;
        } else if (constraints.maxWidth >= 600) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}
```

---

## 🛡️ 5. Lista de Chequeo de Verificación Responsiva Pre-Entrega

Antes de dar por completada cualquier vista:
- [ ] ¿Ejecutó `flutter test` en una resolución de pantalla de 1280x800 y en 400x800 para probar mobile y desktop?
- [ ] ¿Verificó que no haya ninguna franja amarilla y negra de desbordamiento (`RenderFlex overflowed`)?
- [ ] ¿Todos los textos largos dentro de `Row` están contenidos en `Expanded` con `TextOverflow.ellipsis`?
- [ ] ¿Todos los montos numéricos están envueltos en `FittedBox`?
- [ ] ¿Las cabeceras con múltiples botones o chips usan `Wrap` o `SingleChildScrollView` horizontal?
