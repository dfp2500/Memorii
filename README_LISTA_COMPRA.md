# Sistema de Lista de Compra - Memorii

## Funcionalidades Implementadas

### 1. Modelo de Datos (`ProductoListaCompra`)
- **Campos principales:**
  - `id`: Identificador único del producto
  - `idUsuario`: ID del usuario propietario de la lista
  - `nombre`: Nombre del producto
  - `cantidad`: Cantidad especificada
  - `comprado`: Estado de compra (true/false)
  - `fechaCreacion`: Fecha de creación del producto
  - `fechaCompra`: Fecha cuando se marcó como comprado (opcional)

### 2. Controlador (`ListaCompraController`)
- **Funciones principales:**
  - `obtenerProductosUsuario()`: Obtiene todos los productos de un usuario
  - `agregarProducto()`: Agrega un nuevo producto a la lista
  - `cambiarEstadoCompra()`: Marca/desmarca un producto como comprado
  - `eliminarProducto()`: Elimina un producto de la lista
  - `verificarYResetearLista()`: Verifica si es lunes y resetea productos comprados
  - `inicializarListaPorDefecto()`: Crea lista inicial con productos predefinidos
  - `obtenerEstadisticas()`: Obtiene estadísticas de la lista

### 3. Reset Automático Semanal
- **Funcionamiento:**
  - Se ejecuta automáticamente cada vez que el usuario abre la app
  - Solo resetea si es lunes y después de las 00:00
  - Solo afecta a productos marcados como comprados
  - Los productos no comprados permanecen en la lista

### 4. Integración con la App
- **Verificación automática:** Se ejecuta en `InicioPage` al cargar datos
- **Inicialización:** Se crea lista por defecto si el usuario no tiene productos
- **Notificación visual:** Se muestra mensaje informativo los lunes

## Estructura de la Base de Datos

### Colección: `lista_compra`
```json
{
  "id_usuario": 123,
  "nombre": "Huevos",
  "cantidad": "20 unidades",
  "comprado": false,
  "fecha_creacion": "2024-01-15T10:30:00Z",
  "fecha_compra": null
}
```

## Flujo de Funcionamiento

1. **Primera vez:** Al acceder a la lista, se crea automáticamente con productos por defecto
2. **Uso diario:** El usuario puede agregar, marcar y eliminar productos
3. **Lunes:** Al abrir la app, se verifica si es lunes y se resetean los productos comprados
4. **Persistencia:** Todos los cambios se guardan en Firebase Firestore

## Características Técnicas

- **Persistencia:** Base de datos Firebase Firestore
- **Sincronización:** Tiempo real con la base de datos
- **Reset inteligente:** Solo resetea productos comprados, mantiene la lista base
- **Interfaz responsiva:** Diseño adaptativo con indicadores visuales
- **Manejo de errores:** Try-catch en todas las operaciones de base de datos

## Productos por Defecto

La lista inicial incluye 18 productos comunes:
- Huevos, Pollo, Atún, Pan integral
- Avena, Arroz integral, Verduras (cebollas, zanahorias, pimientos, espinacas, tomates)
- Frutas (plátanos, manzanas)
- Lácteos (yogures, leche)
- Otros (crema de cacahuete, almendras, aceite de oliva)

## Notas de Implementación

- El reset automático se ejecuta en `InicioPage` para asegurar que se verifique cada vez que el usuario abre la app
- Se incluye un mensaje informativo los lunes para notificar al usuario sobre el reset
- La lista se ordena automáticamente: productos no comprados primero, comprados al final
- Se incluye un botón de refresh en la barra de navegación para recargar manualmente 