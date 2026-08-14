#!/usr/bin/env bash
# Clash Verge startup_script entrypoint.
# verge rejects paths with args / non-.sh extensions
# (error: unsupported script extension: ... proxyfix fix --quiet).
set -euo pipefail
exec /home/jackz/.local/bin/proxyfix-guard
