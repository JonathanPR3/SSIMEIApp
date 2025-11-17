# 🧪 Prueba de Reconocimiento Facial - Integración Backend

**Fecha:** 2025-11-17
**Estado:** ✅ Listo para probar

---

## 📋 RESUMEN DE CAMBIOS

### ✅ Lo que se implementó:

1. **Nuevo servicio de API** → `lib/services/face_recognition_api_service.dart`
   - Conecta con los endpoints reales del backend FastAPI
   - Métodos: `registerFace()`, `recognizeFace()`, `listFaces()`, `deleteFace()`, `getMyFace()`

2. **Endpoints agregados** → `lib/config/api_config.dart`
   - `/api/v1/faces` - Registrar/listar rostros
   - `/api/v1/faces/{id}` - Detalle/eliminar rostro
   - `/api/v1/faces/recognize` - Reconocer rostro
   - `/api/v1/faces/users/{id}/face` - Rostro de usuario

3. **Pantalla modificada** → `lib/screens/face_capture_screen.dart`
   - Mantiene los 5 pasos de captura (NO se eliminaron)
   - Al finalizar, envía **solo la PRIMERA imagen** al backend
   - Backend procesa con DeepFace y genera embedding
   - Si falla, pregunta si quiere guardar localmente

---

## 🎯 FLUJO ACTUAL

### **Paso 1: Usuario captura rostro**
```
1. Usuario abre ManageFacesScreen
2. Presiona "Registrar Nuevo Rostro"
3. Se abre FaceCaptureScreen
4. Captura 5 imágenes siguiendo los pasos:
   - Paso 1: Rostro centrado ✅
   - Paso 2: Girado izquierda
   - Paso 3: Girado derecha
   - Paso 4: Sonriendo
   - Paso 5: Neutral
5. Las 5 imágenes se guardan localmente en el dispositivo
```

### **Paso 2: Usuario completa registro**
```
6. Dialog aparece pidiendo:
   - Nombre completo
   - Relación (Familiar, Empleado, etc.)
7. Usuario ingresa datos y presiona "Registrar"
```

### **Paso 3: Envío al backend** ⭐ NUEVO
```
8. Flutter muestra "Enviando rostro al backend..."

9. Flutter envía SOLO la primera imagen capturada a:
   POST /api/v1/faces
   Content-Type: multipart/form-data

   Datos:
   - image: archivo de la primera captura
   - user_id: null (persona sin usuario registrado)
   - full_name: nombre ingresado

10. Backend FastAPI:
    - Recibe la imagen
    - Extrae embedding con DeepFace (Facenet512)
    - Genera vector de 512 números
    - Verifica duplicados (threshold 0.15)
    - Guarda en BD:
      * organization_id
      * user_id: null
      * embedding: JSON array [512 floats]
      * created_at, updated_at
    - Crea registro en face_metadata:
      * full_name
      * expires_at (opcional)

11. Backend responde:
    - Status 201: Éxito
    - Status 409: Rostro duplicado
    - Status 400: Error en imagen
```

### **Paso 4: Confirmación en Flutter**
```
12a. Si éxito:
     - Muestra "✅ Rostro registrado exitosamente en el servidor"
     - Guarda también localmente (opcional, para compatibilidad)
     - Cierra la pantalla

12b. Si error:
     - Muestra "❌ Error del servidor: [mensaje]"
     - Pregunta: "¿Deseas guardar localmente?"
     - Si Sí → guarda solo localmente
     - Si No → no guarda nada
```

---

## 🔧 CÓMO PROBAR

### **Requisitos previos:**

1. **Backend corriendo:**
   ```bash
   cd C:\Users\jonit\OneDrive\Documentos\GitHub\vigilancia-api
   venv\Scripts\activate
   uvicorn app.main:app --reload
   ```

2. **Verificar que DeepFace esté instalado:**
   ```bash
   pip list | grep -i deepface
   # Debe aparecer: deepface
   ```

