#!/bin/bash

# Kafka SCRAM 사용자 초기화 스크립트
# 이 스크립트는 Kafka 브로커가 시작된 후 실행되어야 합니다.

set -e

BOOTSTRAP_SERVER=kafka:29092

echo "Waiting for Kafka to be ready..."
sleep 10

# SASL 클라이언트 설정 파일 생성
cat > /tmp/client.properties << EOF
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="${KAFKA_ADMIN_USER}" password="${KAFKA_ADMIN_PASSWORD}";
EOF

# Admin 사용자 생성
echo "Creating admin user: ${KAFKA_ADMIN_USER}"
kafka-configs --bootstrap-server $BOOTSTRAP_SERVER \
    --alter \
    --add-config "SCRAM-SHA-512=[password=${KAFKA_ADMIN_PASSWORD}]" \
    --entity-type users \
    --entity-name ${KAFKA_ADMIN_USER} \
    --command-config /tmp/client.properties

# Client 사용자 생성
echo "Creating client user: ${KAFKA_CLIENT_USER}"
kafka-configs --bootstrap-server $BOOTSTRAP_SERVER \
    --alter \
    --add-config "SCRAM-SHA-512=[password=${KAFKA_CLIENT_PASSWORD}]" \
    --entity-type users \
    --entity-name ${KAFKA_CLIENT_USER} \
    --command-config /tmp/client.properties

echo "SCRAM users created successfully!"

# 생성된 사용자 확인
echo "Verifying users..."
kafka-configs --bootstrap-server $BOOTSTRAP_SERVER \
    --describe \
    --entity-type users \
    --command-config /tmp/client.properties

echo "Kafka user initialization complete!"
