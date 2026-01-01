#!/bin/bash

# Kafka SCRAM 사용자 초기화 스크립트
# 이 스크립트는 Kafka 브로커가 시작된 후 실행되어야 합니다.

set -e

KAFKA_HOME=/opt/kafka
BOOTSTRAP_SERVER=kafka:9092

echo "Waiting for Kafka to be ready..."
sleep 10

# Admin 사용자 생성
echo "Creating admin user..."
kafka-configs --bootstrap-server $BOOTSTRAP_SERVER \
    --alter \
    --add-config 'SCRAM-SHA-512=[password='${KAFKA_ADMIN_PASSWORD}']' \
    --entity-type users \
    --entity-name ${KAFKA_ADMIN_USER} \
    --command-config /etc/kafka/client.properties 2>/dev/null || \
kafka-configs --bootstrap-server $BOOTSTRAP_SERVER \
    --alter \
    --add-config 'SCRAM-SHA-512=[password='${KAFKA_ADMIN_PASSWORD}']' \
    --entity-type users \
    --entity-name ${KAFKA_ADMIN_USER}

# Client 사용자 생성
echo "Creating client user..."
kafka-configs --bootstrap-server $BOOTSTRAP_SERVER \
    --alter \
    --add-config 'SCRAM-SHA-512=[password='${KAFKA_CLIENT_PASSWORD}']' \
    --entity-type users \
    --entity-name ${KAFKA_CLIENT_USER} \
    --command-config /etc/kafka/client.properties 2>/dev/null || \
kafka-configs --bootstrap-server $BOOTSTRAP_SERVER \
    --alter \
    --add-config 'SCRAM-SHA-512=[password='${KAFKA_CLIENT_PASSWORD}']' \
    --entity-type users \
    --entity-name ${KAFKA_CLIENT_USER}

echo "SCRAM users created successfully!"

# 생성된 사용자 확인
echo "Verifying users..."
kafka-configs --bootstrap-server $BOOTSTRAP_SERVER \
    --describe \
    --entity-type users \
    --command-config /etc/kafka/client.properties 2>/dev/null || \
kafka-configs --bootstrap-server $BOOTSTRAP_SERVER \
    --describe \
    --entity-type users

echo "Kafka user initialization complete!"
