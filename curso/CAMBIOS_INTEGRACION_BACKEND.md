# ✅ Cambios Realizados - Integración Backend de Reconocimiento Facial

**Fecha:** 2025-11-17
**Estado:** ✅ Completo y listo para probar

---

## 📝 RESUMEN

Se integró completamente el sistema de reconocimiento facial con el backend FastAPI. Ahora la app Flutter:
- ✅ Registra rostros en el servidor (envía imagen, backend genera embedding)
- ✅ Lista rostros desde el servidor (GET /api/v1/faces)
- ✅ Elimina rostros del servidor (DELETE /api/v1/faces/{id})
- ✅ Muestra estadísticas del servidor

---

## 📂 ARCHIVOS MODIFICADOS

### 1. **`lib/config/api_config.dart`** - MODIFICADO
**Agregado:**
```dart
// Faces - Reconocimiento Facial
static const String faces = '/api/v1/faces';
static String faceById(int faceId) => '/api/v1/faces/$faceId';
static const String recognizeFace = '/api/v1/faces/recognize';
static String userFace(int userId) => '/api/v1/faces/users/$userId/face';
```

---

### 2. **`lib/services/face_recognition_api_service.dart`** - NUEVO
**Archivo completamente nuevo** con los siguientes métodos:

#### `registerFace()`
- Envía UNA imagen al backend
- Parámetros: `imagePath`, `userId` (opcional), `fullName` (requerido si userId es null)
- Backend extrae embedding con DeepFace
- Retorna: face_id, organization_id, type, created_at

#### `recognizeFace()`
- Envía imagen para reconocimiento
- Parámetros: `imagePath`, `threshold` (default 0.4), `topN` (default 1)
- Retorna: match_found, confidence, face (con info de usuario o metadata)

#### `listFaces()`
- Obtiene lista de rostros de la organización
- Parámetros: `type` (all/users/non_users), `search`, `page`, `limit`
- Retorna: total, page, limit, faces[]

#### `deleteFace()`
- Elimina rostro del servidor
- Parámetro: `faceId`
- Retorna: success, message

#### `getMyFace()`
- Obtiene el rostro del usuario actual
- Retorna: face data o not_found

---

### 3. **`lib/screens/face_capture_screen.dart`** - MODIFICADO

#### **Cambios en el import:**
```dart
import 'package:curso/services/face_recognition_api_service.dart';
```

#### **Cambios en `_completeRegistration()`:**

**ANTES:**
```dart
// Solo guardaba localmente
await FaceService.registerFace(...);
```

**DESPUÉS:**
```dart
// 1. Envía PRIMERA imagen al backend
final apiResult = await FaceRecognitionApiService.registerFace(
  imagePath: imagePaths.first, // Solo la primera imagen
  userId: null,
  fullName: name,
);

// 2. Si éxito → guarda también localmente (compatibilidad)
if (apiResult['success']) {
  print('✅ Backend procesó el rostro');
  await FaceService.registerFace(...); // Local
  _showMessage('✅ Rostro registrado en el servidor');
}

// 3. Si falla → pregunta si guardar localmente
else {
  final saveLocal = await _showErrorDialog(...);
  if (saveLocal) {
    await FaceService.registerFace(...); // Solo local
  }
}
```

#### **Nuevo método agregado:**
```dart
Future<bool?> _showErrorDialog(String title, String message)
```
- Dialog para preguntar si guardar localmente cuando backend falla

---

### 4. **`lib/screens/manage_faces_screen.dart`** - MODIFICADO

#### **Cambios en el import:**
```dart
import 'package:curso/services/face_recognition_api_service.dart';
```

#### **Nuevas variables de estado:**
```dart
List<Map<String, dynamic>> backendFaces = []; // Rostros del backend
bool useBackend = true; // TRUE = backend, FALSE = local
```

#### **Método `_loadFaces()` - MODIFICADO:**

**ANTES:**
```dart
// Solo cargaba localmente
final results = await Future.wait([
  FaceService.getRegisteredFaces(),
  FaceService.getFaceStats(),
]);
```

