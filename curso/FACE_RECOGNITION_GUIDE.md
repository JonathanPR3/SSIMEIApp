# Guía de Implementación - Reconocimiento Facial

## 📋 Resumen de la Implementación

✅ **COMPLETADO (2025-11-17):** Sistema de reconocimiento facial **completamente integrado con backend FastAPI usando DeepFace/Facenet512**. La app ahora puede:
- Registrar rostros enviando imagen al backend para generar embedding (512 dimensiones)
- Reconocer rostros comparando contra base de datos usando distancia coseno
- Listar rostros registrados de la organización
- Probar reconocimiento facial en tiempo real con cámara frontal

## 🗂️ Estructura de Archivos Creados/Modificados

### Nuevos Archivos (2025-11-17)

1. **`lib/services/face_recognition_api_service.dart`** ⭐ NUEVO
   - Servicio REAL conectado al backend FastAPI
   - `registerFace()` - Envía imagen al backend para registro
   - `recognizeFace()` - Reconoce rostro comparando contra BD
   - `listFaces()` - Lista todos los rostros de la organización
   - `deleteFace()` - Elimina rostro
   - `getMyFace()` - Obtiene rostro del usuario actual
   - Incluye manejo de `MediaType.parse()` para content-type correcto

2. **`lib/screens/test_face_recognition_screen.dart`** ⭐ NUEVO
   - Pantalla de prueba con preview de cámara frontal
   - Captura foto y envía a `/api/v1/faces/recognize`
   - Muestra resultado: reconocido/no reconocido
   - Información detallada: nombre, tipo, confianza, face_id
   - Estados visuales (borde verde si reconoce)

### Archivos Modificados (2025-11-17)

3. **`lib/config/api_config.dart`**
   - Agregados endpoints de reconocimiento facial:
     - `POST /api/v1/faces` - Registrar rostro
     - `GET /api/v1/faces` - Listar rostros
     - `DELETE /api/v1/faces/{id}` - Eliminar rostro
     - `POST /api/v1/faces/recognize` - Reconocer rostro
     - `GET /api/v1/faces/users/{userId}/face` - Rostro de usuario

4. **`lib/screens/face_capture_screen.dart`**
   - Mantiene proceso de captura de 5 imágenes (UX sin cambios)
   - **Envía SOLO primera imagen al backend** para generar embedding
   - Backend procesa con DeepFace/Facenet512 automáticamente
   - Manejo de errores con dialog para guardar localmente si falla backend
   - Guarda también localmente para compatibilidad

5. **`lib/screens/manage_faces_screen.dart`**
   - **Carga rostros desde backend** en lugar de almacenamiento local
   - Toggle `useBackend = true` (usa API real)
   - Soporta ambos tipos de rostros:
     - `registered_user` - Usuario registrado (tiene user_id)
     - `non_user` - Visitante (usa face_metadata con full_name)
   - Manejo correcto de tipos de ID (int backend vs String local)
   - Eliminación de rostros vía API

6. **`lib/screens/settings/SettingsScreen.dart`**
   - Agregada nueva opción en sección "Rostros"
   - "Probar Reconocimiento Facial" con subtítulo "Modo de prueba"
   - Navegación a `TestFaceRecognitionScreen`
   - Modificado `_buildSettingsCard()` para aceptar `subtitle` opcional

## 📸 ¿Cómo Funciona Actualmente?

### Flujo de Registro de Rostro (Backend Integrado)

1. Usuario abre "Gestionar Rostros" desde Settings
2. Presiona "Registrar Nuevo Rostro"
3. La app captura **5 imágenes** (UX sin cambios):
   - Paso 1: Rostro centrado
   - Paso 2: Girado a la izquierda
   - Paso 3: Girado a la derecha
   - Paso 4: Sonriendo
   - Paso 5: Expresión neutral

