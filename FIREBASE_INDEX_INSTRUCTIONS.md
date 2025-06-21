# Instrucciones para Crear Índice en Firebase Console

## Problema
Firebase Firestore requiere un índice compuesto para consultas que filtran y ordenan al mismo tiempo.

## Solución 1: Crear Índice Manualmente (Recomendado)

### Pasos:
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto `memorii-fe062`
3. Ve a **Firestore Database** en el menú lateral
4. Haz clic en la pestaña **Índices**
5. Haz clic en **Crear índice**
6. Configura el índice así:

**Colección:** `lista_compra`
**Campos del índice:**
- `id_usuario` (Ascending)
- `fecha_creacion` (Ascending)
- `__name__` (Ascending)

7. Haz clic en **Crear**

### Enlace Directo:
Puedes usar este enlace directo para crear el índice:
```
https://console.firebase.google.com/v1/r/project/memorii-fe062/firestore/indexes?create_composite=ClJwcm9qZWN0cy9tZW1vcmlpLWZlMDYyL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9saXN0YV9jb21wcmEvaW5kZXhlcy9fEAEaDgoKaWRfdXN1YXJpbxABGhIKDmZlY2hhX2NyZWFjaW9uEAEaDAoIX19uYW1lX18QAQ
```

## Solución 2: Usar Consulta Simplificada (Ya Implementada)

He modificado el código para evitar el problema del índice:
- La consulta ahora solo filtra por `id_usuario`
- El ordenamiento se hace en memoria (en la app)
- Esto funciona pero es menos eficiente para listas grandes

## Recomendación

**Para mejor rendimiento:** Crea el índice manualmente usando la Solución 1.
**Para solución rápida:** El código actual ya funciona sin el índice.

## Nota Importante

Una vez creado el índice, puedes revertir el cambio en el controlador para usar la consulta optimizada:

```dart
// En lista_compra_controller.dart, línea ~15
final QuerySnapshot snapshot = await _listaCompraCollection
    .where('id_usuario', isEqualTo: idUsuario)
    .orderBy('fecha_creacion', descending: false)  // ← Volver a agregar esta línea
    .get();
``` 