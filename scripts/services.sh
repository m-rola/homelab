# shellcheck shell=bash
# shellcheck disable=SC2034  # SERVICES is used by scripts that source this file
SERVICES=(
  unbound
  pihole
  nginx
  uptime-kuma
  netalertx
  tailscale
)

# Disabled: crowdsec — no inbound internet traffic (no port forwarding, no public IPv6),
# so there is nothing to detect. compose/crowdsec and config/crowdsec are kept;
# re-enable by adding it back here and in ansible/inventory/group_vars/rpi.yml.
