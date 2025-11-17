# AVISO DE PRIVACIDAD

**SISTEMA DE SEGURIDAD Y MONITOREO CON INTELIGENCIA ARTIFICIAL (SSIMEI)**

**Última actualización:** 17 de noviembre de 2025

---

## 1. IDENTIDAD Y DOMICILIO DEL RESPONSABLE

El presente Aviso de Privacidad se emite en cumplimiento de la Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP) y demás normativa aplicable en materia de protección de datos personales.

**Responsable del tratamiento de datos personales:**
- Sistema de Seguridad y Monitoreo con Inteligencia Artificial (SSIMEI)
- [Domicilio del responsable]
- [Correo electrónico de contacto]
- [Teléfono de contacto]

---

## 2. DATOS PERSONALES QUE SE RECABAN

Para el funcionamiento del sistema de vigilancia y seguridad, recabamos las siguientes categorías de datos personales:

### 2.1 Datos de Identificación
- Nombre completo
- Correo electrónico
- Credenciales de acceso (usuario y contraseña encriptada)

### 2.2 Datos Biométricos (Sensibles)
- **Imágenes faciales:** Fotografías del rostro del usuario capturadas mediante cámara frontal
- **Vectores biométricos:** Representaciones matemáticas únicas del rostro (embeddings de 512 dimensiones) generadas mediante algoritmos de inteligencia artificial (DeepFace/Facenet512)
- **Metadatos de captura:** Fecha, hora y dispositivo de registro

### 2.3 Datos de Videovigilancia
- **Grabaciones de video:** Capturas de eventos de seguridad desde cámaras RTSP
- **Imágenes de incidentes:** Fotografías asociadas a detecciones de comportamiento sospechoso
- **Logs de eventos:** Registros de detecciones automáticas con marca temporal

### 2.4 Datos de Uso del Sistema
- Dirección IP
- Información del dispositivo (modelo, sistema operativo)
- Registros de actividad en la aplicación
- Preferencias de notificaciones

---

## 3. FINALIDADES DEL TRATAMIENTO DE DATOS

Los datos personales recabados serán utilizados para las siguientes finalidades:

### 3.1 Finalidades Primarias (Necesarias para el servicio)
1. **Identificación y autenticación de usuarios** en el sistema de vigilancia
2. **Control de acceso** a instalaciones mediante reconocimiento facial
3. **Detección de personas autorizadas y no autorizadas** en zonas monitoreadas
4. **Registro y documentación de incidentes de seguridad**
5. **Generación de alertas y notificaciones** en tiempo real ante eventos sospechosos
6. **Gestión de cámaras de vigilancia** y dispositivos de monitoreo
7. **Auditoría y trazabilidad** de eventos de seguridad
8. **Cumplimiento de obligaciones** derivadas del contrato de servicios

### 3.2 Finalidades Secundarias (No necesarias para el servicio)
1. **Análisis estadístico** del comportamiento de seguridad
2. **Mejora continua** de los algoritmos de detección mediante aprendizaje automático
3. **Investigación y desarrollo** de nuevas funcionalidades de seguridad
4. **Comunicaciones promocionales** sobre actualizaciones del sistema

**Usted puede manifestar su negativa para el tratamiento de sus datos personales para las finalidades secundarias en cualquier momento, sin que ello afecte el servicio principal.**

---

## 4. FUNDAMENTO LEGAL Y CONSENTIMIENTO

### 4.1 Datos Biométricos (Datos Sensibles)
El tratamiento de datos biométricos faciales se realiza con base en:

- **Consentimiento expreso y por escrito** del titular, conforme al artículo 9 de la LFPDPPP
- **Finalidad legítima de seguridad** y protección de bienes e instalaciones
- **Medidas de seguridad técnicas y administrativas** para proteger la información

**Al registrar su rostro en el sistema, usted otorga su consentimiento expreso e informado para:**
- La captura de imágenes faciales mediante la cámara del dispositivo
- El procesamiento de dichas imágenes para generar vectores biométricos únicos
- El almacenamiento seguro de los vectores biométricos en bases de datos encriptadas
- La comparación automática de rostros detectados con la base de datos registrada
- El uso de tecnologías de inteligencia artificial para el reconocimiento facial

