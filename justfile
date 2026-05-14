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
	moon test --target js moon/rhodonite_examples/src/visual_regression

update-visual-snapshots:
	RHODONITE_UPDATE_VISUAL_SNAPSHOTS=1 moon test --target js --update moon/rhodonite_examples/src/visual_regression

# Publish rhodonite_core → rhodonite_webgpu → rhodonite to mooncakes (not rhodonite_examples).
# Prerequisites: `moon login`; network for registry.
publish-mooncakes:
	bash scripts/publish-rhodonite-mooncakes.sh

# Alias for scripts that referenced the old placeholder name.
release-stage:
	just publish-mooncakes
