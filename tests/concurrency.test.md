# Prueba de edición concurrente

Con dos sesiones autenticadas, leer la misma actividad (version=1). Enviar dos actualizaciones con `eq(version,1)`. Solo una debe devolver una fila y avanzar a version=2; la segunda debe devolver cero filas y mostrar conflicto. Releer y reintentar con la versión actual. Para cargas altas, migrar esta operación a una función SQL transaccional que haga UPDATE ... WHERE version = expected_version RETURNING.
