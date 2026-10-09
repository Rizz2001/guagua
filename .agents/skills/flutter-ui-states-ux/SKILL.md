---
name: flutter-ui-states-ux
description: Usa esta skill al terminar o revisar cualquier pantalla de la app Flutter POS. Cubre estados vacíos/carga/error, formularios, microcopy, accesibilidad y una checklist de calidad antes de dar la tarea por completada.
---

# Estados, UX y checklist de calidad

## Cuatro estados por pantalla
Toda pantalla con datos implementa: **loading** (skeleton, no spinner suelto), **empty** (ilustración/ícono + explicación + botón de acción), **error** (mensaje claro + "Reintentar"), **data**. Una pantalla en blanco es un bug.
- Ejemplos de empty state: Cuentas por cobrar → "Aún no tienes clientes con crédito" + botón "Nuevo cliente / cupo". Inventario → "Aún no tienes productos" + "Nuevo producto" + importar. POS sin productos → enlace directo a Inventario.
- El empty state se centra en el área de contenido, nunca pegado a una esquina ni dentro de una columna angosta.

## Formularios
- Validación en línea, mensajes en español claros ("Ingresa un precio mayor a 0").
- `keyboardType` y `inputFormatters` correctos (decimal, entero, teléfono).
- Botón de guardar deshabilitado + indicador mientras guarda; evitar doble envío.
- Confirmación en acciones destructivas (anular, eliminar, cerrar Z) y opción deshacer cuando se pueda.
- Foco inicial lógico, Enter avanza/confirma, escáner de código de barras como entrada de teclado.

## Feedback
- SnackBar/toast para éxito y error no bloqueante; diálogo solo para decisiones.
- Acciones largas con progreso. Sin pantallas congeladas.

## Microcopy
- Español neutro-venezolano consistente, términos fijos (Tasa BCV, Merma, Cierre Z, Cupo). Sin mezclar inglés ("Fina Rule" visible al usuario debería explicarse o renombrarse).
- Sin emojis como sustituto de íconos en badges de estado; usar `StatusBadge` con ícono.

## Accesibilidad
- Contraste ≥ 4.5:1, `Semantics` en botones solo-ícono, tooltips en desktop, foco visible, no depender solo del color (rojo/verde) para diferencias de caja.

## Datos de prueba
Crear seeders de desarrollo (productos, clientes, ventas, turno) para verificar visualmente llenos, no solo vacíos.

## Checklist antes de dar por terminada una pantalla
- [ ] Usa solo tokens/tema y componentes compartidos
- [ ] Probada en compact, medium y expanded, sin overflow
- [ ] Tiene loading, empty, error y data
- [ ] Formularios validados y con etiquetas completas
- [ ] Montos formateados por moneda y alineados
- [ ] Lógica cubierta por tests y coherente con el resto de módulos
- [ ] Teclado y tooltips en desktop; targets ≥ 48dp en móvil
- [ ] `flutter analyze` sin warnings
