---
name: flutter-responsive-adaptive
description: Usa esta skill al crear o modificar cualquier pantalla, layout, navegación, tabla o diálogo de la app Flutter POS. Garantiza responsive real en móvil, tablet y escritorio sin overflows.
---

# Responsive y adaptativo (móvil / tablet / desktop)

## Breakpoints (clases de ventana Material 3)
- compact: < 600
- medium: 600 – 1023
- expanded: ≥ 1024
Crear `Breakpoints` + extensión `context.windowSize`. Usar `MediaQuery.sizeOf` / `LayoutBuilder`, nunca `Platform.isX` para decidir layout.

## Navegación
- compact: `NavigationBar` inferior (máx. 5 destinos + "Más") o Drawer.
- medium: `NavigationRail` colapsado con iconos + tooltips.
- expanded: sidebar extendido (~240 px).
Un solo `AppShell` que decide; los módulos no conocen el menú.

## Contenido
- `ConstrainedBox(maxWidth: 1440)` centrado en pantallas grandes.
- Cero alturas fijas en contenedores con texto; usar `Flexible/Expanded/Wrap`, `SingleChildScrollView` o slivers. Toda pantalla debe poder hacer scroll.
- Grids con `SliverGridDelegateWithMaxCrossAxisExtent`, no con número fijo de columnas.
- Tablas: en compact se convierten en lista de cards (título, subtítulo, trailing con monto/estado).
- Diálogos: en compact usar bottom sheet o pantalla completa; en desktop diálogo centrado.

## Layout por módulo
- **POS**: expanded = grilla de productos + panel de orden fijo (~380 px a la derecha). medium = panel colapsable. compact = grilla + barra inferior con total que abre la orden en bottom sheet. Buscador/escáner siempre accesible y con autofocus en desktop.
- **Dashboard**: KPIs 4 columnas (expanded) → 2 (medium) → 1 o carrusel horizontal (compact).
- **Cuentas por cobrar / Inventario / Compras**: tabla en expanded, cards en compact, filtros en chips con scroll horizontal.
- **Cierre de caja**: dos paneles lado a lado en expanded; apilados en compact con el resumen/diferencia pegado abajo.

## Reglas de calidad
- Touch targets ≥ 48×48 dp.
- Probar con textScale 1.0 y 1.3 sin overflow.
- Soporte de teclado en desktop: Tab, Enter para confirmar, Esc para cerrar, atajos (F2 buscar, F4 cobrar).
- Tamaños a verificar: 360×640, 412×915, 768×1024, 1024×768, 1366×768, 1920×1080, y ventana redimensionada en vivo.
- Ningún "RenderFlex overflowed" en consola. Si aparece, la tarea no está terminada.