4. **Backend procesa SOLO la primera imagen:**
   - Se envía a `POST /api/v1/faces` con multipart/form-data
   - Backend usa DeepFace con modelo Facenet512
   - Genera embedding de 512 dimensiones
   - Verifica que no sea duplicado (threshold 0.15)
   - Guarda en tabla `faces` con `organization_id`

5. Al completar, el usuario ingresa:
   - Nombre completo
   - Se crea como `type: non_user` (visitante)
   - O se asocia con `user_id` si es usuario registrado

6. **Almacenamiento dual:**
   - ✅ Backend: Embedding en MySQL (JSON con 512 valores)
   - ✅ Local: 5 imágenes guardadas para compatibilidad

### Flujo de Reconocimiento (Prueba en Tiempo Real)

1. Usuario abre Settings → "Probar Reconocimiento Facial"
2. Se abre cámara frontal con preview
3. Usuario presiona "Capturar y Reconocer"
4. **Backend procesa:**
   - Imagen se envía a `POST /api/v1/faces/recognize`
   - Extrae embedding con DeepFace/Facenet512
   - **Compara contra TODOS los rostros** de la organización
   - Calcula distancia coseno con cada embedding guardado
   - Filtra por threshold (default 0.4)
   - Retorna el mejor match (top_n=1)

5. **Respuesta muestra:**
   - ✅ Reconocido: Nombre, tipo (Usuario/Visitante), confianza, face_id
   - ❌ No reconocido: Mensaje de que no hay coincidencia

### Backend - Modelo de Datos

**Tabla `faces`:**
```sql
- id (int, PK, auto_increment)
- organization_id (bigint, FK)
- user_id (bigint, FK, nullable) -- Si es registered_user
- type (enum: 'registered_user', 'non_user')
- embedding (json) -- Vector de 512 dimensiones [0.123, 0.456, ...]
- created_at (timestamp)
- updated_at (timestamp)
```

**Tabla `face_metadata` (para visitantes):**
```sql
- id (int, PK)
- face_id (int, FK)
- full_name (varchar 255)
- relationship (varchar 100, nullable)
- notes (text, nullable)
```

**Tipos de rostros:**
- `registered_user`: Tiene `user_id`, se obtiene nombre de tabla `users`
- `non_user`: Visitante, usa `face_metadata.full_name`

### Ver las Imágenes Guardadas

Para verificar que las imágenes se están guardando:

```dart
// En cualquier parte de tu código
final images = await FaceStorageService.getFaceImages('face_id_123');
print('Total imágenes: ${images.length}');
for (var img in images) {
  print('Ruta: ${img.path}');
}
```

## 🧪 Cómo Probar el Sistema

### 1. Registrar un Rostro

```bash
# Desde la app:
1. Settings → Gestionar Rostros
2. Botón "Registrar Nuevo Rostro"
3. Seguir proceso de 5 capturas
4. Ingresar nombre: "Juan Pérez"
5. Completar registro

# Logs esperados:
📤 Enviando rostro al backend...
   URL: https://tu-api.com/api/v1/faces
   User ID: null
   Full Name: Juan Pérez
📡 Respuesta: 201
✅ Rostro registrado exitosamente
   Face ID: 123
   Type: non_user
```

### 2. Probar Reconocimiento

```bash
# Desde la app:
1. Settings → Probar Reconocimiento Facial
2. Posicionar rostro frente a cámara
3. Botón "Capturar y Reconocer"

# Logs esperados si reconoce:
🔍 Reconociendo rostro...
   Threshold: 0.4
   Top N: 1
📡 Respuesta: 200
✅ Rostro reconocido!
   Confidence: 0.85
   Type: non_user

# Resultado en pantalla:
✅ Rostro Reconocido!
👤 Nombre: Juan Pérez
🏷️ Tipo: Visitante
📊 Confianza: 85.0%
🆔 Face ID: 123
```

### 3. Listar Rostros

```bash
# Desde la app:
1. Settings → Gestionar Rostros
2. Ver lista de rostros registrados

# La pantalla carga desde backend automáticamente
# useBackend = true en manage_faces_screen.dart
```

