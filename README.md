# Infrastructure

Traefik 리버스 프록시 및 Kafka 클러스터 Docker Compose 구성

## Architecture

```
                              ┌──────────────────────────────────────────┐
                              │              Docker Host                 │
                              │                                          │
[Internet]                    │  ┌────────────────────────────────────┐  │
    │                         │  │            Traefik                 │  │
    ├── :80 ─────────────────▶│  │  - Let's Encrypt certificate       │  │
    ├── :443 ────────────────▶│  │  - HTTP → HTTPS redirection        │  │
    ├── :9092 ───────────────▶│  │  - Docker label based routing      │  │
    │                         │  └──────────────┬─────────────────────┘  │
    │                         │                 │                        │
    │                         │       ┌─────────┴─────────┐              │
    │                         │       ▼                   ▼              │
    │                         │   [Kafka]            [Kafka-UI]          │
    │                         │   :9092               :8080              │
    │                         │                                          │
    └─────────────────────────┴──────────────────────────────────────────┘
```

## Directory Structure

```
.
├── traefik/                 # 리버스 프록시
│   ├── compose.yaml
│   ├── .env.example
│   └── letsencrypt/         # SSL 인증서 (자동 생성)
│
├── kafka/                   # Kafka 클러스터
│   ├── compose.yaml
│   ├── .env.example
│   ├── scripts/
│   │   └── init-kafka-users.sh
│   └── data/
│       └── kafka/           # Kafka 데이터
│
└── README.md
```

## Quick Start

### 1. Traefik 시작

```bash
cd traefik
cp .env.example .env
# .env 수정 (도메인, 이메일 등)
docker compose up -d
```

### 2. Kafka 시작

```bash
cd kafka
cp .env.example .env
# .env 수정 (비밀번호 등)
docker compose up -d
```

## Services

| 서비스 | 포트 | 설명 |
|--------|------|------|
| Traefik | 80, 443, 9092 | 리버스 프록시 + Let's Encrypt |
| Kafka | (via Traefik) | 메시지 브로커 (SASL 인증) |
| Kafka UI | (via Traefik) | 웹 관리 UI |

## Adding New Services

Traefik 수정 없이 라벨만 추가:

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

networks:
  proxy:
    external: true
```

## Documentation

- [Traefik 설정](./traefik/README.md)
- [Kafka 설정](./kafka/README.md)
