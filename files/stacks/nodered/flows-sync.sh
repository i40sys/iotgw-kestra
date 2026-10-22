#!/bin/sh
# flows-sync.sh <project> — install the flows-repo checkout the CONTROLLER
# pushed (tasks/nodered.yaml) as the Node-RED project, without ever losing the
# operator's work. Runs in a throw-away nodered/node-red container (it has git)
# as uid 1000, with the stack's data/ mounted at /data, while Node-RED is
# stopped.
#
#   /data/projects/.iotgw-incoming/<project>   fresh checkout from the controller
#   /data/projects/<project>                   the project Node-RED runs
#
# Policy: the gateway copy is REPLACED only when that loses nothing, i.e. its
# working tree is clean (Node-RED's *.backup files aside) and every local branch
# head is a commit the fresh checkout also has (everything was pushed). Otherwise
# the gateway copy is KEPT untouched and the run says why; the operator commits +
# pushes (or discards) in the editor and the next provisioning refreshes it.
#
# Prints one line: "flows-sync: installed|replaced|kept <reason>".
set -eu

project="$1"
cur="/data/projects/$project"
new="/data/projects/.iotgw-incoming/$project"

[ -d "$new/.git" ] || { echo "flows-sync: no incoming checkout at $new" >&2; exit 1; }

finish() { rm -rf /data/projects/.iotgw-incoming; echo "flows-sync: $*"; exit 0; }

if [ ! -e "$cur" ]; then
  mv "$new" "$cur"
  finish "installed $(git -C "$cur" rev-parse --short HEAD)"
fi

if [ ! -d "$cur/.git" ]; then
  finish "kept $cur is not a git checkout; move it away to get the repo's version"
fi

changes="$(git -C "$cur" status --porcelain --untracked-files=all 2>&1 | grep -v '\.backup$' || true)"
if [ -n "$changes" ]; then
  finish "kept uncommitted changes in the editor ($(printf '%s\n' "$changes" | wc -l) file(s)); commit + push or discard them, then re-provision"
fi

unpushed=""
for c in $(git -C "$cur" for-each-ref --format='%(objectname)' refs/heads); do
  git -C "$new" cat-file -e "$c^{commit}" 2>/dev/null || unpushed="$unpushed $(git -C "$cur" rev-parse --short "$c")"
done
if [ -n "$unpushed" ]; then
  finish "kept local commit(s) not in the repo:$unpushed; push them, then re-provision"
fi

old="$(git -C "$cur" rev-parse --short HEAD 2>/dev/null || echo none)"
rm -rf "$cur"
mv "$new" "$cur"
finish "replaced $old -> $(git -C "$cur" rev-parse --short HEAD)"
