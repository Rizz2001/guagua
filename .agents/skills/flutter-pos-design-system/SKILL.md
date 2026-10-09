---
name: flutter-pos-design-system
description: Usa esta skill siempre que crees o modifiques UI en la app Flutter de POS/inventario. Define tokens, tema Material 3, componentes compartidos y reglas visuales para un diseño profesional y consistente.
---

# Design System para Guagua POS (Flutter)

## Regla de oro
Ningún widget de pantalla define colores, tamaños de fuente, radios ni espaciados "a mano". Todo sale de `AppTheme`, `AppSpacing`, `AppRadius` y los componentes compartidos.

## Tokens (crear en `lib/core/theme/`)
- **Color**: primario casi negro (#18181B), fondo #F4F4F5, superficie #FFFFFF, borde #E4E4E7, texto secundario #71717A. Semánticos: success (verde), warning (ámbar), danger (rojo), info/acento (violeta, usado para la tasa BCV). Cada semántico con variante `container` suave para badges.
- **Espaciado**: 4 / 8 / 12 / 16 / 24 / 32 / 48 (`AppSpacing.xs…xxl`).
- **Radios**: 12 (inputs, botones), 16 (cards), 24 (diálogos).
- **Tipografía**: una sola familia (google_fonts, ej. Plus Jakarta Sans). Escala: display 28, title 20, subtitle 16, body 14, caption 12. Montos con `FontFeature.tabularFigures()` para que las columnas alineen.
- **Elevación**: preferir borde 1px + sombra muy suave; nada de sombras pesadas.

## Tema
- `ThemeData(useMaterial3: true)` con `ColorScheme` completo.
- Configurar en el tema: `InputDecorationTheme`, `FilledButtonTheme`, `OutlinedButtonTheme`, `CardTheme`, `DialogTheme`, `ChipTheme`, `NavigationRailTheme`, `NavigationBarTheme`, `DataTableTheme`, `SnackBarTheme`.
- Preparar modo oscuro (útil en POS de noche) aunque se active después.

## Componentes compartidos (`lib/shared/widgets/`)
`AppPageHeader` (título + subtítulo + acciones, mismo padding en TODAS las pantallas), `AppCard`, `KpiCard`, `StatusBadge`, `AppTextField`, `MoneyField` (formato por moneda), `AppDialog` / `AppBottomSheet`, `EmptyState`, `LoadingState`, `ErrorState`, `AppDataTable`, `ConfirmDialog`, `CurrencyText`.
Antes de crear un widget nuevo, buscar si ya existe uno reutilizable.

## Formularios y diálogos
- Etiqueta SIEMPRE visible y completa (nunca truncada con "…"). Si no cabe, usar etiqueta arriba del campo o una sola columna.
- Grilla de 2 columnas solo si el ancho del diálogo ≥ 480; si no, 1 columna.
- Diálogo con `maxWidth` 560, contenido scrollable, botones fijos abajo, acción principal a la derecha.
- Helper text para unidades y moneda (ej. "Precio de venta (USD)").

## Consistencia visual
- Mismo header, padding de página (24 en desktop, 16 en móvil) y posición del título en todos los módulos.
- Estados activo/hover/pressed/focus/disabled definidos para todo elemento interactivo, incluyendo el ítem del menú lateral.
- Íconos de una sola familia y tamaño (20/24).
- Contraste mínimo 4.5:1.
