
#!/usr/bin/env bash
# Codex Model Team - project-local installer
# Default repository: zakaria5729/codex-model-team

set -Eeuo pipefail

# --------------------------------------------------
# Defaults
# --------------------------------------------------

DEFAULT_OWNER="zakaria5729"
DEFAULT_REPO="codex-model-team"
DEFAULT_REF="main"

PLUGIN_NAME="codex-model-team"
MARKETPLACE_NAME="codex-model-team"

TARGET_DIR="$PWD"
OWNER_OVERRIDE=""
REPO_OVERRIDE=""
REF_OVERRIDE=""

# --------------------------------------------------
# Helpers
# --------------------------------------------------

info() {
  printf '\n==> %s\n' "$*"
}

fail() {
  printf '\nERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Codex Model Team Installer

Usage:
  ./install.sh [options]

Options:
  -u, --username OWNER   GitHub username or organization
  -r, --repo NAME        Repository name (default: codex-model-team)
      --ref REF          Git branch (default: main)
      --target DIR       Target project directory
  -h, --help             Show this help

Examples:
  ./install.sh
  ./install.sh --username another-owner
  ./install.sh --target ~/projects/my-app
  ./install.sh --username another-owner --repo codex-model-team

Default repository:
  https://github.com/zakaria5729/codex-model-team

The default owner is zakaria5729.
No username prompt is required.
EOF
}

# --------------------------------------------------
# Parse arguments
# --------------------------------------------------

