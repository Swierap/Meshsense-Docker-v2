This repository provides a Docker container for MeshSense allowing it to run headless in server mode.

Updated to the last Beta Version.

Typical usage:

docker run -d -p 5920:5920 --name meshsense -e ACCESS_KEY=mySecretAccessKey meshsense

docker-compose

volumes:
  data:
services:
  meshsense:
    restart: unless-stopped
    environment:
      - ACCESS_KEY=mySecretAccessKey
      - PORT=5920
    expose:
      - 5920
    volumes:
      - data:/root/.local/share/meshsense/
    labels:
      - traefik.enable=true
      - traefik.http.routers.meshsense.entrypoints=https
      - traefik.http.routers.meshsense.tls=true
      - traefik.http.routers.meshsense.rule=Host(`meshsense.<yourdomain>.com`)
      - traefik.http.services.meshsense.loadbalancer.server.port=5920
      - traefik.http.services.meshsense.loadbalancer.healthcheck=true
      - traefik.http.services.meshsense.loadbalancer.healthcheck.interval=30s
      - traefik.http.services.meshsense.loadbalancer.healthcheck.path=/
      - traefik.http.routers.meshsense.middlewares=google-oidc@file     # See tips for securing