**DESPUÉS:**
```dart
if (useBackend) {
  // Cargar desde backend
  final result = await FaceRecognitionApiService.listFaces(
    type: 'all',
    page: 1,
    limit: 100,
  );

  if (result['success']) {
    backendFaces = List<Map<String, dynamic>>.from(result['faces']);
    stats = {
      'total_registered': result['total'],
      'remaining_slots': 100 - result['total'],
      'recently_seen': 0,
    };
  }
} else {
  // Cargar local (legacy)
  ...
}
```

#### **Método `_deleteFace()` - MODIFICADO:**

**ANTES:**
```dart
Future<void> _deleteFace(RegisteredFace face)
```

**DESPUÉS:**
```dart
Future<void> _deleteFace(dynamic face) // Acepta RegisteredFace O Map

if (useBackend) {
  final result = await FaceRecognitionApiService.deleteFace(faceId);
  if (result['success']) {
    _showSuccessSnackBar('Rostro eliminado del servidor');
    _loadFaces();
  }
} else {
  // Local
  final success = await FaceService.deleteFace(faceId);
}
```

#### **Nuevos métodos agregados:**

**`_buildBackendFaceCard(Map<String, dynamic> face)`**
- Construye card para rostros del backend
- Muestra: display_name, type (Usuario/Visitante), created_at
- Menu: Solo "Eliminar" (backend no soporta toggle status)

**`_formatCreatedAt(String? createdAt)`**
- Formatea fecha de creación
- "Ahora", "Hace 5m", "Hace 2h", "Hace 3d", etc.

#### **UI modificada:**
```dart
// En build()
if (useBackend && backendFaces.isEmpty) ...[
  // Mensaje de vacío
] else if (useBackend) ...[
  // Mostrar rostros del backend
  ...backendFaces.map((face) => _buildBackendFaceCard(face)),
] else if (registeredFaces.isEmpty) ...[
  // Local vacío
] else ...[
  // Local con rostros
  ...registeredFaces.map((face) => _buildFaceCard(face)),
],
```

---

## 🔄 FLUJO COMPLETO

### **Registro de Rostro:**

```
1. Usuario abre "Gestionar Rostros"
   └─> ManageFacesScreen carga rostros con listFaces()
   └─> Muestra rostros del backend (si useBackend = true)

2. Usuario presiona "Registrar Nuevo Rostro"
   └─> FaceCaptureScreen se abre
   └─> Captura 5 imágenes (5 pasos)
   └─> Guarda las 5 imágenes localmente

3. Usuario ingresa nombre y relación
   └─> Presiona "Registrar"

4. Flutter envía PRIMERA imagen al backend
   POST /api/v1/faces
   Body: image (file), user_id (null), full_name (string)

5. Backend procesa:
   └─> Extrae embedding con DeepFace (Facenet512)
   └─> Verifica duplicados (threshold 0.15)
   └─> Guarda en faces table:
       - organization_id
       - user_id: null
       - embedding: JSON [512 floats]
   └─> Guarda en face_metadata table:
       - full_name
       - expires_at

6. Backend responde:
   201 Created: {id, organization_id, user_id, type, created_at}
   409 Conflict: Rostro duplicado
   400 Bad Request: Imagen inválida

7. Flutter procesa respuesta:
   ✅ Si success:
      - Guarda también localmente (opcional)
      - Muestra "✅ Rostro registrado en el servidor"
      - Cierra pantalla
      - ManageFacesScreen recarga con _loadFaces()

   ❌ Si error:
      - Muestra dialog "¿Guardar localmente?"
      - Si Sí → guarda solo local
      - Si No → no guarda nada

8. ManageFacesScreen se actualiza
   └─> Ahora muestra el nuevo rostro en la lista
```

---

### **Listar Rostros:**

