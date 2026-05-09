# RhodoniteMBT — Moon workspace shortcuts

set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# Run from repository root (where moon.work lives).
default:
	just check-ws

check-ws:
	moon check --target all

fmt:
	moon fmt

info:
	moon info

# Placeholder for a future kagura-style release staging (path deps -> versions).
release-stage:
	@echo "TODO: add scripting to rewrite moon.mod.json path deps to semver for publish."
	@exit 1
