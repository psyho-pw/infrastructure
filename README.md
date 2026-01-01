# Infrastructure Management

이 저장소는 현재 운영 중인 5개 서버 인스턴스의 인프라 구성 코드를 관리합니다. Docker Compose를 기반으로 각 서비스가 컨테이너화되어 관리됩니다.

## 📂 프로젝트 구조

```text
.
├── db/            # 데이터베이스 서버 설정 (PostgreSQL, MySQL 등)
├── jenkins/       # CI/CD 자동화 서버 (Jenkins)
├── pi/            # 메인 서비스 클러스터
│   ├── traefik/   # 리버스 프록시 및 SSL 인증 (Gateway)
│   ├── kafka/     # 메시지 브로커 클러스터
│   └── proxy/     # Squid 프록시 서버
├── production/    # 운영 환경 공통 설정
└── test/          # 
```