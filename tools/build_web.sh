#!/bin/sh
# Build every portable module for the web profile into dist/.
#
# The profile emits one flat output dir keyed by basename, so this list is the
# whole graph rather than a set of entry points — and a module deleted from the
# tree leaves its `dist/*.mjs` behind, where a `.mjs` harness importing it will
# keep passing off the stale artifact. `--clean` wipes dist/ first and is what
# to use after adding or removing a core module.
#
#   tools/build_web.sh            # incremental
#   tools/build_web.sh --clean    # after a module was added or removed
set -e
# Gene must be on PATH. Resolve it before changing directory: a relative PATH
# entry such as `bin` names a different file after the cd below.
GENE_EXE=$(command -v gene || true)
if [ -z "$GENE_EXE" ]; then
  echo "gene not found on PATH (add the Gene checkout's bin directory to PATH)" >&2
  exit 1
fi
case "$GENE_EXE" in
  /*) ;;
  *) GENE_EXE="$(pwd)/$GENE_EXE" ;;
esac
cd "$(dirname "$0")/.."

if [ "$1" = "--clean" ]; then
  rm -rf dist
fi
mkdir -p dist

MODULES="
core/exact core/noise core/field core/world core/registry
core/tiles core/texture core/shaders core/groups core/item core/biome core/cave core/ore
core/decor core/abm core/craft core/entity core/formspec
core/api core/mods core/mapgen core/light core/mesh core/loaded
core/physics core/raycast core/edit core/inventory core/drops
core/vec core/container core/wire core/protocol core/client_world
mods/default/src/default
client/atlas client/render client/sound client/main client/net_main
probes/divergence probes/world_spec probes/mapgen_spec probes/light_spec
probes/loaded_spec probes/physics_spec probes/edit_spec probes/inventory_spec
probes/wire_spec probes/protocol_spec probes/abm_spec
core/seen
probes/web_world_spec probes/web_mapgen_spec probes/web_light_spec
probes/web_loaded_spec probes/web_physics_spec probes/web_edit_spec
probes/web_inventory_spec probes/web_wire_spec probes/web_protocol_spec
probes/web_divergence probes/web_abm_spec probes/web_players_probe probes/web_tick_probe
probes/web_entity_probe probes/web_net_probe probes/web_chest_probe
"

for m in $MODULES; do
  if output=$("$GENE_EXE" build --target web "$m.gene" --out-dir dist); then
    :
  else
    echo "Failed to build $m.gene:" >&2
    printf '%s\n' "$output" >&2
    exit 1
  fi
done

echo "built $(echo $MODULES | wc -w | tr -d ' ') modules into dist/"
