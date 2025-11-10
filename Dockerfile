# --- Stage 1: Build (Budowanie aplikacji i instalacja zależności) ---
FROM node:20-bookworm-slim AS builder

# Ustawienie zmiennej ARG (jeśli potrzebne do natywnych modułów)
ARG NATIVEBUILD=false
ENV NATIVEBUILD=${NATIVEBUILD}

# Instalacja niezbędnych zależności systemowych do budowania
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    cmake \
    build-essential \
    ca-certificates \
    libdbus-1-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
# Konfiguracja git (jeśli repozytorium wymaga --recurse-submodules lub sslVerify=false)
RUN git config --global http.sslVerify false && \
    git clone --recurse-submodules https://github.com/Affirmatech/MeshSense.git .

# Uruchomienie skryptów konfiguracyjnych (z Pliku 2)
RUN node ./update.mjs

# Instalacja zależności i budowanie UI/API. 
# Używamy --omit=dev, ponieważ potrzebujemy tylko zależności produkcyjnych w runtime.
WORKDIR /app/api
RUN npm install --omit=dev

WORKDIR /app/ui
RUN npm install --omit=dev
RUN npm run build

# --- Stage 2: Runtime (Lekkie środowisko uruchomieniowe) ---
FROM node:20-bookworm-slim AS runtime

# Instalacja zależności systemowych wymaganych TYLKO do działania aplikacji (Chromium headless)
RUN apt-get update && apt-get install -y --no-install-recommends \
    fonts-noto-color-emoji \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libgdk-pixbuf-2.0-0 \
    libgtk-3-0 \
    libgbm1 \
    libnss3 \
    libasound2 \
    libxi6 \
    libxss1 \
    libxtst6 \
    dbus \
    dumb-init \
    # Usuwamy curl, git, udev, xvfb, jeśli nie są ściśle wymagane w runtime
    && rm -rf /var/lib/apt/lists/*

# Dodanie 'dumb-init' jako narzędzia do zarządzania procesami (z Pliku 2)
# apt-get install powyżej już to załatwiło, jeśli jest w repozytorium Debiana.

# Konfiguracja użytkownika 'node' dla bezpieczeństwa (domyślny w node-slim)
# Kopiowanie zbudowanej aplikacji od użytkownika 'node' dla 'node'
WORKDIR /app
COPY --from=builder --chown=node:node /app /app

# Konfiguracja DBus (z Pliku 2)
RUN mkdir -p /var/run/dbus && \
    chown node:node /var/run/dbus && \
    dbus-uuidgen > /var/lib/dbus/machine-id

# Ustawienie właściwego użytkownika i katalogu roboczego
USER node
WORKDIR /app

EXPOSE 5920

# Użycie dumb-init jako ENTRYPOINT i precyzyjnego CMD (z Pliku 2, dostosowane ścieżki)
ENTRYPOINT ["dumb-init", "--"]
# Zakładając, że build Pliku 2 generuje index.cjs w dist, 
# Plik 1 używa natomiast server.js bezpośrednio w api/
CMD ["node", "./api/server.js", "--headless", "--disable-gpu", "--in-process-gpu", "--disable-software-rasterizer"]