## 🔧 Parámetros Configurables

### Threshold de Reconocimiento

En `test_face_recognition_screen.dart` línea 88:

```dart
final result = await FaceRecognitionApiService.recognizeFace(
  imagePath: image.path,
  threshold: 0.4,  // ← Ajustar aquí
  topN: 1,
);
```

**Valores recomendados:**
- `0.3` - Muy estricto (solo coincidencias casi perfectas)
- `0.4` - Balanceado (default, recomendado)
- `0.5` - Permisivo (puede dar algunos falsos positivos)
- `0.6` - Muy permisivo (muchos falsos positivos)

### Número de Mejores Matches

```dart
threshold: 0.4,
topN: 3,  // Retorna los 3 mejores matches
```

## 🔑 Endpoints Utilizados

### POST /api/v1/faces - Registrar Rostro

**Request:**
```http
POST /api/v1/faces
Authorization: Bearer {token}
Content-Type: multipart/form-data

Body:
- image: File (imagen JPG/PNG)
- user_id: int (opcional, para usuarios registrados)
- full_name: string (requerido si user_id es null)
```

**Response 201:**
```json
{
  "id": 123,
  "organization_id": 5,
  "user_id": null,
  "type": "non_user",
  "created_at": "2025-11-17T12:00:00",
  "metadata": {
    "full_name": "Juan Pérez"
  }
}
```

### POST /api/v1/faces/recognize - Reconocer Rostro

**Request:**
```http
POST /api/v1/faces/recognize
Authorization: Bearer {token}
Content-Type: multipart/form-data

Body:
- image: File
- threshold: float (default 0.4)
- top_n: int (default 1)
```

**Response 200 (Match encontrado):**
```json
{
  "match_found": true,
  "confidence": 0.85,
  "face": {
    "id": 123,
    "type": "non_user",
    "metadata": {
      "full_name": "Juan Pérez"
    }
  }
}
```

**Response 200 (No match):**
```json
{
  "match_found": false,
  "message": "No se encontró ninguna coincidencia"
}
```

### GET /api/v1/faces - Listar Rostros

**Request:**
```http
GET /api/v1/faces?type=all&page=1&limit=20
Authorization: Bearer {token}
```

**Query params:**
- `type`: "all", "users", "non_users"
- `search`: Buscar por nombre
- `page`: Página (default 1)
- `limit`: Items por página (default 20)

**Response 200:**
```json
{
  "total": 5,
  "page": 1,
  "limit": 20,
  "data": [
    {
      "id": 123,
      "type": "non_user",
      "metadata": {"full_name": "Juan Pérez"},
      "user": null
    }
  ]
}
```

## 🐛 Troubleshooting

### Error: "El archivo debe ser una imagen"

**Causa:** Falta content-type en multipart upload

**Solución:** Ya solucionado con `MediaType.parse(contentType)` en líneas 96-101 y 221-226 de `face_recognition_api_service.dart`

### Error: "No hay sesión activa"

**Causa:** Token no encontrado o nombre incorrecto

**Solución:** Token se guarda como `'api_access_token'` en SharedPreferences (ya corregido en línea 15)

### Error: Type mismatch - int vs String

**Causa:** Backend usa int para IDs, local usa String

**Solución:** Ya manejado en `manage_faces_screen.dart` con conversiones apropiadas

### Rostro duplicado (409 Conflict)

**Causa:** Backend detectó embedding muy similar (distancia < 0.15)

**Solución:**
- Esto es esperado, previene duplicados
- Usuario puede eliminar rostro anterior e intentar de nuevo
- O ajustar threshold de duplicados en backend

## 🚀 Anteriormente: Integración con Backend (YA COMPLETADO)

### ~~Opción 1: Envío Inmediato a API~~ ✅ IMPLEMENTADO

~~Cuando tengas tu backend listo, modifica `face_capture_screen.dart` línea 248:~~

**Estado actual:** Ya implementado en `face_capture_screen.dart`

