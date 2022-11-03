#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n'

# grab witch data off home page
# curl $CC_NEXT_URL | jq '.pageProps.witches | map({id, name, image})' > output_raw/witches.json

# TODO: replace, calc max based on stuff currently in ouput dir
max=${1:-20}
# # assume that between runs there have been a max of 100 new mints
# max=`bc <<< "`ls output_raw/artifacts | cut -f 1 -d '.' | sort -n | tail -n1` + 100"`

mkdir -p output_raw/artifacts
base_url="https://cryptocoven.xyz/api/hut/artifacts/metadata"

seq 1 $max | xargs -P 4 -I {} sh -c "(test ! -e output_raw/artifacts/{}.json) && (echo 'pulling artifact {}'; curl --silent $base_url/{} | jq > output_raw/artifacts/{}.json) || exit 0";

# if output doesn't have name, assume it hasn't been manifested or request failed for ~whatever reason and wipe it
invalid=`{ grep -rL 'name' output_raw/artifacts || true; }`;
[[ ! -z $invalid ]] && (xargs rm <<< $invalid)

# TODO:
# - -c below
# - prob prune unneeded attrs
# - prob make all_artifacts a projection of artifacts_and_witches to get e.g. witch name

# wombo combo join witches + artifacts by witch id
jq -s '.[0] * .[1] | values[] | select(.artifacts != null)' \
    <(jq 'group_by(.id) | map({key: .[0].id|tostring, value: {witch: .[0]}}) | from_entries' output_raw/witches.json) \
    <(jq 'select(.coven.witchId != null)' output_raw/artifacts/* | jq -s | jq 'group_by(.coven.witchId) | map({key: .[0].coven.witchId|tostring, value: {artifacts: .}}) | from_entries') \
  | jq -s \
  > _data/artifacts_and_witches.json

jq -s '.' output_raw/artifacts/* > _data/all_artifacts.json
