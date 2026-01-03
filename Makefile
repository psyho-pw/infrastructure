.PHONY: help install check deploy deploy-all deploy-pi deploy-db deploy-jenkins \
        deploy-docker deploy-traefik dry-run dry-run-pi dry-run-db dry-run-jenkins \
        vault-decrypt vault-encrypt ping docker-logs docker-ps clean lint install-hooks

INVENTORY := inventory/production
VAULT_PASS := .vault_pass
TARGET ?= all
DRY_RUN ?= false

help: ## show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## install Ansible collections
	ansible-galaxy install -r requirements.yml

check: ## test Ansible connection
	ansible all -i $(INVENTORY) -m ping

deploy: ## deploy infrastructure (TARGET=all|pi|db|jenkins|docker|traefik, DRY_RUN=true for check mode)
	@case "$(TARGET)" in \
		all) \
			PLAYBOOK="playbooks/site.yml"; \
			;; \
		pi) \
			PLAYBOOK="playbooks/pi.yml"; \
			;; \
		db) \
			PLAYBOOK="playbooks/db.yml"; \
			;; \
		jenkins) \
			PLAYBOOK="playbooks/jenkins.yml"; \
			;; \
		docker) \
			PLAYBOOK="playbooks/docker.yml"; \
			;; \
		traefik) \
			PLAYBOOK="playbooks/traefik.yml"; \
			;; \
		*) \
			echo "Error: Invalid TARGET. Available: all, pi, db, jenkins, docker, traefik"; \
			echo "Usage: make deploy TARGET=pi"; \
			echo "       make deploy TARGET=all DRY_RUN=true"; \
			exit 1; \
			;; \
	esac; \
	if [ "$(DRY_RUN)" = "true" ]; then \
		ansible-playbook -i $(INVENTORY) $$PLAYBOOK --check --diff; \
	else \
		ansible-playbook -i $(INVENTORY) $$PLAYBOOK; \
	fi

vault-decrypt: ## decrypt Vault file (example: make vault-decrypt HOST=pi-server)
	@if [ -z "$(HOST)" ]; then \
		echo "Error: HOST 변수를 지정해주세요. 예: make vault-decrypt HOST=pi-server"; \
		exit 1; \
	fi
	@FILE_PATH="inventory/host_vars/$(HOST)/vault.yml"; \
	if [ ! -f "$$FILE_PATH" ]; then \
		echo "Error: 파일을 찾을 수 없습니다: $$FILE_PATH"; \
		exit 1; \
	fi; \
	echo "Decrypting: $$FILE_PATH"; \
	ansible-vault decrypt $$FILE_PATH --vault-password-file $(VAULT_PASS)

vault-encrypt: ## encrypt Vault file (example: make vault-encrypt HOST=pi-server)
	@if [ -z "$(HOST)" ]; then \
		echo "Error: HOST 변수를 지정해주세요. 예: make vault-encrypt HOST=pi-server"; \
		exit 1; \
	fi
	@FILE_PATH="inventory/host_vars/$(HOST)/vault.yml"; \
	if [ ! -f "$$FILE_PATH" ]; then \
		echo "Error: 파일을 찾을 수 없습니다: $$FILE_PATH"; \
		exit 1; \
	fi; \
	if head -n 1 "$$FILE_PATH" | grep -q '$$ANSIBLE_VAULT'; then \
		echo "Error: 파일이 이미 암호화되어 있습니다: $$FILE_PATH"; \
		exit 1; \
	fi; \
	echo "Encrypting: $$FILE_PATH"; \
	ansible-vault encrypt $$FILE_PATH --vault-password-file $(VAULT_PASS) --encrypt-vault-id default

ping: ## check all servers connection
	ansible all -i $(INVENTORY) -m ping

docker-logs: ## check Docker logs (example: make logs HOST=pi SERVICE=traefik)
	@if [ -z "$(HOST)" ] || [ -z "$(SERVICE)" ]; then \
		echo "Error: HOST와 SERVICE 변수를 지정해주세요. 예: make logs HOST=pi SERVICE=traefik"; \
		exit 1; \
	fi
	ansible $(HOST) -i $(INVENTORY) -m shell -a "docker logs $(SERVICE)"

docker-ps: ## check Docker container status
	ansible all -i $(INVENTORY) -m shell -a "docker ps"

# Shorthand aliases for deploy
deploy-all: ## deploy all infrastructure
	@$(MAKE) deploy TARGET=all

deploy-pi: ## deploy Pi server
	@$(MAKE) deploy TARGET=pi

deploy-db: ## deploy DB server
	@$(MAKE) deploy TARGET=db

deploy-jenkins: ## deploy Jenkins server
	@$(MAKE) deploy TARGET=jenkins

deploy-docker: ## deploy Docker only
	@$(MAKE) deploy TARGET=docker

deploy-traefik: ## deploy Traefik only
	@$(MAKE) deploy TARGET=traefik

# Shorthand aliases for dry-run
dry-run: ## dry-run all infrastructure
	@$(MAKE) deploy TARGET=all DRY_RUN=true

dry-run-pi: ## dry-run Pi server
	@$(MAKE) deploy TARGET=pi DRY_RUN=true

dry-run-db: ## dry-run DB server
	@$(MAKE) deploy TARGET=db DRY_RUN=true

dry-run-jenkins: ## dry-run Jenkins server
	@$(MAKE) deploy TARGET=jenkins DRY_RUN=true

clean: ## clean Ansible logs
	rm -f ansible.log
	find .ansible/tmp -type f -delete 2>/dev/null || true

lint: ## lint Ansible files
	ANSIBLE_VAULT_PASSWORD_FILE=$(VAULT_PASS) ansible-lint --fix

install-hooks: ## install git hooks for pre-commit linting
	@echo "Installing git hooks..."
	@ln -sf ../../hooks/pre-commit .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "✅ Git hooks installed successfully!"
	@echo "   pre-commit hook will run ansible-lint before each commit"
