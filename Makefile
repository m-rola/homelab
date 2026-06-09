SCRIPTS := $(CURDIR)/scripts

.PHONY: help start stop update os-update backup status report monitor check-updates firewall install logs aliases healthcheck \
        install-hooks ansible-provision ansible-base ansible-docker ansible-deploy ansible-dry-run ansible-ping ansible-facts ansible-containers

help:
	@echo "Homelab management"
	@echo ""
	@echo "  make start               Start all services"
	@echo "  make stop                Stop all services"
	@echo "  make status              Show running containers"
	@echo "  make update              Pull and restart Docker services"
	@echo "  make os-update           Refresh apt package list"
	@echo "  make backup              Run manual backup"
	@echo "  make report              Send RPi report to Telegram"
	@echo "  make monitor             Run health/disk/temp alert check"
	@echo "  make check-updates       Check for new image versions"
	@echo "  make firewall            Apply firewall rules (sudo)"
	@echo "  make install             Install cron jobs + logrotate"
	@echo "  make aliases             Add homelab aliases to ~/.bashrc"
	@echo "  make install-hooks       Configure git to use .githooks/ (pre-push AI review)"
	@echo "  make logs                Tail update log"
	@echo ""
	@echo "Ansible (run from laptop, targets RPi over SSH)"
	@echo ""
	@echo "  make ansible-provision   Bootstrap RPi from scratch"
	@echo "  make ansible-base        OS hardening only"
	@echo "  make ansible-docker      Docker installation only"
	@echo "  make ansible-deploy      Deploy repo + .env + start services"
	@echo "  make ansible-dry-run     Dry-run — show changes, touch nothing"
	@echo "  make ansible-ping        Verify SSH connectivity"
	@echo "  make ansible-facts       Show RPi system facts"
	@echo "  make ansible-containers  Show container status via Ansible"

start:
	bash $(SCRIPTS)/start-all.sh

stop:
	bash $(SCRIPTS)/stop-all.sh

status:
	docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

update:
	bash $(SCRIPTS)/update.sh

os-update:
	bash $(SCRIPTS)/os-update.sh

backup:
	bash $(SCRIPTS)/backup.sh

report:
	bash $(SCRIPTS)/rpi-report.sh

monitor:
	bash $(SCRIPTS)/monitor.sh

healthcheck:
	bash $(SCRIPTS)/healthcheck.sh

check-updates:
	bash $(SCRIPTS)/check-updates.sh

firewall:
	sudo bash $(SCRIPTS)/setup-firewall.sh

install:
	bash $(SCRIPTS)/install-cron.sh

aliases:
	@grep -qF 'homelab-aliases.sh' ~/.bashrc || echo 'source $(CURDIR)/config/homelab-aliases.sh' >> ~/.bashrc
	@echo "Aliases installed — run: source ~/.bashrc"

install-hooks:
	git config core.hooksPath .githooks
	chmod +x .githooks/pre-push
	@echo "Git hooks installed — pre-push AI review active"

logs:
	@tail -100 $(CURDIR)/logs/update.log 2>/dev/null || echo "No logs yet — run 'make update' first"

# ── Ansible ───────────────────────────────────────────────────────────────────
ansible-provision: ## Bootstrap RPi from scratch: OS → Docker → services
	cd ansible && ansible-playbook site.yml

ansible-base: ## OS hardening only (hostname, packages, swap, SSH)
	cd ansible && ansible-playbook site.yml --tags base

ansible-docker: ## Docker Engine installation only
	cd ansible && ansible-playbook site.yml --tags docker

ansible-deploy: ## Repo clone + .env generation + service start only
	cd ansible && ansible-playbook site.yml --tags services

ansible-dry-run: ## Dry-run — show what would change, touch nothing
	cd ansible && ansible-playbook site.yml --check --diff

ansible-ping: ## Verify SSH connectivity to RPi
	cd ansible && ansible all -m ping

ansible-facts: ## Show RPi system facts (arch, OS, IP)
	cd ansible && ansible all -m setup | grep -E 'ansible_(architecture|os_family|distribution|default_ipv4)'

ansible-containers: ## Show container status via Ansible
	cd ansible && ansible rpi1 -m shell -a "docker ps --format 'table {{.Names}}\t{{.Status}}'"
