# NEXORA Projects

Aplicación web de gestión personal de proyectos en español. Interfaz moderna con Next.js 15, TypeScript, Tailwind CSS y Supabase (PostgreSQL, Auth, Storage y Realtime). Configuración regional: `America/Bogota` y COP.

## Qué incluye esta versión

- Registro e inicio de sesión con Supabase Auth. Al crear la cuenta, una migración crea automáticamente el espacio personal y asigna el rol administrador.
- Proyectos con fechas, prioridad, presupuesto, estado y objetivo general.
- Objetivos medibles con línea base, meta, valor actual, sentido del indicador y peso.
- Actividades con fechas, prioridad, estado, avance, horas estimadas, objetivo asociado, subactividad y dependencia.
- Vistas de resumen, proyectos, tabla de actividades, Kanban con arrastrar y soltar, calendario mensual y cronograma tipo Gantt.
- Comentarios por actividad y actualización en tiempo real de actividades/comentarios.
- Documentos privados por proyecto (PDF, PNG, JPG, TXT, DOCX, XLSX), límite 8 MB, URL firmada para lectura.
- Reportes con indicadores, exportación CSV e impresión/guardar como PDF desde el navegador.
- Configuración de espacio, moneda, zona horaria y explicación de permisos.
- RLS por espacio, comprobaciones de rol en servidor, validación Zod, protección de dependencias cíclicas y control de concurrencia optimista para actividades.

> La aplicación está pensada inicialmente para una cuenta personal. El modelo de datos conserva organizaciones, membresías y roles para poder ampliar a equipos después. Notificaciones a otros usuarios no tienen efecto práctico en el modo de cuenta única.

## Requisitos

- Node.js 20.9 o superior.
- npm 10 o superior.
- Docker Desktop en ejecución.
- Supabase CLI (`npx supabase --version`) o instalación global de Supabase CLI.
- Visual Studio Code recomendado.

## Arranque local (recomendado)

1. Descomprime el ZIP y abre la carpeta `nexora-projects` en VS Code.
2. Instala dependencias:

   ```bash
   npm install
   ```

3. Inicia Supabase local desde la raíz del proyecto:

   ```bash
   npx supabase start
   ```

   La primera ejecución puede tardar mientras Docker descarga las imágenes. Al finalizar, la CLI imprime `API URL` y `anon key`.

4. Crea `.env.local` copiando `.env.example` y pega la URL y la anon key que imprimió Supabase:

   ```bash
   cp .env.example .env.local
   ```

   `NEXT_PUBLIC_SUPABASE_URL` normalmente será `http://127.0.0.1:54321`. Usa la anon key local que devuelve el comando, no inventes una.

5. Aplica migraciones y crea el bucket local:

   ```bash
   npx supabase db reset
   ```

   `db reset` aplica en orden las migraciones de `supabase/migrations` y el seed. La migración `0003` crea el bucket privado y prepara el alta automática del espacio personal.

6. Inicia Next.js:

   ```bash
   npm run dev
   ```

7. Abre <http://localhost:3000>, crea tu cuenta desde “Registrarme” y entra. En Supabase local las confirmaciones por correo están desactivadas por la configuración local.

## Supabase alojado (alternativa)

Si más adelante quieres usar un proyecto Supabase en la nube, copia su Project URL y anon/public key a `.env.local`. Aplica las tres migraciones en orden (`0001`, `0002`, `0003`) desde Supabase CLI enlazado al proyecto o SQL Editor. No expongas claves `service_role` en el navegador. Configura Auth Redirect URLs para la URL real de tu aplicación.

## Comandos

```bash
npm run dev        # desarrollo
npm run typecheck  # TypeScript
npm test           # pruebas unitarias
npm run build      # compilación de producción
npm start          # servidor compilado
npx supabase start # servicios locales
npx supabase stop  # detener servicios locales
```

## Flujo principal

1. Regístrate e inicia sesión.
2. Crea un proyecto con fechas, prioridad y presupuesto.
3. Crea objetivos medibles dentro del proyecto.
4. Crea actividades y, si aplica, asígnales objetivo, actividad principal o dependencia.
5. Actualiza estados y avance desde la tabla o arrastra tarjetas entre columnas Kanban.
6. Revisa calendario y cronograma para identificar vencimientos.
7. Añade comentarios y sube evidencias privadas.
8. Consulta el resumen y exporta actividades a CSV o imprime el reporte a PDF.

## Arquitectura

- `src/app`: rutas y composición de la aplicación.
- `src/components/dashboard.tsx`: vistas de trabajo y componentes de interacción.
- `src/lib/domain`: validación y métricas de negocio.
- `src/lib/supabase`: clientes SSR y navegador.
- `src/server`: operaciones autorizadas y documentos.
- `supabase/config.toml`: configuración de servicios locales.
- `supabase/migrations`: esquema, RLS, bucket y automatizaciones.
- `tests`: pruebas unitarias y notas de autorización/concurrencia.

## Métricas

- Avance ponderado: `Σ(avance_i × peso_i) / Σ(peso_i)`. Si no hay actividades o el peso total es cero, devuelve `null`.
- Tasa de finalización: `actividades completadas / total × 100`. Si no hay actividades, devuelve `null`.
- Cumplimiento de objetivo: compara el cambio desde la línea base hasta el valor actual contra el cambio esperado hasta la meta, según si el indicador debe aumentar o disminuir. El resultado se limita a 0–100 %; si la línea base y la meta coinciden, no se calcula.

## Seguridad y límites conocidos

- Las tablas de negocio usan Row Level Security; las operaciones de escritura verifican membresía/rol también en servidor.
- El alta inicial crea una organización personal, un espacio y una membresía `admin` para el nuevo usuario.
- El bucket `project-files` es privado. Las URL firmadas duran 60 segundos y se emiten tras comprobar membresía.
- Los archivos admitidos están limitados a 8 MB y a una lista de MIME permitidos. Esto no sustituye un antivirus; no subas archivos no confiables.
- La vista Kanban usa drag-and-drop nativo del navegador; el cronograma es una vista Gantt ligera, no un motor avanzado de planificación.
- El calendario muestra vencimientos de actividades. No incluye todavía sincronización externa con Google/Outlook.
- Los reportes PDF usan la función de impresión del navegador. El CSV está implementado; no hay generador XLSX dedicado.
- Realtime actualiza la vista al detectar cambios en actividades/comentarios. En una cuenta única la colaboración multiusuario y las notificaciones entre usuarios quedan inactivas.
- Antes de producción se requieren pruebas E2E, revisión de seguridad independiente, backups y restauración ensayada, monitorización, pruebas de carga y revisión de políticas de retención.

## Funciones que aún no forman parte de esta entrega

- Edición avanzada de todos los campos del proyecto y de la actividad desde un formulario de detalle; en esta versión se crean registros y se actualizan estados/avances.
- Administración visual de miembros y cambio de roles; la aplicación arranca con un único administrador y las reglas RLS ya contemplan los roles previstos.
- Exportación XLSX nativa, PDF generado en servidor, notificaciones push/correo, menciones, calendario externo y automatizaciones programadas.
- Editor visual de fases, dependencias con conectores gráficos en Gantt y panel de auditoría completo.

Estas funciones no deben confundirse con lo ya implementado.

## Respaldos

En un entorno Supabase gestionado, activa backups/PITR según tu plan. En local puedes respaldar PostgreSQL con `pg_dump` usando la conexión local que muestra `npx supabase status`. Los objetos de Storage requieren respaldo separado.
