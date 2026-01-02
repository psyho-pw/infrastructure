# 보안 가이드 - Ansible Vault 사용법

## 개요

민감한 정보(비밀번호, API 키, 인증서 등)는 Ansible Vault를 사용하여 암호화된 상태로 관리합니다.
`vault.yml` 파일만 암호화하고, `vars.yml`은 일반 텍스트로 유지합니다.

## Vault 비밀번호 설정

```bash
# 비밀번호 파일 생성
echo 'your-secure-password' > .vault_pass

# 권한 설정
chmod 600 .vault_pass

# .gitignore에 추가됨 (이미 설정됨)
```

`ansible.cfg`에 추가:

```ini
[defaults]
vault_password_file = .vault_pass
```

## Vault 파일 암호화

### 새 파일 암호화

```bash
# Pi 서버 vault 파일 암호화
ansible-vault encrypt host_vars/pi-server/vault.yml

# 여러 파일 한번에 암호화
ansible-vault encrypt host_vars/*/vault.yml
```

### 암호화된 파일 편집

```bash
# vault 파일 편집 (자동으로 복호화/암호화)
ansible-vault edit host_vars/pi-server/vault.yml
```

### 암호화된 파일 보기

```bash
# vault 파일 내용 보기
ansible-vault view host_vars/pi-server/vault.yml
```

### 암호 변경

```bash
# vault 파일 비밀번호 변경
ansible-vault rekey host_vars/pi-server/vault.yml
```

### 복호화 (임시)

```bash
# 파일 복호화 (주의: 민감 정보 노출)
ansible-vault decrypt host_vars/pi-server/vault.yml

# 작업 후 다시 암호화
ansible-vault encrypt host_vars/pi-server/vault.yml
```

## Playbook 실행

### 비밀번호 파일 사용

```bash
# ansible.cfg에 vault_password_file이 설정되어 있으면 그냥 실행
ansible-playbook playbooks/pi.yml
```

### 비밀번호 수동 입력

```bash
# vault 비밀번호 입력 프롬프트 표시
ansible-playbook playbooks/pi.yml --ask-vault-pass
```

### 비밀번호 파일 직접 지정

```bash
ansible-playbook playbooks/pi.yml --vault-password-file .vault_pass
```

### 배포

```bash
ansible-playbook playbooks/pi.yml
```
