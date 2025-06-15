
# 🧓🚐 AFA-Jándula  
**Sistema de gestión de transporte, comunicación y documentación para asociaciones de personas mayores.**

![Firebase](https://img.shields.io/badge/Firebase-Backend-yellow)
![Flutter Web](https://img.shields.io/badge/Flutter-Web-blue)
![Deploy](https://img.shields.io/badge/Deploy-Firebase%20Hosting-brightgreen)
![Status](https://img.shields.io/badge/Status-En%20Desarrollo-orange)

---

## 🌐 Demo en Producción

📍 [https://afa-jandula.web.app](https://afa-jandula.web.app)  
_Accesible desde cualquier navegador con conexión._

---

## 📱 Tecnologías Usadas

| Tecnología       | Uso principal                              |
|------------------|---------------------------------------------|
| **Flutter Web**  | Interfaz de usuario adaptada a mayores      |
| **Firebase Auth**| Inicio de sesión con Google / Contraseña    |
| **Firestore**    | Base de datos en tiempo real                |
| **Firebase Cloud Messaging** | Notificaciones push personalizadas     |
| **Firebase Storage** | Almacenamiento de documentos compartidos |
| **Google Maps API** | Cálculo de distancias y rutas             |

---

## 🔧 Funcionalidades Principales

### 👥 Gestión de Usuarios
- Registro público con revisión por administrador
- Roles diferenciados: Usuario, Conductor, Administrador
- Activación/desactivación de cuentas

### 🚐 Rutas y Transporte
- Asignación de usuarios a rutas
- Orden de recogida personalizado
- Seguimiento en tiempo real del conductor
- Aviso de llegada (proximidad)

### 🔔 Notificaciones
- Inicio de ruta
- Turno de recogida
- Conductor cerca
- Recogida cancelada

### 📄 Documentos y Comunicación
- Subida y lectura de archivos PDF
- Novedades, talleres, convocatorias
- Compartición segura y organizada

---

## 🗺️ Mapa Interactivo

- Visualización en tiempo real del conductor
- Cálculo de distancia y tiempo estimado al usuario
- Uso de [Google Distance Matrix API](https://developers.google.com/maps/documentation/distance-matrix)

---

## 🚀 Despliegue

El proyecto está desplegado en Firebase Hosting:  
✅ SSL automático  
✅ Dominio gratuito de Firebase  
✅ Actualización con un solo comando: `flutter build web && firebase deploy`

---

## 📂 Estructura del Proyecto

```
📁 lib/
  ├── screens/        # Vistas por rol
  ├── services/       # Funciones Firebase
  ├── widgets/        # Componentes comunes
  ├── models/         # Estructuras de datos

📁 web/               # Config Flutter Web
🗂️ firebase.json      # Configuración del hosting
```

---

## 🎯 Objetivos del Proyecto

Este sistema nace para responder a los siguientes retos planteados por la asociación AFA Jándula:

- ✅ Crear una app simple y accesible para usuarios mayores
- ✅ Gestionar rutas de transporte con comunicación en tiempo real
- ✅ Permitir cancelaciones por motivos personales o de salud
- ✅ Centralizar la documentación relevante para usuarios y cuidadores
- ⚙️ Establecer una base para futuras ampliaciones (citas, chats, geocercas...)

---

## 👨‍💻 AutorES

Desarrollado por **Jesús Soto y Pablo Martínez**   
📍 TFG | AFA | 2025