3. **Usuario con sesión activa en Flutter**
   - Debes estar logueado
   - Token válido (no expirado)
   - organization_id presente

---

### **Pasos de prueba:**

#### **Prueba 1: Registrar rostro nuevo**

1. Abrir la app Flutter
2. Ir a "Gestionar Rostros" (ManageFacesScreen)
3. Presionar "Registrar Nuevo Rostro"
4. Capturar las 5 fotos siguiendo los pasos
5. Ingresar:
   - Nombre: "Juan Pérez"
   - Relación: "Visitante"
6. Presionar "Registrar"
7. Esperar procesamiento (~5-10 segundos)

**Resultado esperado:**
```
✅ Rostro registrado exitosamente en el servidor
```

**Verificar en consola de Flutter:**
```
📸 Total de imágenes capturadas: 5
📂 Ubicación: /data/.../face_123_step1_1234567890.jpg
📤 Enviando rostro al backend...
   URL: http://localhost:8000/api/v1/faces
   User ID: null
   Full Name: Juan Pérez
📡 Respuesta: 201
✅ Rostro registrado exitosamente
   Face ID (backend): 45
   Type: non_user
```

**Verificar en consola del backend:**
```
INFO: Extracting embedding...
INFO: Face detected successfully
INFO: Embedding size: 512
INFO: Checking for duplicates...
INFO: No duplicates found
INFO: Creating face record...
INFO: Creating face_metadata...
INFO: Face registered successfully - ID: 45
```

---

#### **Prueba 2: Intentar registrar rostro duplicado**

1. Registrar un rostro (ej: "María López")
2. Inmediatamente intentar registrar el mismo rostro de nuevo
3. Usar la misma persona (o foto muy similar)

**Resultado esperado:**
```
❌ Error del servidor: Ya existe un rostro muy similar registrado (ID: 45)
```

**Dialog aparece:**
```
Título: Error al registrar en servidor
Mensaje: Ya existe un rostro muy similar registrado (ID: 45)

¿Deseas guardar localmente?
[No] [Sí]
```

---

#### **Prueba 3: Registrar con imagen sin rostro**

1. Intentar capturar una imagen sin rostro visible
2. O una imagen muy borrosa/oscura

**Resultado esperado:**
```
❌ Error del servidor: No se detectó ningún rostro en la imagen
```

---

#### **Prueba 4: Backend apagado**

1. Detener el backend (Ctrl+C en la terminal)
2. Intentar registrar un rostro

**Resultado esperado:**
```
❌ Error del servidor: Error de conexión: ...
```

**Dialog aparece preguntando si guardar localmente.**

---

## 📊 VERIFICAR EN BASE DE DATOS

Después de registrar un rostro exitosamente, verifica en MySQL:

```sql
-- Ver rostros registrados
SELECT * FROM faces ORDER BY created_at DESC LIMIT 5;

-- Ver metadata de rostros sin usuario
SELECT f.id, f.organization_id, f.created_at,
       fm.full_name, fm.expires_at
FROM faces f
LEFT JOIN face_metadata fm ON f.id = fm.face_id
WHERE f.user_id IS NULL
ORDER BY f.created_at DESC;

-- Ver tamaño del embedding
SELECT id,
       LENGTH(embedding) as embedding_length,
       SUBSTRING(embedding, 1, 50) as embedding_preview
FROM faces
ORDER BY created_at DESC
LIMIT 1;
```

**Resultado esperado:**
- `embedding_length`: ~5000-6000 caracteres (JSON array de 512 floats)
- `embedding_preview`: `[0.123456, -0.234567, 0.345678, ...]`

---

## 🐛 TROUBLESHOOTING

### **Error: "No hay sesión activa"**
**Causa:** Token no encontrado o expirado
**Solución:**
- Cerrar sesión y volver a iniciar sesión
- Verificar que `auth_token` esté en SharedPreferences

---

