# Pruebas de autorización e integración (ejecutar contra Supabase de pruebas)

1. Crear dos organizaciones A y B, cada una con un workspace y usuario miembro.
2. Autenticar usuario A y consultar `projects` del workspace B: RLS debe devolver cero filas.
3. Intentar insertar proyecto en workspace B desde sesión A: debe fallar.
4. Asignar a usuario externo B como `assignee_id` en una actividad de A: no debe concederle lectura ni escritura en A.
5. Usuario `observer`: lectura permitida; insert/update de proyecto y actividad denegados.
6. Usuario `collaborator`: solo puede actualizar actividad asignada o con fila en `activity_collaborators`; no puede crear proyectos ni objetivos.
7. Usuario `project_director`: puede gestionar proyectos y actividades dentro de su workspace, no membresías ni organizaciones.
8. Probar dependencias A→B, B→C y C→A: la última debe fallar por ciclo.

No se marcan como ejecutadas: requieren credenciales y una instancia Supabase de pruebas.