### 4.2 Videovigilancia
La operación de cámaras de vigilancia se fundamenta en:
- **Derecho a la seguridad** de personas y bienes
- **Aviso visible** de la presencia de cámaras en las instalaciones
- **Limitación del uso** exclusivamente para fines de seguridad
- **Tiempo de retención limitado** de las grabaciones

---

## 5. TECNOLOGÍA DE RECONOCIMIENTO FACIAL

### 5.1 Descripción del Sistema
Nuestro sistema utiliza tecnología de inteligencia artificial de última generación:

- **Algoritmo:** DeepFace con modelo Facenet512
- **Funcionamiento:** Conversión de imágenes faciales en vectores matemáticos (embeddings) de 512 dimensiones
- **Comparación:** Cálculo de distancia coseno entre vectores con umbral de reconocimiento de 0.4
- **Precisión:** Sistema optimizado para minimizar falsos positivos y negativos

### 5.2 Almacenamiento Seguro
- Los vectores biométricos se almacenan en formato JSON encriptado
- **No se almacenan fotografías originales del rostro**, solo representaciones matemáticas
- Bases de datos protegidas con encriptación AES-256
- Acceso restringido mediante autenticación de múltiples factores

### 5.3 Categorización de Rostros
El sistema clasifica los rostros en dos categorías:
- **`registered_user`:** Usuarios autorizados y miembros de la organización
- **`non_user`:** Visitantes y personas no registradas (para estadísticas anónimas)

---

## 6. TRANSFERENCIA DE DATOS

Sus datos personales **NO serán transferidos a terceros**, salvo en los siguientes casos excepcionales:

1. **Autoridades competentes:** Cuando sea requerido por orden judicial o autoridad administrativa
2. **Proveedores de servicios técnicos:** Para mantenimiento de servidores y bases de datos, bajo estrictos acuerdos de confidencialidad
3. **Casos de emergencia:** Para proteger la seguridad de personas ante situaciones de riesgo inminente

En todos los casos, se garantiza que el receptor de los datos implementará medidas de seguridad equivalentes o superiores.

---

## 7. MEDIDAS DE SEGURIDAD

Implementamos las siguientes medidas técnicas, físicas y administrativas:

### 7.1 Medidas Técnicas
- ✅ Encriptación end-to-end de datos biométricos (AES-256)
- ✅ Tokens JWT para autenticación con expiración de 60 minutos
- ✅ Comunicación segura mediante HTTPS/TLS
- ✅ Protección contra inyección SQL y ataques XSS
- ✅ Logs de auditoría de accesos y modificaciones
- ✅ Respaldos automáticos encriptados cada 24 horas

### 7.2 Medidas Físicas
- ✅ Servidores en centros de datos certificados
- ✅ Control de acceso físico restringido
- ✅ Sistemas de videovigilancia en instalaciones críticas

### 7.3 Medidas Administrativas
- ✅ Políticas de privacidad y confidencialidad para personal
- ✅ Capacitación continua en protección de datos
- ✅ Acuerdos de confidencialidad con terceros
- ✅ Procedimientos de respuesta ante incidentes de seguridad

---

## 8. DERECHOS ARCO (Acceso, Rectificación, Cancelación y Oposición)

Como titular de datos personales, usted tiene derecho a:

### 8.1 Acceso
Conocer qué datos personales tenemos sobre usted, para qué los utilizamos y las condiciones de uso.

### 8.2 Rectificación
Solicitar la corrección de sus datos personales en caso de que estén desactualizados, sean inexactos o estén incompletos.

### 8.3 Cancelación
Solicitar la eliminación de sus datos personales de nuestros registros o bases de datos cuando:
- Considere que no están siendo utilizados conforme a los principios y deberes previstos en la ley
- Hayan dejado de ser necesarios para las finalidades consentidas
- Haya concluido la relación jurídica con nuestra organización

### 8.4 Oposición
Oponerse por causa legítima al tratamiento de sus datos personales.

### 8.5 Revocación del Consentimiento
Revocar el consentimiento otorgado para el tratamiento de sus datos biométricos en cualquier momento.

