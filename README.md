# TOKE+ Mobile

Aplicacion Flutter de TOKE+ para clientes y tecnicos de servicios del hogar. Permite publicar pedidos, explorar prestadores verificados, postular a trabajos, chatear, comprar creditos, usar TokePro, recibir notificaciones y gestionar soporte desde una experiencia movil en espanol.

## Estado Del Proyecto

- Plataforma principal: Android.
- Package Android: `com.tokeplus.app`.
- Backend principal: InsForge `https://439t8drp.us-east.insforge.app`.
- Backend auxiliar: Heroku `https://tokeplus-api-439t8drp-fdd3e7290e72.herokuapp.com`.
- Estado actual verificado: `flutter analyze` sin issues y `flutter test` OK.

## Stack

- Flutter / Dart.
- GoRouter para navegacion.
- Riverpod para estado donde aplica.
- InsForge Auth, Database, Storage, Functions y Realtime via REST/WebSocket.
- Firebase Cloud Messaging para push notifications.
- Socket.IO para realtime.
- Mercado Pago por WebView/deep links via backend Express.
- Biometria con `local_auth` y `flutter_secure_storage`.

## Modulos Principales

- `auth`: registro, login, recuperacion, OTP, OAuth Google y flujo de prestador.
- `client`: home, descubrir, explorar, pedidos, postulantes, reservas y resenas.
- `technician`: feed de pedidos, postulaciones, creditos, TokePro, verificacion y panel.
- `chat`: conversaciones cliente-tecnico.
- `notifications`: historial, contador y tokens FCM.
- `profile`: datos personales, foto, contrasena, biometria y desactivacion.
- `support`: asistente IA y tickets de soporte.
- `core`: networking, tema, widgets compartidos, IA, push, realtime y constantes.

## Funcionalidades Destacadas

- Registro separado para cliente y tecnico.
- Verificacion de email por codigo.
- Registro de tecnico con documentos privados y estado de revision.
- Pedidos con categoria, descripcion, fotos, distrito, presupuesto y fecha preferida.
- Vista publica de pedidos desde `Descubrir > Pedidos` con detalle completo del servicio.
- Testimonios y casos de exito alimentados por resenas reales.
- Perfil publico de tecnico con rating, servicios y trabajos.
- Postulaciones con debito atomico de creditos.
- Compra de creditos y TokePro con Mercado Pago.
- Chat, notificaciones y soporte IA.
- Registro de token FCM tolerante a respuestas HTTP `2xx`.

## Estructura Relevante

```text
lib/
  app/                     Configuracion de app y router
  core/                    Servicios, tema, networking y widgets base
  features/
    auth/                  Autenticacion y registro
    client/                Experiencia de cliente
    technician/            Experiencia de tecnico
    chat/                  Mensajeria
    notifications/         Notificaciones in-app y push
    profile/               Cuenta y perfil
    support/               Soporte IA y tickets
assets/                    Imagenes, iconos y animaciones
test/                      Tests Flutter
```

## Configuracion Local

1. Instalar Flutter compatible con Dart SDK `^3.11.3`.
2. Instalar dependencias:

```bash
flutter pub get
```

3. Agregar `android/app/google-services.json` localmente para Firebase. No debe commitearse.
4. Ejecutar la app:

```bash
flutter run -d <device-id>
```

## Comandos De Calidad

```bash
dart format lib test
flutter analyze
flutter test
flutter build apk --release
```

Para instalar en dispositivo conectado en profile:

```bash
flutter run --profile -d <device-id> --no-resident
```

## Integraciones

- InsForge Auth: `POST /api/auth/users`, `POST /api/auth/sessions`, refresh y verificacion OTP.
- InsForge RPCs: pedidos publicos, prestadores, resenas, postulaciones, wallets y soporte.
- InsForge Storage: avatars, request photos, verification docs y work photos.
- InsForge Function: `/functions/ai-gateway` para soporte y clasificacion IA.
- Backend Express: IA alternativa, pagos Mercado Pago y notificaciones.
- Firebase: push notifications y `google-services.json` generado en CI desde secret.

## Seguridad

- Tokens guardados en `flutter_secure_storage`.
- Documentos de verificacion en bucket privado.
- Deep links para OAuth y retorno de pagos.
- No incluir API keys, service accounts ni `google-services.json` en commits.

## Pruebas Verificadas

- `flutter analyze`: sin issues.
- `flutter test`: tests pasando.
- RPC `get_public_requests`: devuelve detalle de pedido publico.
- RPC `get_technician_reviews`: devuelve resenas y datos del pedido asociado.
- Function `ai-gateway`: responde soporte IA.

## Despliegue

El build Android se genera por GitHub Actions. El workflow crea `google-services.json` desde `GOOGLE_SERVICES_JSON_BASE64` y construye el APK. Para publicar una version, usar tags/releases o el flujo configurado en `.github/workflows/cd.yml`.
