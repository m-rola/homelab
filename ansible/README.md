# ansible/

Ansible automation for bootstrapping a Raspberry Pi homelab.
Replaces manual `provision.sh` runs and manages secrets via Ansible Vault
instead of copying `.env` by hand.

## Structure

```
ansible/
├── ansible.cfg                     # Ansible configuration
├── site.yml                        # master playbook
├── vault.yml                       # encrypted secrets (gitignored)
├── vault.yml.example               # vault template — copy and fill in values
├── inventory/
│   ├── hosts.yml                   # RPi host list with IPs
│   └── group_vars/
│       └── rpi.yml                 # public variables + vault references
└── roles/
    ├── base/                       # provision.sh as Ansible (OS hardening)
    ├── docker/                     # Docker Engine installation on ARM
    └── services/                   # clone repo + generate .env + start services
```

## First run

### 1. Install Ansible on your laptop

```bash
pip install ansible
ansible-galaxy collection install community.docker
```

### 2. Set the vault password

```bash
echo "your_vault_password" > ~/.vault_pass
chmod 600 ~/.vault_pass
```

### 3. Fill in secrets in vault.yml

```bash
# Copy example and fill in real values
cp ansible/vault.yml.example ansible/vault.yml
nano ansible/vault.yml

# Encrypt
ansible-vault encrypt ansible/vault.yml

# Verify (should show encrypted content)
cat ansible/vault.yml
```

### 4. Set your RPi's IP

```bash
nano ansible/inventory/hosts.yml
# change ansible_host: 192.168.1.10 to the real IP
```

### 5. Ensure your SSH key is on the RPi

```bash
ssh-copy-id pi@192.168.1.10
```

### 6. Run

```bash
# Dry-run first
make ansible-dry-run

# Full deploy
make ansible-provision
```

## Day-to-day operations

Daily operations (update, backup, monitor) still go through the existing Makefile:

```bash
make update    # update Docker images
make backup    # manual backup
make status    # container status
```

Use Ansible only for:
- bootstrapping a new or restored RPi
- changing OS configuration
- rotating secrets (`ansible-vault edit ansible/vault.yml` → `make ansible-deploy`)

## Secret rotation

```bash
# Edit encrypted vault
ansible-vault edit ansible/vault.yml

# Regenerate .env on the RPi
make ansible-deploy

# Restart services that use the changed secrets
ssh pi@rpi "cd ~/homelab && docker compose restart pihole"
```

## Disaster recovery

After SD card failure with a new RPi:

```bash
# 1. Flash a new card (Raspberry Pi Imager + SSH key)
# 2. From your laptop:
make ansible-provision
# 3. Restore data from backup:
ssh pi@rpi "cd ~/homelab && ./scripts/restore.sh"
```

RTO: ~20 minutes instead of ~1 hour.