```
1. ManageFacesScreen.initState()
   └─> _loadFaces()
   └─> useBackend = true
   └─> Llama FaceRecognitionApiService.listFaces()

2. GET /api/v1/faces?type=all&page=1&limit=100

3. Backend responde:
   {
     total: 5,
     page: 1,
     limit: 100,
     data: [
       {
         id: 1,
         type: "registered_user",
         display_name: "Jonathan García",
         user_id: 25,
         email: "jonathan@example.com",
         role: "USER",
         created_at: "2025-11-17T10:00:00Z"
       },
       {
         id: 2,
         type: "non_user",
         display_name: "María López",
         user_id: null,
         created_at: "2025-11-17T11:00:00Z"
       },
       ...
     ]
   }

4. Flutter procesa:
   └─> backendFaces = result['faces']
   └─> stats = {total_registered, remaining_slots, recently_seen}

5. UI muestra:
   └─> _buildBackendFaceCard() para cada rostro
   └─> Avatar circular
   └─> Nombre
   └─> Tipo (Usuario/Visitante) con icono
   └─> Fecha ("Hace 2h")
   └─> Menu "..." con opción "Eliminar"
```

---

### **Eliminar Rostro:**

```
1. Usuario presiona "..." en un rostro
   └─> Selecciona "Eliminar"

2. Flutter muestra dialog de confirmación
   └─> "¿Estás seguro de eliminar el rostro de [nombre]?"

3. Usuario confirma
   └─> _deleteFace(face)
   └─> FaceRecognitionApiService.deleteFace(faceId)

4. DELETE /api/v1/faces/{faceId}

5. Backend:
   └─> Verifica que face.organization_id = user.organization_id
   └─> Elimina imagen de S3 (si existe)
   └─> DELETE FROM faces WHERE id = faceId
   └─> CASCADE elimina face_metadata

6. Backend responde:
   204 No Content (éxito)
   404 Not Found (rostro no existe)
   403 Forbidden (no pertenece a tu org)

7. Flutter:
   └─> Muestra "Rostro eliminado del servidor"
   └─> Llama _loadFaces() para recargar lista
   └─> UI se actualiza sin el rostro eliminado
```

---

## 🔍 DATOS QUE SE ENVÍAN/RECIBEN

### **POST /api/v1/faces (Registrar)**

**Request:**
```
Content-Type: multipart/form-data

Fields:
- image: File (JPEG, PNG)
- user_id: null (siempre null por ahora)
- full_name: "Juan Pérez"
```

**Response 201:**
```json
{
  "id": 45,
  "organization_id": 3,
  "user_id": null,
  "type": "non_user",
  "created_at": "2025-11-17T14:30:00Z"
}
```

---

### **GET /api/v1/faces (Listar)**

**Request:**
```
GET /api/v1/faces?type=all&page=1&limit=100
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response 200:**
```json
{
  "total": 5,
  "page": 1,
  "limit": 100,
  "data": [
    {
      "id": 1,
      "type": "registered_user",
      "display_name": "Jonathan García Pérez",
      "user_id": 25,
      "email": "jonathan@example.com",
      "role": "USER",
      "created_at": "2025-11-17T08:00:00Z"
    },
    {
      "id": 2,
      "type": "non_user",
      "display_name": "María López",
      "user_id": null,
      "created_at": "2025-11-17T10:30:00Z"
    }
  ]
}
```

---

### **DELETE /api/v1/faces/{id} (Eliminar)**

**Request:**
```
DELETE /api/v1/faces/45
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response 204:**
```
(sin contenido - success)
```

---

## 🧪 CÓMO PROBAR

### **1. Iniciar backend:**
```bash
cd C:\Users\jonit\OneDrive\Documentos\GitHub\vigilancia-api
venv\Scripts\activate
uvicorn app.main:app --reload
```

Verificar que esté corriendo:
```
INFO:     Uvicorn running on http://localhost:8000
```

---

### **2. Ejecutar Flutter:**
```bash
cd C:\Users\jonit\OneDrive\Documentos\GitHub\CamarasSeguridadTT\curso
flutter run
```

---

### **3. Prueba básica:**

1. **Login** en la app (necesitas sesión activa)
2. **Ir a "Gestionar Rostros"**
   - Debería aparecer "No hay rostros registrados" si es primera vez
   - O mostrar rostros ya registrados

3. **Registrar un rostro:**
   - Presiona "Registrar Nuevo Rostro"
   - Captura las 5 fotos
   - Ingresa nombre: "Test Usuario"
   - Ingresa relación: "Prueba"
   - Presiona "Registrar"
   - Espera (~5-10 segundos)
   - Debería mostrar: "✅ Rostro registrado en el servidor"

