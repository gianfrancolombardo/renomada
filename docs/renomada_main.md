# Análisis del Proyecto ReNomada

Este documento compila un análisis exhaustivo del proyecto **ReNomada**, basado en la documentación técnica y de producto existente.

---

## 1. Resumen del Proyecto

**ReNomada** es una aplicación móvil diseñada para facilitar el intercambio y regalo de objetos (“items”) de manera **hiperlocal**, enfocada específicamente en la comunidad de personas con estilo de vida nómada (viajeros en furgoneta/autocaravana, mochileros y nómadas digitales).

La plataforma funciona bajo una premisa de **inmediatez y proximidad geográfica**, permitiendo a los usuarios descubrir objetos disponibles en un radio cercano a su ubicación actual y coordinar su entrega en persona de forma rápida.

Su filosofía central combina la sostenibilidad (dar segunda vida a los objetos) con la practicidad del estilo de vida nómada (viajar ligero y ayudarse mutuamente en la ruta).

---

## 2. Lo que Persigue (Misión y Propósito)

El propósito fundamental de ReNomada es **"facilitar el regalo/intercambio hiperlocal 'aquí y ahora' entre personas nómadas, con una experiencia mínima en fricción y máxima utilidad comunitaria."**

Sus principios rectores son:
*   **Comunidad primero:** Fomentar conexiones reales y colaboración entre viajeros.
*   **Sostenibilidad y minimalismo:** Reducir residuos y fomentar la economía circular.
*   **Hiperlocalidad:** Relevancia basada en la cercanía inmediata.
*   **Simplicidad radical:** Eliminar barreras para publicar o adquirir objetos.

**North Star Metric:** Porcentaje de items reclamados dentro de 14 días en un hotspot activo.

---

## 3. El Problema que Resuelve

Las personas en constante movimiento (vanlife, mochileros) enfrentan problemas logísticos específicos que las plataformas tradicionales de compraventa (Wallapop, Marketplace) no resuelven bien:

1.  **Espacio Limitado:** Necesidad crítica de liberar espacio físico en vehículos o mochilas ("lo que no viaja contigo, estorba").
2.  **Tiempo Limitado:** Los usuarios están de paso; no pueden esperar días para coordinar una venta o envío.
3.  **Fricción Transaccional:** El regateo y la gestión de ventas comerciales consumen tiempo y energía.
4.  **Ineficiencia Local:** Es difícil saber si hay otros viajeros cerca que necesiten justo lo que uno va a desechar.

---

## 4. Cómo lo Hace (Solución y Mecanismo)

ReNomada implementa una solución tecnológica y de producto centrada en la reducción de fricción:

### Mecánica de Producto (UX/UI)
*   **Feed por Radio:** La app filtra usuarios y objetos basándose exclusivamente en un radio de distancia configurable (ej. 1-20 km) desde la ubicación actual.
*   **Interacción "Tinder-like":**
    *   **Swipe Right (Me interesa):** Inicia inmediatamente un chat privado con el dueño.
    *   **Swipe Left (Pasar):** Oculta el objeto permanentemente para limpiar el feed.
*   **Sin Envíos:** Todo está diseñado para entregas en persona ("Quedada").
*   **Privacidad de Ubicación:** La ubicación se asocia al perfil del usuario (no al objeto individual) y se muestra siempre "redondeada" (aproximada) para proteger la seguridad del viajero.

### Arquitectura Técnica
*   **Aplicación Móvil:** Desarrollada en **Flutter** para garantizar rendimiento nativo en iOS y Android.
*   **Backend as a Service (BaaS):** Utiliza **Supabase** para gestionar:
    *   **Autenticación:** Gestión de usuarios.
    *   **Base de Datos (PostgreSQL):** Con lógica geoespacial (PostGIS) para los filtros por radio.
    *   **Seguridad (Row Level Security - RLS):** Políticas estrictas de acceso a datos.
    *   **Realtime:** Para el chat instantáneo entre usuarios.
    *   **Storage:** Almacenamiento de fotos de los objetos.
*   **Infraestructura Ligera:** No requiere un backend propio complejo en esta fase, reduciendo costes y mantenimiento.

---

## 5. Propuesta de Valor

> **"Libera espacio. Reduce tu huella."**

La propuesta de valor se articula en tres pilares para el usuario:
1.  **Practicidad (Viaja Ligero):** Facilita desprenderse de carga innecesaria de forma útil, sin la culpa de tirarlo a la basura.
2.  **Ahorro y Utilidad:** Permite conseguir equipamiento básico o "tesoros" de otros viajeros de forma gratuita o por intercambio, ideal para presupuestos ajustados.
3.  **Conexión Social:** Actúa como un rompehielos para conectar con otros viajeros en la misma ruta o área (hotspots).

---

## 6. Estado Actual del Proyecto

Actualmente, el proyecto se encuentra en **Fase de Desarrollo del MVP (Fase 1)**.

### Lo que está hecho (Fase 0 - Setup & Cimientos + Fase 1 Core MVP):
*   ✅ Configuración del proyecto en Flutter.
*   ✅ Infraestructura en Supabase (Auth, DB, Storage).
*   ✅ Landing page (Astro) desplegada.
*   ✅ Definición completa de ingeniería, marca y diseño (Design System).
*   ✅ Implementación de Autenticación y Perfiles.
*   ✅ Desarrollo del CRUD de Items (Publicación).
*   ✅ Lógica del Feed Geográfico.
*   ✅ Sistema de Chat en tiempo real y Notificaciones Push.
