# --- 1) Compilar Flutter web ---
FROM debian:bookworm-slim AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
      git curl unzip xz-utils ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Misma versión de Flutter con la que se desarrolla y se prueba
ARG FLUTTER_VERSION=3.47.5
RUN git clone --depth 1 -b ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:${PATH}"
RUN git config --global --add safe.directory /flutter \
    && flutter config --no-analytics --enable-web \
    && flutter precache --web

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .

# URL de la API; se puede cambiar como Build Argument en Coolify
ARG API_URL=https://www.pollaf.softlane.click
RUN flutter build web --release --dart-define=API_URL=${API_URL}

# --- 2) Servir con nginx ---
FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q --spider http://127.0.0.1/ || exit 1
