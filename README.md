# Aula Puntos - SENATI

Aplicación Flutter local para administrar grupos, sesiones, asistencia, participación y reportes. Los datos se almacenan en SQLite y pueden exportarse a PDF, XLSX o copias JSON.

## Arquitectura

- `lib/core/database`: apertura SQLite, esquema, migraciones y datos semilla.
- `lib/features/<feature>/domain`: entidades, contratos de repositorio y casos de uso.
- `lib/features/<feature>/data`: adaptadores SQLite y exportadores de reportes.
- `lib/features/<feature>/presentation`: pantallas de cada módulo.
- `lib/main.dart`: inicializa SQLite y registra dependencias con Provider.

Las rutas antiguas `lib/database`, `lib/models`, `lib/screens` y `lib/services` se conservan como exports de compatibilidad.

## Base de datos

La versión 2 usa UUID v4 en claves primarias y foráneas. Al abrir una base de la versión 1, la migración convierte los IDs y remapea las relaciones dentro de la actualización SQLite, conservando los registros. La restauración también acepta copias antiguas con IDs numéricos.

## Ejecutar

```powershell
flutter pub get
flutter run
```

## Pruebas

```powershell
flutter test
flutter analyze
```
