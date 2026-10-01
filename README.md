# Polla Automática: frontend (Flutter)

App web y Android de la polla futbolera. Consume la API FastAPI del repo
`Polla-Automatica`. Estado con Riverpod, rutas con go_router, HTTP con Dio.

## Requisitos
- Flutter estable (3.47+). Web no necesita nada más; Android necesita el SDK.
- La API corriendo. En el repo del backend:
  `CORS_ORIGINS=http://localhost:5000 uv run uvicorn app.main:app`

## Ejecutar
```bash
flutter pub get
# Web (puerto fijo para que coincida con CORS_ORIGINS del backend)
flutter run -d chrome --web-port 5000 --dart-define=API_URL=http://localhost:8000
# Sin Chrome: sirve en http://localhost:5000
flutter run -d web-server --web-port 5000 --dart-define=API_URL=http://localhost:8000
# Emulador Android: localhost del PC es 10.0.2.2
flutter run -d android --dart-define=API_URL=http://10.0.2.2:8000
```

## Pantallas
- **Login / Registro**
- **Mis grupos**: lista, crear grupo, unirse con código
- **Grupo**: pestañas *Partidos* (pronosticar, se bloquea al empezar), *Ranking* y
  *Miembros* (generar código de invitación)

## Estructura
```
lib/
  core/      # config (API_URL), cliente HTTP, providers, router, utilidades de UI
  models/    # modelos que parsean la API
  features/  # auth, groups, game (partidos, ranking, miembros)
test/        # modelos y widgets (API simulada con mocktail)
```

## Calidad
```bash
flutter analyze
flutter test
```

## Despliegue web (Coolify)
El `Dockerfile` compila Flutter web y lo sirve con nginx (puerto 80).

1. En Coolify: *New Resource → Public/Private Repository*, repo `Polla-Automatica-Frontend`,
   rama `main`, **Build Pack: Dockerfile**, puerto expuesto **80**.
2. Asigna el dominio (ej. `https://polla.tu-dominio.com`).
3. La URL de la API se fija al compilar: por defecto `https://www.pollaf.softlane.click`.
   Para otra, define el Build Argument `API_URL` en Coolify.
4. **Backend:** en sus variables de entorno pon `CORS_ORIGINS` con la URL exacta del
   frontend (sin `/` al final) y redespliega; si no, el navegador bloquea las llamadas.
