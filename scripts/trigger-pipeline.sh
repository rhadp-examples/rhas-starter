#!/usr/bin/env bash
#
# Trigger the Pipelines-as-Code build/validate PipelineRun without a git push.
# Posts a signed GitHub push webhook to the PAC controller — the same path a
# real GitHub delivery uses — targeting the current (or specified) commit on
# the given branch.
#
# Prerequisites:
#   - oc logged into the cluster (scripts/buildspace.sh already set up)
#   - the github-webhook-config secret exists in the buildspace namespace
#   - jq, openssl, curl, git
#
# Usage:
#   scripts/trigger-pipeline.sh [branch] [revision]
#
# Examples:
#   scripts/trigger-pipeline.sh              # main @ origin/main
#   scripts/trigger-pipeline.sh main         # main @ origin/main
#   scripts/trigger-pipeline.sh main abc123  # main @ specific SHA

set -euo pipefail

BRANCH="${1:-main}"
REVISION_ARG="${2:-}"

for cmd in oc jq openssl curl git; do
  command -v "$cmd" >/dev/null || {
    echo "error: required command not found: $cmd" >&2
    exit 1
  }
done

oc whoami >/dev/null || {
  echo "error: not logged into OpenShift (run: oc login ...)" >&2
  exit 1
}

# Resolve GitHub repo from the origin remote (same as buildspace.sh)
GIT_REMOTE_URL=$(git remote get-url origin)
GIT_REPO=${GIT_REMOTE_URL#*github.com[:/]}
GIT_REPO=${GIT_REPO%.git}
GIT_OWNER=${GIT_REPO%%/*}
GIT_NAME=${GIT_REPO#*/}

NAMESPACE=buildspace-$(echo "$GIT_REPO" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-zA-Z0-9-]/-/g; s/-\+/-/g; s/^-//; s/-$//' | cut -c1-63)
REPOSITORY_NAME=$NAMESPACE-pac

if ! oc get namespace "$NAMESPACE" &>/dev/null; then
  echo "error: namespace $NAMESPACE not found; run scripts/buildspace.sh first" >&2
  exit 1
fi

if ! oc get secret github-webhook-config -n "$NAMESPACE" &>/dev/null; then
  echo "error: secret github-webhook-config missing in $NAMESPACE; run scripts/buildspace.sh first" >&2
  exit 1
fi

WEBHOOK_SECRET=$(oc get secret github-webhook-config -n "$NAMESPACE" \
  -o jsonpath='{.data.webhook\.secret}' | base64 -d)
if [[ -z "$WEBHOOK_SECRET" ]]; then
  echo "error: webhook.secret is empty in github-webhook-config" >&2
  exit 1
fi

CONSOLE_URL=$(oc whoami --show-console)
BASE_URL=${CONSOLE_URL#https://console-openshift-console.}
PAC_ENDPOINT="https://pipelines-as-code-controller-openshift-pipelines.$BASE_URL"

# Prefer the remote tip so PAC clones a commit that exists on GitHub
if [[ -n "$REVISION_ARG" ]]; then
  REVISION="$REVISION_ARG"
else
  git fetch --quiet origin "$BRANCH" 2>/dev/null || true
  if git rev-parse --verify --quiet "origin/$BRANCH" >/dev/null; then
    REVISION=$(git rev-parse "origin/$BRANCH")
  elif git rev-parse --verify --quiet "$BRANCH" >/dev/null; then
    REVISION=$(git rev-parse "$BRANCH")
  else
    echo "error: cannot resolve revision for branch '$BRANCH'" >&2
    exit 1
  fi
fi

SENDER=$(oc whoami 2>/dev/null | tr -c 'A-Za-z0-9._-' '-' | sed 's/^-//;s/-$//' || true)
SENDER=${SENDER:-manual-trigger}
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DELIVERY_ID=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || openssl rand -hex 16)

# Include a path under src/** so pipelinesascode.tekton.dev/on-path-change matches.
PAYLOAD=$(jq -n \
  --arg ref "refs/heads/$BRANCH" \
  --arg after "$REVISION" \
  --arg owner "$GIT_OWNER" \
  --arg name "$GIT_NAME" \
  --arg full_name "$GIT_REPO" \
  --arg sender "$SENDER" \
  --arg ts "$TIMESTAMP" \
  '{
    ref: $ref,
    before: "0000000000000000000000000000000000000000",
    after: $after,
    created: false,
    deleted: false,
    forced: false,
    repository: {
      id: 1,
      name: $name,
      full_name: $full_name,
      private: true,
      owner: { login: $owner, name: $owner },
      html_url: ("https://github.com/" + $full_name),
      clone_url: ("https://github.com/" + $full_name + ".git"),
      default_branch: "main"
    },
    pusher: { name: $sender, email: ($sender + "@users.noreply.github.com") },
    sender: { login: $sender, id: 1, type: "User" },
    head_commit: {
      id: $after,
      tree_id: $after,
      distinct: true,
      message: "manual pipeline trigger (no code change)",
      timestamp: $ts,
      url: ("https://github.com/" + $full_name + "/commit/" + $after),
      author: { name: $sender, email: ($sender + "@users.noreply.github.com"), username: $sender },
      committer: { name: $sender, email: ($sender + "@users.noreply.github.com"), username: $sender },
      added: [],
      removed: [],
      modified: ["src/main.cpp"]
    },
    commits: [
      {
        id: $after,
        tree_id: $after,
        distinct: true,
        message: "manual pipeline trigger (no code change)",
        timestamp: $ts,
        url: ("https://github.com/" + $full_name + "/commit/" + $after),
        author: { name: $sender, email: ($sender + "@users.noreply.github.com"), username: $sender },
        committer: { name: $sender, email: ($sender + "@users.noreply.github.com"), username: $sender },
        added: [],
        removed: [],
        modified: ["src/main.cpp"]
      }
    ]
  }')

PAYLOAD_FILE=$(mktemp)
trap 'rm -f "$PAYLOAD_FILE"' EXIT
printf '%s' "$PAYLOAD" >"$PAYLOAD_FILE"

SIGNATURE=$(openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" "$PAYLOAD_FILE" | awk '{print $NF}')

echo "Triggering PipelineRun via PAC webhook"
echo "  repository : $GIT_REPO"
echo "  namespace  : $NAMESPACE"
echo "  branch     : $BRANCH"
echo "  revision   : $REVISION"
echo "  endpoint   : $PAC_ENDPOINT"
echo

HTTP_CODE=$(curl -sS -o /tmp/pac-trigger-response.txt -w "%{http_code}" -X POST "$PAC_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "User-Agent: rhas-starter-trigger-pipeline/1.0" \
  -H "X-GitHub-Event: push" \
  -H "X-GitHub-Delivery: $DELIVERY_ID" \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  --data-binary @"$PAYLOAD_FILE")

if [[ "$HTTP_CODE" != "200" && "$HTTP_CODE" != "201" && "$HTTP_CODE" != "202" ]]; then
  echo "error: PAC returned HTTP $HTTP_CODE" >&2
  cat /tmp/pac-trigger-response.txt >&2 || true
  echo >&2
  exit 1
fi

echo "PAC accepted the event (HTTP $HTTP_CODE)."
if [[ -s /tmp/pac-trigger-response.txt ]]; then
  cat /tmp/pac-trigger-response.txt
  echo
fi

echo "Watch runs with:"
echo "  oc get pipelineruns -n $NAMESPACE -w"
echo "  oc get repository $REPOSITORY_NAME -n $NAMESPACE -o yaml"
