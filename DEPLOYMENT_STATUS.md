# NEXORA Projects — preparación para publicación

## Estado comprobado

- Proyecto Next.js 15 / React 19 / TypeScript.
- Cliente Supabase SSR y cliente de navegador presentes.
- Variables requeridas por el código: `NEXT_PUBLIC_SUPABASE_URL` y `NEXT_PUBLIC_SUPABASE_ANON_KEY`.
- Migraciones SQL presentes: `0001_initial_schema.sql`, `0002_rls_policies.sql`, `0003_personal_workspace_and_dependencies.sql`.
- Moneda y zona horaria por defecto: COP y `America/Bogota`.

## Bloqueador antes de compartir con otra persona

La migración `0003_personal_workspace_and_dependencies.sql` crea un espacio personal independiente para cada usuario nuevo. La interfaz y las operaciones actuales no ofrecen un flujo completo de invitación/unión al mismo espacio. Por tanto, dos cuentas registradas por separado NO compartirán proyectos. No publicar como colaboración de dos personas hasta implementar y probar invitaciones/membresías y revisar RLS.

## Publicación prevista (cuando se cierre el bloqueador)

1. Crear un repositorio privado en GitHub y subir el contenido de esta carpeta (no subir `.env.local`, claves ni secretos).
2. Crear un proyecto Supabase Cloud. Aplicar las migraciones SQL en orden, después de revisarlas en un entorno de prueba.
3. En Supabase Auth, configurar la URL del sitio y las URLs de redirección de Vercel.
4. Importar el repositorio desde Vercel usando Next.js.
5. Configurar en Vercel:
   - `NEXT_PUBLIC_SUPABASE_URL`: Project URL de Supabase.
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`: publishable/anon key del proyecto.
   - `NEXT_PUBLIC_APP_URL`: URL HTTPS final de Vercel.
   - `NEXT_PUBLIC_DEFAULT_CURRENCY`: `COP`.
6. Ejecutar despliegue y validar registro, login, CRUD, RLS y Storage antes de compartir el enlace.

## Validación pendiente

No se pudo completar `npm install` en el entorno de preparación por límite de tiempo. Por ello no se afirma que `npm run typecheck`, `npm test` o `npm run build` hayan pasado. Ejecutarlos antes de producción.

Nunca poner una clave `service_role` en variables `NEXT_PUBLIC_*`, en el repositorio o en el navegador. No compartir contraseñas ni tokens en el chat.