### **Error: "Cannot import name 'DeepFace'"**
**Causa:** DeepFace no instalado en el backend
**Solución:**
```bash
cd vigilancia-api
venv\Scripts\activate
pip install deepface
```

---

### **Error: "Timeout" o tarda mucho**
**Causa:** Primera ejecución de DeepFace descarga modelos (~100MB)
**Solución:**
- Esperar a que descargue (solo la primera vez)
- O ejecutar manualmente:
```python
from deepface import DeepFace
DeepFace.build_model("Facenet512")
```

---

### **Error 400: "Error en la imagen"**
**Posibles causas:**
1. Imagen muy oscura/borrosa
2. Rostro no visible o parcialmente oculto
3. Múltiples rostros en la imagen
4. Imagen corrupta

**Solución:**
- Capturar nuevamente con mejor iluminación
- Asegurar que solo haya un rostro visible
- Rostro debe estar frontal y completo

---

### **Error 409: "Rostro duplicado"**
**Causa:** Ya existe un rostro muy similar (distancia < 0.15)
**Solución:**
- Normal si es la misma persona
- Verificar rostros existentes con `GET /api/v1/faces`
- Si es legítimo, backend dev puede ajustar threshold

---

## 📁 ARCHIVOS MODIFICADOS/CREADOS

```
curso/
├── lib/
│   ├── config/
│   │   └── api_config.dart                          ✏️ MODIFICADO
│   ├── services/
│   │   └── face_recognition_api_service.dart        ✅ NUEVO
│   └── screens/
│       └── face_capture_screen.dart                 ✏️ MODIFICADO
└── PRUEBA_RECONOCIMIENTO_FACIAL.md                  ✅ Este archivo
```

---

## 🎯 PRÓXIMOS PASOS

### **Después de probar:**

1. ✅ Si funciona → Implementar pantalla de reconocimiento
2. ✅ Si funciona → Integrar con ManageFacesScreen para listar rostros del backend
3. ✅ Si funciona → Agregar opción de eliminar rostros del backend

### **Mejoras futuras:**

1. Enviar las 5 imágenes al backend (requiere modificar backend)
2. Mostrar la imagen original (requiere S3 en backend)
3. Reconocimiento en tiempo real desde cámara
4. Integrar con sistema de incidentes (persona autorizada/no autorizada)

---

## 💡 NOTAS IMPORTANTES

1. **Solo se envía UNA imagen** (la primera captura)
   - Las otras 4 quedan guardadas localmente pero NO se envían
   - Backend procesa solo esa imagen

2. **NO se guarda la imagen en S3** (backend no lo implementó)
   - Solo se guarda el embedding (vector de números)
   - No hay URL de imagen para mostrar después

3. **Threshold de duplicados muy estricto** (0.15)
   - Puede rechazar fotos legítimas de la misma persona
   - Si sucede, el backend dev debe ajustar el threshold

4. **Performance con muchos rostros**
   - Reconocimiento es O(n) - búsqueda lineal
   - Con <100 rostros: rápido
   - Con >1000 rostros: puede ser lento

---

## ✅ CHECKLIST DE PRUEBA

- [ ] Backend corriendo en localhost:8000
- [ ] DeepFace instalado
- [ ] Usuario logueado en Flutter
- [ ] Permisos de cámara otorgados
- [ ] Registrar rostro nuevo (caso exitoso)
- [ ] Ver logs de Flutter (debe mostrar "✅ Rostro registrado")
- [ ] Ver logs de backend (debe mostrar "Face registered successfully")
- [ ] Verificar en BD (tabla faces + face_metadata)
- [ ] Intentar registrar duplicado (debe rechazar)
- [ ] Intentar con imagen sin rostro (debe rechazar)
- [ ] Probar con backend apagado (debe ofrecer guardar localmente)

---

**¡Listo para probar!** 🚀

Si encuentras algún error, revisa los logs de Flutter y del backend para identificar el problema.
