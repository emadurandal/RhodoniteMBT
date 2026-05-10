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

# Publish rhodonite_core → rhodonite_webgpu → rhodonite to mooncakes (not rhodonite_examples).
# Prerequisites: `moon login`; network for registry.
publish-mooncakes:
	bash scripts/publish-rhodonite-mooncakes.sh

# Alias for scripts that referenced the old placeholder name.
release-stage:
	just publish-mooncakes