while (($#)); do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;

    -u|--username|--owner)
      (($# >= 2)) || fail "Missing value after $1"
      OWNER_OVERRIDE="$2"
      shift 2
      ;;

    --username=*)
      OWNER_OVERRIDE="${1#*=}"
      shift
      ;;

    -r|--repo)
      (($# >= 2)) || fail "Missing value after $1"
      REPO_OVERRIDE="$2"
      shift 2
      ;;

    --repo=*)
      REPO_OVERRIDE="${1#*=}"
      shift
      ;;

    --ref)
      (($# >= 2)) || fail "Missing value after --ref"
      REF_OVERRIDE="$2"
      shift 2
      ;;

    --ref=*)
      REF_OVERRIDE="${1#*=}"
      shift
      ;;

    --target)
      (($# >= 2)) || fail "Missing value after --target"
      TARGET_DIR="$2"
      shift 2
      ;;

    --target=*)
      TARGET_DIR="${1#*=}"
      shift
      ;;

    *)
      fail "Unknown argument: $1. Use --help."
      ;;
  esac
done

# --------------------------------------------------
# Validate environment
# --------------------------------------------------

[[ -d "$TARGET_DIR" ]] || fail "Target directory does not exist: $TARGET_DIR"

TARGET_DIR="$(cd "$TARGET_DIR" && pwd -P)"

for cmd in curl tar awk grep cp mkdir mktemp cmp rm basename dirname sed cat mv; do
  command -v "$cmd" >/dev/null 2>&1 || fail "Required command not found: $cmd"
done

# --------------------------------------------------
# Resolve repository owner
#
# Priority:
# 1. --username argument
# 2. Environment variable
# 3. Previously saved project owner
# 4. Default owner
# --------------------------------------------------

CONFIG_DIR="$TARGET_DIR/.codex"
MODEL_TEAM_CONFIG="$CONFIG_DIR/model-team.env"

SAVED_OWNER=""
SAVED_REPO=""
SAVED_REF=""

read_saved_value() {
  local key="$1"
  local file="$2"

  [[ -f "$file" ]] || return 0

  sed -n "s/^${key}=//p" "$file" | sed -n '1p'
}

if [[ -f "$MODEL_TEAM_CONFIG" ]]; then
  SAVED_OWNER="$(read_saved_value owner "$MODEL_TEAM_CONFIG")"
  SAVED_REPO="$(read_saved_value repo "$MODEL_TEAM_CONFIG")"
  SAVED_REF="$(read_saved_value ref "$MODEL_TEAM_CONFIG")"
fi

if [[ -n "$OWNER_OVERRIDE" ]]; then
  REPO_OWNER="$OWNER_OVERRIDE"
elif [[ -n "${CODEX_MODEL_TEAM_OWNER:-}" ]]; then
  REPO_OWNER="$CODEX_MODEL_TEAM_OWNER"
elif [[ -n "$SAVED_OWNER" ]]; then
  REPO_OWNER="$SAVED_OWNER"
else
  REPO_OWNER="$DEFAULT_OWNER"
fi

REPO_NAME="${REPO_OVERRIDE:-${CODEX_MODEL_TEAM_REPO:-${SAVED_REPO:-$DEFAULT_REPO}}}"
REPO_REF="${REF_OVERRIDE:-${CODEX_MODEL_TEAM_REF:-${SAVED_REF:-$DEFAULT_REF}}}"

# --------------------------------------------------
# Validate repository coordinates
# --------------------------------------------------

[[ "$REPO_OWNER" =~ ^[A-Za-z0-9-]{1,39}$ ]] \
  || fail "Invalid GitHub owner: $REPO_OWNER"

[[ "$REPO_NAME" =~ ^[A-Za-z0-9._-]{1,100}$ ]] \
  || fail "Invalid repository name: $REPO_NAME"

[[ "$REPO_REF" =~ ^[A-Za-z0-9._/-]+$ ]] \
  || fail "Invalid Git reference: $REPO_REF"

REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"

ARCHIVE_URL="https://codeload.github.com/${REPO_OWNER}/${REPO_NAME}/tar.gz/refs/heads/${REPO_REF}"

info "Codex Model Team"
printf 'Repository : %s/%s\n' "$REPO_OWNER" "$REPO_NAME"
printf 'Branch     : %s\n' "$REPO_REF"
printf 'Target     : %s\n' "$TARGET_DIR"

# --------------------------------------------------
# Download repository
# --------------------------------------------------

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-model-team.XXXXXX")"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

if [[ -n "${CODEX_MODEL_TEAM_SOURCE_DIR:-}" ]]; then
  SOURCE_DIR="$(cd "$CODEX_MODEL_TEAM_SOURCE_DIR" && pwd -P)"
else
  info "Downloading repository..."

  curl --fail --location --silent --show-error \
    "$ARCHIVE_URL" \
    -o "$TMP_DIR/source.tar.gz" \
    || fail "Could not download repository. Check owner, repository, and branch."

  mkdir "$TMP_DIR/source"

  tar -xzf "$TMP_DIR/source.tar.gz" \
    --strip-components=1 \
    -C "$TMP_DIR/source" \
    || fail "Could not extract repository archive."

  SOURCE_DIR="$TMP_DIR/source"
fi

# --------------------------------------------------
# Validate downloaded source
# --------------------------------------------------

[[ -d "$SOURCE_DIR/.codex/agents" ]] \
  || fail "Repository is missing .codex/agents/"

[[ -f "$SOURCE_DIR/plugins/$PLUGIN_NAME/plugin.json" ]] \
  || fail "Repository is missing the plugin package."

# --------------------------------------------------
# Prepare marketplace configuration
# --------------------------------------------------

MARKETPLACE_FILE="$TARGET_DIR/.agents/plugins/marketplace.json"

mkdir -p "$(dirname "$MARKETPLACE_FILE")"

if [[ ! -f "$MARKETPLACE_FILE" ]]; then

  cat > "$TMP_DIR/marketplace.json" <<EOF
{
  "name": "$MARKETPLACE_NAME",
  "interface": {
    "displayName": "Codex Model Team"
  },
  "plugins": [
    {
      "name": "$PLUGIN_NAME",
      "source": {
        "source": "git-subdir",
        "url": "$REPO_URL",
        "path": "./plugins/$PLUGIN_NAME",
        "ref": "$REPO_REF"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Productivity"
    }
  ]
}
EOF

elif command -v jq >/dev/null 2>&1; then

  jq \
    --arg plugin "$PLUGIN_NAME" \
    --arg repo "$REPO_URL" \
    --arg path "./plugins/$PLUGIN_NAME" \
    --arg ref "$REPO_REF" \
    --arg display "Codex Model Team" \
    '
    .name = (.name // "project-marketplace")
    | .interface = ((.interface // {}) + {
        displayName: (.interface.displayName // $display)
      })
    | .plugins = (
        ((.plugins // []) | map(select(.name != $plugin)))
        + [{
            name: $plugin,
            source: {
              source: "git-subdir",
              url: $repo,
              path: $path,
              ref: $ref
            },
            policy: {
              installation: "AVAILABLE",
              authentication: "ON_INSTALL"
            },
            category: "Productivity"
          }]
      )
    ' "$MARKETPLACE_FILE" > "$TMP_DIR/marketplace.json" \
    || fail "Could not update existing marketplace JSON."

else

  fail "An existing marketplace.json was found. Install jq to safely merge the Model Team marketplace without overwriting other plugins."

fi

# --------------------------------------------------
# Install custom agents
# --------------------------------------------------

info "Installing project-local agents..."

mkdir -p "$CONFIG_DIR/agents"

COPIED=0
PRESERVED=0

for source_file in "$SOURCE_DIR"/.codex/agents/*.toml; do

  [[ -f "$source_file" ]] || continue

  filename="$(basename "$source_file")"
  destination="$CONFIG_DIR/agents/$filename"

  if [[ -e "$destination" ]]; then

    if cmp -s "$source_file" "$destination"; then
      printf '  already current: %s\n' "$filename"
    else
      printf '  preserved existing: %s\n' "$filename"
    fi

    PRESERVED=$((PRESERVED + 1))

  else

    cp "$source_file" "$destination"

    printf '  installed: %s\n' "$filename"

    COPIED=$((COPIED + 1))

  fi

done

# --------------------------------------------------
# Register marketplace
# --------------------------------------------------

info "Registering plugin marketplace..."

mv "$TMP_DIR/marketplace.json" "$MARKETPLACE_FILE"

printf '  updated: %s\n' "$MARKETPLACE_FILE"

# --------------------------------------------------
# Configure project-local Codex settings
# --------------------------------------------------

info "Configuring Codex..."

CONFIG_FILE="$CONFIG_DIR/config.toml"

if [[ ! -f "$CONFIG_FILE" ]]; then

  cat > "$CONFIG_FILE" <<EOF
# Project-local Codex Model Team configuration.

model = "gpt-6.2-sol"
model_reasoning_effort = "medium"
plan_mode_reasoning_effort = "high"

[agents]
max_concurrent_threads_per_session = 4

[plugins."${PLUGIN_NAME}@${MARKETPLACE_NAME}"]
enabled = true
EOF

  printf '  created project config\n'

else

  awk '
    BEGIN {
      in_table = 0
      first_table = 0
      seen_model = 0
      seen_effort = 0
      seen_plan = 0
    }

    {
      lines[NR] = $0

      if ($0 ~ /^[[:space:]]*\[/) {
        if (!first_table) first_table = NR
        in_table = 1
      }

      if (!in_table && $0 ~ /^[[:space:]]*model[[:space:]]*=/)
        seen_model = 1

      if (!in_table && $0 ~ /^[[:space:]]*model_reasoning_effort[[:space:]]*=/)
        seen_effort = 1

      if (!in_table && $0 ~ /^[[:space:]]*plan_mode_reasoning_effort[[:space:]]*=/)
        seen_plan = 1
    }

    END {
      if (!first_table) first_table = NR + 1

      for (i = 1; i < first_table; i++)
        print lines[i]

      if (!seen_model)
        print "model = \"gpt-6.2-sol\""

      if (!seen_effort)
        print "model_reasoning_effort = \"medium\""

      if (!seen_plan)
        print "plan_mode_reasoning_effort = \"high\""

      if (first_table <= NR) {
        print ""
        for (i = first_table; i <= NR; i++)
          print lines[i]
      }
    }
  ' "$CONFIG_FILE" > "$TMP_DIR/config.toml"

  mv "$TMP_DIR/config.toml" "$CONFIG_FILE"

  PLUGIN_TABLE="[plugins.\"${PLUGIN_NAME}@${MARKETPLACE_NAME}\"]"

  if grep -Fq "$PLUGIN_TABLE" "$CONFIG_FILE"; then

    if grep -A3 -F "$PLUGIN_TABLE" "$CONFIG_FILE" \
      | grep -Eq '^[[:space:]]*enabled[[:space:]]*=[[:space:]]*false'; then

      printf '  WARNING: Plugin is explicitly disabled in config.toml\n' >&2

    else

      printf '  plugin configuration already exists\n'

    fi

  else

    printf '\n%s\nenabled = true\n' "$PLUGIN_TABLE" >> "$CONFIG_FILE"

    printf '  enabled Model Team plugin\n'

  fi

fi

# --------------------------------------------------
# Save repository coordinates
# --------------------------------------------------

mkdir -p "$CONFIG_DIR"

cat > "$TMP_DIR/model-team.env" <<EOF
owner=$REPO_OWNER
repo=$REPO_NAME
ref=$REPO_REF
EOF

mv "$TMP_DIR/model-team.env" "$MODEL_TEAM_CONFIG"

# --------------------------------------------------
# Done
# --------------------------------------------------

printf '\n========================================\n'
printf ' Codex Model Team installed successfully\n'
printf '========================================\n'

printf '\nRepository: %s\n' "$REPO_URL"
printf 'Target:     %s\n' "$TARGET_DIR"

printf '\nNext steps:\n'
printf '  1. cd "%s"\n' "$TARGET_DIR"
printf '  2. Run: codex\n'
printf '  3. Trust the project if prompted.\n'
printf '  4. Check: codex plugin marketplace list\n'

printf '\nAgents installed: %s\n' "$COPIED"
printf 'Existing files preserved: %s\n' "$PRESERVED"

printf '\nSaved configuration: %s\n' "$MODEL_TEAM_CONFIG"

printf '\nDefault owner: %s\n' "$DEFAULT_OWNER"

printf '\nTo use another GitHub owner later:\n'
printf '  ./install.sh --username NEW_OWNER\n'

printf '\nNo global Codex configuration was modified.\n'