**Procedimiento para ejercer derechos ARCO:**
1. Enviar solicitud por escrito a: [correo electrónico de contacto]
2. Incluir: nombre completo, correo registrado, descripción clara de la solicitud
3. Adjuntar identificación oficial vigente
4. Plazo de respuesta: **20 días hábiles** a partir de la recepción

---

## 9. CONSERVACIÓN Y ELIMINACIÓN DE DATOS

### 9.1 Plazos de Conservación
- **Datos biométricos activos:** Mientras subsista la relación jurídica o membresía
- **Grabaciones de video:** Máximo **30 días**, salvo incidentes bajo investigación
- **Logs de auditoría:** **2 años** para cumplimiento normativo
- **Datos de usuarios inactivos:** **6 meses** después de la última actividad

### 9.2 Eliminación Segura
Al concluir los plazos de conservación o ante solicitud de cancelación:
- Eliminación permanente de vectores biométricos de bases de datos
- Sobrescritura segura de archivos multimedia
- Eliminación de copias de respaldo después de 90 días
- Certificado de eliminación disponible a solicitud

---

## 10. USO DE COOKIES Y TECNOLOGÍAS DE RASTREO

Nuestra aplicación puede utilizar:
- **Tokens de sesión:** Para mantener la autenticación del usuario
- **Almacenamiento local:** Para preferencias y configuraciones (opcional)
- **Identificadores de dispositivo:** Para vincular sesiones de forma segura

**No utilizamos cookies de terceros para publicidad o rastreo comercial.**

---

## 11. DERECHOS DE MENORES DE EDAD

El sistema **NO está destinado a menores de 18 años**. Si detectamos datos de menores, procederemos a eliminarlos inmediatamente y notificaremos a los tutores legales.

---

## 12. CAMBIOS AL AVISO DE PRIVACIDAD

Nos reservamos el derecho de modificar este Aviso de Privacidad en cualquier momento para:
- Cumplir con cambios legislativos
- Implementar nuevas políticas internas
- Adaptar nuevas tecnologías

**Notificación de cambios:**
- Publicación en la aplicación móvil
- Notificación por correo electrónico
- Aviso destacado al iniciar sesión

**Fecha de vigencia:** Los cambios entrarán en vigor **30 días** después de su publicación.

---

## 13. CONSENTIMIENTO

**Al utilizar este sistema y registrar sus datos biométricos, usted declara:**

✅ Haber leído y comprendido el presente Aviso de Privacidad
✅ Otorgar su consentimiento expreso para el tratamiento de sus datos personales
✅ Autorizar específicamente el uso de datos biométricos faciales
✅ Aceptar las finalidades primarias y secundarias descritas
✅ Conocer sus derechos ARCO y cómo ejercerlos

---

## 14. AUTORIDAD DE PROTECCIÓN DE DATOS

Si considera que su derecho a la protección de datos personales ha sido vulnerado, puede acudir ante:

**Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales (INAI)**
- Sitio web: www.inai.org.mx
- Teléfono: 01 800 835 4324
- Correo: contacto@inai.org.mx

---

## 15. CONTACTO Y DUDAS

Para cualquier duda o aclaración sobre el presente Aviso de Privacidad:

📧 **Correo electrónico:** [correo de contacto]
📞 **Teléfono:** [número de contacto]
🏢 **Domicilio:** [dirección física]
⏰ **Horario de atención:** Lunes a viernes de 9:00 a 18:00 hrs

---

## 16. DECLARACIONES FINALES

El responsable del tratamiento de datos se compromete a:

1. Tratar sus datos con **absoluta confidencialidad**
2. Utilizar la información **únicamente para fines de seguridad**
3. Implementar las **mejores prácticas de protección de datos**
4. Mantener **transparencia** en todo momento
5. Respetar sus **derechos fundamentales** como titular

---

**Fecha de última actualización:** 17 de noviembre de 2025

**Versión:** 1.0

---

*Este documento constituye un aviso de privacidad integral conforme a la Ley Federal de Protección de Datos Personales en Posesión de los Particulares y su Reglamento.*

*Para garantizar la plena validez jurídica de este documento, se recomienda complementarlo con la asesoría de un abogado especializado en protección de datos.*
