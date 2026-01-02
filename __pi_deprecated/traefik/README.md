# Traefik Reverse Proxy

Let's Encrypt 자동 인증서 발급이 포함된 Traefik 리버스 프록시

## Features

- HTTP → HTTPS 자동 리다이렉트
- Let's Encrypt 자동 인증서 발급/갱신
- Docker 라벨 기반 자동 서비스 디스커버리
- TCP 프록시 지원 (Kafka 등)
- 대시보드 (선택)

## Quick Start

### 1. 환경 변수 설정

```bash
cp .env.example .env
```

```env
DOMAIN=your-domain.com
ACME_EMAIL=admin@your-domain.com
DASHBOARD_AUTH=admin:$$apr1$$...  # htpasswd 형식
```

### 2. 대시보드 비밀번호 생성

```bash
# htpasswd 설치 (Ubuntu)
sudo apt install apache2-utils

# 비밀번호 생성 ($ 이스케이프 필요)
echo $(htpasswd -nb admin your-password) | sed -e s/\\$/\\$\\$/g
```

### 3. 네트워크 생성 및 시작

```bash
docker network create proxy
docker compose up -d
```

## 다른 서비스 연동

### HTTP 서비스 (웹앱, API)

```yaml
services:
  my-app:
    image: my-app
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.my-app.rule=Host(`app.example.com`)"
      - "traefik.http.routers.my-app.tls.certresolver=letsencrypt"
      - "traefik.http.routers.my-app.entrypoints=websecure"
      - "traefik.http.services.my-app.loadbalancer.server.port=8080"

networks:
  proxy:
    external: true
```

### TCP 서비스 (Kafka, DB 등)

Traefik compose에 진입점 추가 필요:

```yaml
# traefik/compose.yaml
command:
  - --entrypoints.my-tcp.address=:5432  # 새 포트
ports:
  - "5432:5432"
```

서비스 라벨:

```yaml
labels:
  - "traefik.tcp.routers.my-db.rule=HostSNI(`*`)"
  - "traefik.tcp.routers.my-db.entrypoints=my-tcp"
  - "traefik.tcp.routers.my-db.tls=true"
  - "traefik.tcp.services.my-db.loadbalancer.server.port=5432"
```

## Ports

| Port | 용도 |
|------|------|
| 80 | HTTP (→ HTTPS 리다이렉트) |
| 443 | HTTPS |
| 9092 | Kafka TCP |

## Files

```
traefik/
├── compose.yaml
├── .env
├── .env.example
└── letsencrypt/     # 인증서 저장 (자동 생성)
    └── acme.json
```

## Dashboard

`https://traefik.your-domain.com` 에서 대시보드 확인 가능 (Basic Auth 필요)