```dart
// ANTES (actual):
await FaceService.registerFace(
  name: name,
  relationship: relationship,
  imageUrl: imagePaths.isNotEmpty ? imagePaths.first : 'no_image',
  processingResult: {...},
  savedImagePaths: imagePaths,
);

// DESPUÉS (con API):
// 1. Enviar imágenes a la API
final apiResponse = await FaceApiService.uploadFaceImages(
  faceId: _currentFaceId!,
  name: name,
  relationship: relationship,
  imagePaths: imagePaths,
  authToken: 'tu_token_jwt', // Obtén del auth service
);

if (apiResponse['success']) {
  // 2. Guardar con embeddings del backend
  await FaceService.registerFace(
    name: name,
    relationship: relationship,
    imageUrl: imagePaths.first,
    processingResult: {
      'steps_completed': steps.length,
      'final_confidence': apiResponse['confidence'],
      'embeddings': apiResponse['embeddings'], // Vector del backend
      'face_id': _currentFaceId,
    },
    savedImagePaths: imagePaths,
  );
}
```

### Opción 2: Envío por Lotes (Batch)

Si prefieres enviar múltiples rostros a la vez:

```dart
// Obtener todos los rostros pendientes de sincronización
final pendingFaces = await getPendingFacesForSync();

// Enviar en batch
for (final faceData in pendingFaces) {
  final images = await FaceStorageService.getFaceImages(faceData['face_id']);
  final paths = images.map((f) => f.path).toList();

  await FaceApiService.uploadFaceImages(
    faceId: faceData['face_id'],
    name: faceData['name'],
    relationship: faceData['relationship'],
    imagePaths: paths,
    authToken: yourAuthToken,
  );
}
```

## 🎯 Alternativa: Captura de Video

Si prefieres enviar un video corto en lugar de 5 imágenes:

### Paso 1: Agregar dependencia

Ya tienes `camera`, pero necesitarás también `video_player` (ya incluido):

```yaml
dependencies:
  camera: ^0.10.5+5
  video_player: ^2.8.1  # ✅ Ya lo tienes
```

### Paso 2: Crear servicio de video

```dart
// lib/services/video_capture_service.dart
import 'package:camera/camera.dart';

class VideoCaptureService {
  static Future<String> recordFaceVideo({
    required CameraController controller,
    required String faceId,
    int durationSeconds = 10,
  }) async {
    // Iniciar grabación
    await controller.startVideoRecording();

    // Grabar por X segundos
    await Future.delayed(Duration(seconds: durationSeconds));

    // Detener y guardar
    final videoFile = await controller.stopVideoRecording();

    // Guardar en storage
    final savedPath = await FaceStorageService.saveVideoFile(
      videoFile: videoFile,
      faceId: faceId,
    );

    return savedPath;
  }
}
```

### Paso 3: Modificar face_capture_screen.dart

Reemplazar el método `_captureStep()` con:

```dart
Future<void> _captureVideo() async {
  setState(() => isProcessing = true);

  try {
    _showMessage('Grabando por 10 segundos...');

    final videoPath = await VideoCaptureService.recordFaceVideo(
      controller: _cameraController!,
      faceId: _currentFaceId!,
      durationSeconds: 10,
    );

    _showMessage('Video guardado exitosamente');

    // Enviar a API para extraer frames y embeddings
    final apiResponse = await FaceApiService.uploadFaceVideo(
      faceId: _currentFaceId!,
      videoPath: videoPath,
      authToken: yourToken,
    );

    if (apiResponse['success']) {
      await _completeRegistration();
    }
  } catch (e) {
    _showMessage('Error al grabar video: $e');
  }

  setState(() => isProcessing = false);
}
```

## 🔧 Métodos Útiles del Storage Service

### Obtener espacio usado

```dart
final sizeBytes = await FaceStorageService.getTotalStorageSize();
final sizeFormatted = FaceStorageService.formatStorageSize(sizeBytes);
print('Espacio usado: $sizeFormatted'); // "2.5 MB"
```

