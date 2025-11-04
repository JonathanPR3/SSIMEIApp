# Guía de Implementación - Reconocimiento Facial

## 📋 Resumen de la Implementación

Tu app ahora tiene la capacidad de **capturar y almacenar imágenes faciales localmente**, lista para enviarlas a tu API de backend cuando esté disponible.

## 🗂️ Estructura de Archivos Creados/Modificados

### Nuevos Archivos

1. **`lib/services/face_storage_service.dart`**
   - Gestiona el almacenamiento local de imágenes
   - Guarda imágenes en el dispositivo
   - Organiza imágenes por face_id
   - Prepara datos para envío a API

2. **`lib/services/face_api_service.dart`**
   - Servicio preparado para comunicación con backend
   - Métodos listos para usar cuando implementes la API
   - Incluye ejemplos de estructura de request/response

### Archivos Modificados

3. **`lib/screens/face_capture_screen.dart`**
   - Ahora guarda cada imagen capturada
   - Almacena 5 imágenes por rostro (una por cada paso)
   - Muestra mensajes de confirmación

4. **`lib/services/face_service.dart`**
   - Acepta rutas de imágenes guardadas
   - Preparado para integración futura

## 📸 ¿Cómo Funciona Actualmente?

### Flujo de Captura

1. Usuario abre "Gestionar Rostros"
2. Presiona "Registrar Nuevo Rostro"
3. La app captura **5 imágenes**:
   - Paso 1: Rostro centrado
   - Paso 2: Girado a la izquierda
   - Paso 3: Girado a la derecha
   - Paso 4: Sonriendo
   - Paso 5: Expresión neutral

4. Cada imagen se guarda en:
   ```
   /data/user/0/com.tu.app/app_flutter/registered_faces/{face_id}/
   ├── {face_id}_step1_{timestamp}.jpg
   ├── {face_id}_step2_{timestamp}.jpg
   ├── {face_id}_step3_{timestamp}.jpg
   ├── {face_id}_step4_{timestamp}.jpg
   └── {face_id}_step5_{timestamp}.jpg
   ```

5. Al completar, el usuario ingresa:
   - Nombre completo
   - Relación (Familiar, Empleado, etc.)

6. Los datos se preparan para envío a API (estructura lista)

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

## 🚀 Próximos Pasos - Integración con Backend

### Opción 1: Envío Inmediato a API

Cuando tengas tu backend listo, modifica `face_capture_screen.dart` línea 248:

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
