#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n'

# grab witch data off home page
# curl $CC_NEXT_URL | jq '.pageProps.witches | map({id, name, image})' > output_raw/witches.json

# default to pulling next 50 entries
offset=${1:-50}
max=$(bc <<< "`ls output_raw/artifacts | cut -f 1 -d '.' | sort -n | tail -n1` + $offset")

mkdir -p output_raw/artifacts
base_url="https://cryptocoven.xyz/api/hut/artifacts/metadata"

seq 1 $max | xargs -P 4 -I {} sh -c "(test ! -e output_raw/artifacts/{}.json) && (echo 'pulling artifact {}'; curl --silent $base_url/{} | jq > output_raw/artifacts/{}.json) || exit 0";

# if output doesn't have name, assume it hasn't been manifested or request failed for ~whatever reason and wipe it
invalid=`{ grep -rL 'name' output_raw/artifacts || true; }`;
[[ ! -z $invalid ]] && (xargs rm <<< $invalid)

# TODO: pull witch name while accounting for unattuned artifacts somehow

# wombo combo join witches + artifacts by witch id
jq -s '.[0] * .[1] | values[] | select(.artifacts != null)' \
    <(jq 'group_by(.id) | map({key: .[0].id|tostring, value: {witch: .[0]}}) | from_entries' output_raw/witches.json) \
    <(jq 'select(.coven.witchId != null) | {id: .id, name: .name, image: .image, external_url: .external_url, description: .description, animation_url: .animation_url, attunementMods: .coven.attunementModifiers, witchId: .coven.witchId, artifactId: .coven.artifactId}' output_raw/artifacts/* \
      | jq -s | jq 'group_by(.witchId) | map({key: .[0].witchId|tostring, value: {artifacts: .}}) | from_entries') \
  | jq -cs \
  > _data/artifacts_and_witches.json

jq '{id: .id, name: .name, image: .image, external_url: .external_url, description: .description, animation_url: .animation_url, attunementMods: .coven.attunementModifiers, witchId: .coven.witchId, artifactId: .coven.artifactId}' output_raw/artifacts/* | jq -cs > _data/all_artifacts.json

jq -cs '{witches: .[0], artifacts: .[1]}' \
    <(jq 'map({key: .witch.id, value: 1}) | from_entries' _data/artifacts_and_witches.json) \
    <(jq 'map({key: .id, value: 1}) | from_entries' _data/all_artifacts.json) \
  > assets/exists.json