### Eliminar rostro

```dart
await FaceStorageService.deleteFaceImages('face_id_123');
```

### Limpiar imágenes antiguas

```dart
// Elimina imágenes de hace más de 30 días
await FaceStorageService.cleanupOldImages(daysOld: 30);
```

## 📡 Estructura de la API Backend (Recomendada)

### Endpoint: Registrar Rostro

```
POST /api/faces
Content-Type: multipart/form-data
Authorization: Bearer {token}

Body:
- face_id: string
- name: string
- relationship: string
- images: File[] (array de imágenes)
- captured_at: DateTime
```

**Respuesta esperada:**

```json
{
  "success": true,
  "face_id": "1234567890",
  "embeddings": [0.123, 0.456, ..., 0.789],
  "confidence": 0.95,
  "message": "Rostro procesado correctamente"
}
```

### Endpoint: Verificar Rostro

```
POST /api/faces/verify
Content-Type: multipart/form-data
Authorization: Bearer {token}

Body:
- image: File (imagen capturada)
```

**Respuesta esperada:**

```json
{
  "recognized": true,
  "face_id": "1234567890",
  "name": "Juan Pérez",
  "relationship": "Familiar",
  "confidence": 0.92,
  "similarity_score": 0.88
}
```

## 🧪 Testing

### Verificar que las imágenes se guardan:

```dart
// En face_capture_screen, después de capturar
final images = await FaceStorageService.getFaceImages(_currentFaceId!);
print('✅ Imágenes guardadas: ${images.length}');
for (var img in images) {
  final exists = await img.exists();
  final size = await img.length();
  print('📁 ${img.path}: $size bytes, exists: $exists');
}
```

### Ver logs en consola:

Cuando captures un rostro, verás:

```
✅ Imagen guardada en: /data/.../face_123_step1_1234567890.jpg
✅ Imagen guardada en: /data/.../face_123_step2_1234567891.jpg
...
📸 Total de imágenes capturadas: 5
📂 Ubicación: /data/.../registered_faces/face_123/
📦 Datos preparados para API:
   - Face ID: face_123
   - Nombre: Juan Pérez
   - Imágenes: 5
```

## ⚠️ Consideraciones Importantes

### 1. Privacidad y Seguridad
- Las imágenes se guardan en el almacenamiento privado de la app
- Solo tu app puede acceder a ellas
- Considera encriptar las imágenes si es información sensible

### 2. Espacio en Disco
- Cada imagen ocupa ~500KB - 2MB
- 5 imágenes por rostro = ~5-10MB
- Con 5 rostros = ~25-50MB
- Implementa limpieza periódica

### 3. Permisos
Ya tienes configurado `permission_handler`, verifica en:
- **Android**: `AndroidManifest.xml`
- **iOS**: `Info.plist`

```xml
<!-- Android -->
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

```xml
<!-- iOS -->
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara para registro facial</string>
```

## 🎨 Personalización

### Cambiar número de pasos de captura

En `face_capture_screen.dart` línea 34:

```dart
final List<String> steps = [
  'Posiciona tu rostro en el centro',
  'Gira ligeramente hacia la izquierda',
  'Gira ligeramente hacia la derecha',
  // Agrega o quita pasos aquí
];
```

### Cambiar calidad de imagen

En `face_capture_screen.dart` línea 112:

```dart
_cameraController = CameraController(
  frontCamera,
  ResolutionPreset.high,  // Cambiar: low, medium, high, veryHigh
  enableAudio: false,
);
```

## 📞 Soporte

Si necesitas ayuda con:
- Integración con tu backend específico
- Procesamiento local de embeddings
- Optimización de almacenamiento
- Implementación de video capture

Solo pregunta y te ayudo con el código específico.

---

**Estado actual:** ✅ Almacenamiento local funcional
**Próximo paso:** 🔄 Integración con API de backend
**Alternativa:** 🎥 Captura de video (código de ejemplo incluido arriba)