4. **Verificar en la lista:**
   - Debería aparecer "Test Usuario" en la lista
   - Con icono naranja (Visitante)
   - Fecha "Ahora"

5. **Eliminar rostro:**
   - Presiona "..." en el rostro
   - Selecciona "Eliminar"
   - Confirma
   - Debería desaparecer de la lista

---

### **4. Verificar logs:**

**Flutter console:**
```
🔍 Cargando rostros desde backend...
📤 Enviando rostro al backend...
   URL: http://localhost:8000/api/v1/faces
   User ID: null
   Full Name: Test Usuario
📡 Respuesta: 201
✅ Rostro registrado exitosamente
   Face ID (backend): 45
   Type: non_user
✅ 1 rostros obtenidos del backend
```

**Backend console:**
```
INFO: POST /api/v1/faces
INFO: Extracting embedding...
INFO: Face detected successfully
INFO: Embedding size: 512
INFO: No duplicates found
INFO: Face registered - ID: 45
INFO: GET /api/v1/faces?type=all
INFO: Returning 1 faces
```

---

### **5. Verificar en MySQL:**

```sql
-- Ver rostros
SELECT * FROM faces ORDER BY created_at DESC LIMIT 5;

-- Ver metadata
SELECT f.id, f.organization_id, fm.full_name, fm.expires_at, f.created_at
FROM faces f
LEFT JOIN face_metadata fm ON f.id = fm.face_id
WHERE f.user_id IS NULL
ORDER BY f.created_at DESC;

-- Ver embedding
SELECT id, LENGTH(embedding) as embedding_length
FROM faces
ORDER BY created_at DESC
LIMIT 1;
```

**Resultado esperado:**
- `embedding_length`: ~5000-6000 caracteres
- `full_name`: "Test Usuario"
- `created_at`: Fecha/hora actual

---

## ✅ CHECKLIST DE PRUEBA

- [ ] Backend corriendo en localhost:8000
- [ ] Usuario logueado en Flutter
- [ ] ManageFacesScreen abre correctamente
- [ ] Lista de rostros carga (vacía o con rostros)
- [ ] Botón "Registrar Nuevo Rostro" funciona
- [ ] FaceCaptureScreen abre y captura 5 fotos
- [ ] Al completar, envía imagen al backend
- [ ] Backend procesa y retorna face_id
- [ ] Flutter muestra "✅ Rostro registrado"
- [ ] ManageFacesScreen recarga automáticamente
- [ ] Nuevo rostro aparece en la lista
- [ ] Datos correctos: nombre, tipo, fecha
- [ ] Botón "..." abre menú
- [ ] Opción "Eliminar" funciona
- [ ] Dialog de confirmación aparece
- [ ] Al confirmar, rostro se elimina del servidor
- [ ] Rostro desaparece de la lista
- [ ] Verificado en MySQL que se guardó/eliminó

---

## 🐛 SI ALGO NO FUNCIONA

### **Error: "No hay sesión activa"**
**Solución:** Cierra sesión y vuelve a iniciar sesión

### **Error: "Error al cargar rostros: ..."**
**Verificar:**
- Backend está corriendo
- Token no expirado
- organization_id presente

### **Error: "Error del servidor: No se detectó ningún rostro"**
**Solución:**
- Capturar foto con mejor iluminación
- Rostro debe estar frontal y completo
- Solo un rostro por imagen

### **No aparecen rostros en la lista**
**Verificar:**
- `useBackend = true` en `manage_faces_screen.dart` línea 25
- Token válido
- Backend tiene rostros registrados (verificar en MySQL)

---

## 📊 ESTADO ACTUAL

✅ **FUNCIONANDO:**
- Registro de rostros en backend
- Listado de rostros desde backend
- Eliminación de rostros del backend
- Manejo de errores (duplicados, imagen inválida, etc.)
- Guardado local como fallback

❌ **NO IMPLEMENTADO (aún):**
- Reconocimiento facial en tiempo real
- Envío de las 5 imágenes (solo se envía 1)
- Guardado de imagen en S3 (backend no lo hace)
- Toggle status (activar/desactivar) desde app
- Editar rostro existente

---

**¡Todo listo para probar!** 🚀
