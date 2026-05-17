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

test-visual:
	pnpm run test:examples:visual

test-visual-native:
	pnpm run test:examples:visual:native

test-visual-browser:
	pnpm run test:examples:visual:browser

update-visual-snapshots:
	pnpm run test:examples:visual:update

update-visual-snapshots-native:
	pnpm run test:examples:visual:update:native

update-visual-snapshots-browser:
	pnpm run test:examples:visual:update:browser

# Publish rhodonite_core → rhodonite_webgpu → rhodonite → rhodonite_app_sdl3 to mooncakes (not rhodonite_examples).
# Prerequisites: `moon login`; network for registry.
publish-mooncakes:
	bash scripts/publish-rhodonite-mooncakes.sh

# Alias for scripts that referenced the old placeholder name.
release-stage:
	just publish-mooncakes
