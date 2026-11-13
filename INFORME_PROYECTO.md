# Informe del Proyecto: Aula Puntos - SENATI

**Fecha de revisión:** 13 de noviembre de 2026  
**Alcance:** estructura, persistencia SQLite, migración UUID, repositorios, pantallas, reportes, respaldos, duplicación de código y pruebas.

## 1. Resumen ejecutivo

Aula Puntos SENATI es una aplicación Flutter local para administrar grupos, estudiantes, sesiones, asistencia y participación, además de producir reportes y copias de seguridad. SQLite es la persistencia principal y no se observó dependencia de un servidor para el uso normal.

El proyecto cuenta con una estructura feature-first con capas `domain`, `data` y `presentation`; usa Provider para registrar dependencias y tiene una migración desde el esquema SQLite v1 con IDs enteros al esquema v2 con UUID v4. Las pruebas cubren la creación inicial, migración, restauración de backups antiguos, generación XLSX, montaje del dashboard y conservación de sesiones durante inserciones consecutivas.

Se corrigieron dos problemas durante la revisión: el upsert de asistencia ahora incluye el UUID requerido, y la inserción de grupos ya no reemplaza destructivamente un grupo cuyo código existe. Se agregó cobertura para ambas rutas y para asegurar que la creación de nuevas sesiones no elimina las anteriores. Siguen pendientes el cast de UUID en “deshacer último punto” y la posible inflación de asistencia en el consolidado global. El respaldo todavía se copia al portapapeles en vez de guardarse directamente como archivo.

## 2. Arquitectura y estructura

- `lib/core/database`: apertura de SQLite, esquema, migración y datos semilla.
- `lib/features/groups`: entidades y operaciones de grupos, instructores, estudiantes y matrícula.
- `lib/features/sessions`: sesiones académicas.
- `lib/features/attendance`: asistencia y estados válidos.
- `lib/features/points`: actividades y eventos de puntuación.
- `lib/features/reports`: consultas de reportes y exportación PDF/XLSX.
- `lib/features/dashboard`: dashboard e indicadores.
- `lib/features/backup`: respaldo, restauración y reinicio.
- `lib/main.dart`: inicialización multiplataforma de SQLite y registro de dependencias con Provider.

Las pantallas canónicas están en `lib/features/*/presentation`. Las rutas antiguas de `lib/screens`, `lib/models`, `lib/database` y `lib/services` se conservan como exports de compatibilidad; las pantallas antiguas ya no mantienen una segunda implementación.

La revisión de duplicados encontró una sola definición por pantalla, entidad y servicio en `lib/features`. Las rutas antiguas de `screens`, `models`, `database` y `services` son archivos export de una línea, no implementaciones duplicadas. El escaneo por hash no encontró archivos de código idénticos dentro de `lib`. Fuera de `lib` hay coincidencias esperables en recursos multiplataforma, como iconos/launch images a distintas resoluciones y configuraciones de proyectos nativos; no se recomienda eliminarlas automáticamente.

Los contratos de repositorio y casos de uso existen por feature. Varios adaptadores y casos de uso son delegaciones sencillas hacia `DatabaseHelper`; este helper todavía concentra una parte considerable del acceso SQL, migraciones, backups y consultas agregadas. Provider se usa principalmente para inyección de dependencias; las pantallas siguen manteniendo buena parte de su estado con `StatefulWidget` y `setState`.

## 3. Persistencia y reglas de negocio

La versión 2 crea ocho tablas: `instructores`, `grupos`, `estudiantes`, `grupo_estudiantes`, `sesiones`, `asistencias`, `actividades` y `participaciones`.

Las claves primarias y foráneas de las entidades usan valores UUID v4 almacenados como texto. `grupo_estudiantes` usa una clave primaria compuesta por grupo y estudiante. La apertura de la base activa `PRAGMA foreign_keys = ON`; la tabla de asistencias restringe los estados a `Presente`, `Tardanza`, `Falta` y `Justificado`, y limita los registros por estudiante/sesión.

La migración v1→v2 reasigna los IDs y remapea sus referencias dentro de la actualización SQLite, conservando las filas. La restauración también acepta backups con IDs numéricos y genera nuevos UUID para sus relaciones. La semilla crea un instructor, un grupo de demostración, ocho estudiantes, una sesión, asistencias y actividades.

## 4. Funcionalidades disponibles

- Dashboard con métricas de grupos, estudiantes, sesiones y puntos.
- Creación y consulta de grupos; importación y exportación CSV del padrón.
- Creación de sesiones e inicialización de asistencias.
- Marcación de asistencia y resumen por estado.
- Asignación rápida de puntos, historial, ranking y acción para deshacer.
- Consolidado por sesión o por grupo.
- Exportación de reportes a PDF y XLSX; CSV copiable para compartir.
- Exportación de backup JSON al portapapeles, restauración mediante pegar JSON y reinicio a datos de demostración.

## 5. Hallazgos priorizados

### Resuelto: código de grupo duplicado podía reemplazar datos existentes

