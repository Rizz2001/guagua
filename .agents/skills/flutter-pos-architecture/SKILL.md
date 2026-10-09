---
name: flutter-pos-architecture
description: Usa esta skill al crear módulos, servicios, estado o base de datos en la app Flutter POS. Define arquitectura feature-first, gestión de estado, persistencia offline y convenciones de código.
---

# Arquitectura Flutter POS

## Estructura feature-first
```
lib/
  core/        (theme, router, utils, formatters, errors, constants)
  shared/      (widgets reutilizables, extensiones)
  data/        (db local, DAOs, dto, repositorios impl)
  domain/      (entidades, value objects Money/Rate, repositorios abstractos, casos de uso)
  features/
    pos/ dashboard/ receivables/ inventory/ purchases/ cash_close/ settings/
      presentation/ (pages, widgets, controllers)
```
Dependencias: presentation → domain ← data. La UI nunca habla con la BD directamente.

## Convenciones
- Estado con Riverpod (`AsyncNotifier`); pantallas solo observan y despachan.
- Navegación con `go_router` y rutas por módulo, con guardas por rol.
- Persistencia offline con `drift` (SQLite) y migraciones versionadas; transacciones para operaciones compuestas.
- Value objects `Money`, `ExchangeRate`, `Quantity` en dominio; sin `double` de dinero circulando.
- Modelos inmutables (`freezed`/`json_serializable`).
- Errores tipados (`Result`/`AppFailure`), nunca `catch` vacío.
- Inyección de dependencias por providers; fácil de mockear.

## Calidad
- `flutter_lints` estricto, `flutter analyze` limpio.
- Tests: unit (dominio), widget (componentes y estados), golden tests de pantallas clave en 3 tamaños, integración del flujo vender → cobrar → cerrar caja.
- Archivos < 300 líneas; widgets grandes divididos.
- README y ARCHITECTURE.md actualizados al agregar un módulo.