El formulario propone el código `202601` cada vez que se abre ([grupos_screen.dart](lib/features/groups/presentation/grupos_screen.dart#L57)). Anteriormente, la inserción usaba `ConflictAlgorithm.replace`, lo que podía reemplazar la fila y borrar sesiones y datos relacionados por cascada. Ahora [insertGrupo](lib/core/database/database_helper.dart#L537) usa la inserción normal de SQLite, que rechaza el código duplicado sin tocar el registro anterior. La prueba [database_migration_test.dart](test/database_migration_test.dart#L125) verifica que el grupo y sus sesiones quedan intactos.

La pantalla informa el error de unicidad al usuario; convendría mejorar ese mensaje para indicar directamente que el código ya está registrado.

### Resuelto: insertar asistencia no generaba la clave primaria requerida

El esquema exige `asistenciaId TEXT PRIMARY KEY NOT NULL`. El `INSERT ... ON CONFLICT` no enviaba esa columna y producía `NOT NULL constraint failed: asistencias.asistenciaId`. [registrarOActualizarAsistencia](lib/core/database/database_helper.dart#L775) ahora genera UUID al insertar y, si ya existe la combinación estudiante/sesión, actualiza el estado y la fecha conservando el ID existente. La prueba de creación inicial cubre inserción y actualización sin duplicar la marca ([database_migration_test.dart](test/database_migration_test.dart#L17)).

### Resuelto: crear una sesión conserva las anteriores

La inserción de sesiones genera UUID y no ejecuta un reemplazo ni un borrado; una prueba crea dos sesiones consecutivas y confirma que la sesión semilla y las nuevas siguen presentes. Está cubierta en [database_migration_test.dart](test/database_migration_test.dart#L93). Se identificó además la sustitución destructiva de grupos por código repetido descrita arriba, que sí podía eliminar las sesiones de ese grupo; esa ruta ya está corregida.

### Alta: “Deshacer último punto” falla con UUID

[deshacerUltimaParticipacion](lib/core/database/database_helper.dart#L888) convierte `participacionId` a `int`, pero la columna ahora devuelve un `String` UUID. Al invocar la acción, se lanza una excepción antes de borrar la participación.

**Recomendación:** tratar el ID como `String` desde el resultado SQL hasta la condición de borrado y agregar una prueba que cubra el botón de deshacer.

### Media: los conteos de asistencia del consolidado global pueden inflarse

En [getConsolidadoReporte](lib/core/database/database_helper.dart#L1024), el consolidado global une sesiones, asistencia y participaciones antes de aplicar `SUM`. Si un estudiante tiene varias participaciones en una sesión, la fila de asistencia se repite por cada participación y los conteos de presentes, tardanzas, faltas o justificados aumentan artificialmente.

**Recomendación:** agregar asistencia y puntos por separado en subconsultas/CTE antes de unir los totales por estudiante.

### Media: los errores al iniciar SQLite quedan ocultos

[main.dart](lib/main.dart#L39) captura cualquier error al abrir o migrar la base, lo imprime y continúa ejecutando la aplicación. Las pantallas pueden intentar consultar una base que no se inicializó correctamente y fallar después sin ofrecer recuperación clara.

**Recomendación:** exponer un estado de inicialización visible, bloquear las operaciones dependientes de SQLite mientras falla y ofrecer reintento o diagnóstico.

### Media: respaldo JSON manual

La pantalla de backup muestra el contenido JSON y ofrece copiarlo al portapapeles ([backup_screen.dart](lib/features/backup/presentation/backup_screen.dart#L118)). Restaurar requiere pegar el contenido. No hay un diálogo integrado para guardar o seleccionar un archivo JSON, por lo que la operación depende de pasos manuales.

**Recomendación:** integrar guardado/selección de archivos o compartir el JSON como archivo, con soporte específico por plataforma.

## 6. Pruebas y estado del análisis

La suite Flutter reportó **7 pruebas aprobadas**. Incluye la creación con datos semilla UUID, inserción y actualización de asistencia sin duplicados, creación de varias sesiones, rechazo seguro de códigos de grupo duplicados, migración desde v1, restauración de un backup numérico, generación/lectura de XLSX y smoke test del dashboard.

`flutter build web` completó correctamente. El dry run de Wasm mostró avisos provenientes de `image 4.3.0`, pero no impidieron la compilación web estándar.

La última ejecución de `flutter analyze` mostró **30 diagnósticos de nivel `info` y ningún error de análisis**. El comando terminó con código 1 por esos diagnósticos, principalmente deprecaciones de Flutter (`value`, `withOpacity`), sugerencias `const`, usos de `BuildContext` tras operaciones asíncronas y un import innecesario en la prueba de migración.

El estado de terminal más reciente reporta que `flutter run` terminó con código 0. `flutter build web` también completó; el dry run de Wasm advirtió sobre la dependencia `image 4.3.0`, sin impedir el build estándar.

## 7. Conclusión

La aplicación dispone de persistencia local, migración UUID, módulos funcionales por feature y pruebas de las rutas principales. Las copias de pantalla fueron retiradas; las rutas históricas se conservan como exports. También quedaron corregidos el upsert de asistencia y la eliminación en cascada causada por códigos de grupo duplicados. Los pendientes funcionales principales son el cast UUID al deshacer puntos y la agregación de asistencia del consolidado global; además, el respaldo puede mejorarse con guardado de archivos integrado.
