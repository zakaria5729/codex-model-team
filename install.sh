#!/usr/bin/env bash
# Install Codex Model Team into the current project (or an optional target path).
# Requires Bash, curl, tar, and standard Unix utilities. No Python, Node.js, or Git required.
set -Eeuo pipefail

PLUGIN_NAME="codex-model-team"
DEFAULT_REPO_NAME="codex-model-team"
DEFAULT_REPO_REF="main"
MARKETPLACE_NAME="codex-model-team"

TARGET_DIR="$PWD"
TARGET_WAS_SET=0
OWNER_OVERRIDE=""
REPO_OVERRIDE=""
REF_OVERRIDE=""

usage() {
  cat <<'USAGE'
Codex Model Team installer

Usage:
  ./install.sh [PROJECT_DIRECTORY] [options]

Options:
  -u, --username OWNER   GitHub username or organization that owns the toolkit repo
  -r, --repo NAME       Toolkit repository name (default: codex-model-team)
      --ref REF          Git branch/ref (default: main)
      --target DIR       Target project directory (default: current directory)
  -h, --help             Show this help

Interactive behavior:
  - The installer asks for the GitHub owner if it is not supplied.
  - If this project was installed before, Enter keeps the saved owner.
  - Enter a different owner to change it at any time.

Non-interactive usage:
  ./install.sh --username YOUR_GITHUB_USERNAME

  Or set CODEX_MODEL_TEAM_OWNER, CODEX_MODEL_TEAM_REPO, and CODEX_MODEL_TEAM_REF.

For a no-clone installation, run this script directly from GitHub Raw:
  curl -fsSL https://raw.githubusercontent.com/OWNER/codex-model-team/main/install.sh | bash

The script opens /dev/tty for prompts, so the prompt also works when the script is piped.
USAGE
}

fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }
info() { printf '\n==> %s\n' "$*"; }

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
      (($# >= 2)) || fail "Missing value after $1"
      REF_OVERRIDE="$2"
      shift 2
      ;;
    --ref=*)
      REF_OVERRIDE="${1#*=}"
      shift
      ;;
    --target)
      (($# >= 2)) || fail "Missing value after $1"
      TARGET_DIR="$2"
      TARGET_WAS_SET=1
      shift 2
      ;;
    --target=*)
      TARGET_DIR="${1#*=}"
      TARGET_WAS_SET=1
      shift
      ;;
    --)
      shift
      if (($#)); then
        if ((TARGET_WAS_SET)); then fail "Target directory was specified more than once"; fi
        TARGET_DIR="$1"
        TARGET_WAS_SET=1
        shift
      fi
      (($# == 0)) || fail "Unexpected arguments after target directory"
      ;;
    -* )
      fail "Unknown option: $1 (use --help)"
      ;;
    *)
      if ((TARGET_WAS_SET)); then
        fail "Only one target directory may be specified"
      fi
      TARGET_DIR="$1"
      TARGET_WAS_SET=1
      shift
      ;;
  esac
done

[[ -d "$TARGET_DIR" ]] || fail "Target directory does not exist: $TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd -P)"

for required in curl tar awk grep cp mkdir mktemp cmp rm basename dirname sed cat mv; do
  command -v "$required" >/dev/null 2>&1 || fail "Required command not found: $required"
done

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

# Resolution order: explicit CLI flag, environment variable, saved project setting,
# then an interactive prompt. The saved owner is shown as the default so it can be
# retained with Enter or changed simply by typing another GitHub username/org.
if [[ -n "$OWNER_OVERRIDE" ]]; then
  REPO_OWNER="$OWNER_OVERRIDE"
elif [[ -n "${CODEX_MODEL_TEAM_OWNER:-}" ]]; then
  REPO_OWNER="$CODEX_MODEL_TEAM_OWNER"
else
  REPO_OWNER="$SAVED_OWNER"
  if [[ -r /dev/tty ]]; then
    if [[ -n "$REPO_OWNER" ]]; then
      printf 'GitHub username or organization that owns the %s repository [%s]: ' "$DEFAULT_REPO_NAME" "$REPO_OWNER" >/dev/tty
    else
      printf 'GitHub username or organization that owns the %s repository: ' "$DEFAULT_REPO_NAME" >/dev/tty
    fi
    if ! IFS= read -r INPUT_OWNER </dev/tty; then
      INPUT_OWNER=""
    fi
    [[ -n "$INPUT_OWNER" ]] && REPO_OWNER="$INPUT_OWNER"
  elif [[ -z "$REPO_OWNER" ]]; then
    fail "GitHub owner is required. Run interactively or pass --username OWNER / CODEX_MODEL_TEAM_OWNER."
  fi
fi

REPO_NAME="${REPO_OVERRIDE:-${CODEX_MODEL_TEAM_REPO:-${SAVED_REPO:-$DEFAULT_REPO_NAME}}}"
REPO_REF="${REF_OVERRIDE:-${CODEX_MODEL_TEAM_REF:-${SAVED_REF:-$DEFAULT_REPO_REF}}}"

[[ -n "$REPO_OWNER" ]] || fail "GitHub owner cannot be empty."
[[ "$REPO_OWNER" =~ ^[A-Za-z0-9-]{1,39}$ ]] || fail "Invalid GitHub username/organization: $REPO_OWNER"
[[ "$REPO_NAME" =~ ^[A-Za-z0-9._-]{1,100}$ ]] || fail "Invalid GitHub repository name: $REPO_NAME"
[[ "$REPO_REF" =~ ^[A-Za-z0-9._/-]+$ ]] || fail "Invalid Git ref: $REPO_REF"

REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
ARCHIVE_URL="https://codeload.github.com/${REPO_OWNER}/${REPO_NAME}/tar.gz/refs/heads/${REPO_REF}"

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-model-team.XXXXXX")"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

if [[ -n "${CODEX_MODEL_TEAM_SOURCE_DIR:-}" ]]; then
  # Local source override is useful for maintainers testing the installer.
  SOURCE_DIR="$(cd "$CODEX_MODEL_TEAM_SOURCE_DIR" && pwd -P)"
else
  info "Downloading Codex Model Team from ${REPO_OWNER}/${REPO_NAME}@${REPO_REF}"
  curl --fail --location --silent --show-error "$ARCHIVE_URL" -o "$TMP_DIR/source.tar.gz" \
    || fail "Could not download ${ARCHIVE_URL}. Check the owner, repository visibility, and branch."
  mkdir "$TMP_DIR/source"
  tar -xzf "$TMP_DIR/source.tar.gz" --strip-components=1 -C "$TMP_DIR/source" \
    || fail "Could not extract the downloaded repository archive."
  SOURCE_DIR="$TMP_DIR/source"
fi

[[ -d "$SOURCE_DIR/.codex/agents" ]] || fail "Source repository is missing .codex/agents/"
[[ -f "$SOURCE_DIR/plugins/$PLUGIN_NAME/plugin.json" ]] || fail "Source repository is missing the plugin package."

# Prepare marketplace changes before copying files so an unsafe merge cannot leave
# the target project half-installed.
MARKETPLACE_FILE="$TARGET_DIR/.agents/plugins/marketplace.json"
mkdir -p "$(dirname "$MARKETPLACE_FILE")"

if [[ ! -f "$MARKETPLACE_FILE" ]]; then
  cat > "$TMP_DIR/marketplace.json" <<EOF_MARKETPLACE
{
  "name": "${MARKETPLACE_NAME}",
  "interface": {
    "displayName": "Codex Model Team"
  },
  "plugins": [
    {
      "name": "${PLUGIN_NAME}",
      "source": {
        "source": "git-subdir",
        "url": "${REPO_URL}",
        "path": "./plugins/${PLUGIN_NAME}",
        "ref": "${REPO_REF}"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Productivity"
    }
  ]
}
EOF_MARKETPLACE
elif command -v jq >/dev/null 2>&1; then
  MARKETPLACE_NAME="$(jq -er '.name | strings' "$MARKETPLACE_FILE")" \
    || fail "Existing marketplace JSON is invalid or has no string 'name'."
  jq --arg marketplace "$MARKETPLACE_NAME" \
     --arg display "Codex Model Team" \
     --arg plugin "$PLUGIN_NAME" \
     --arg repo "$REPO_URL" \
     --arg path "./plugins/$PLUGIN_NAME" \
     --arg ref "$REPO_REF" \
     '
       .name = $marketplace
       | .interface = ((.interface // {}) + {displayName: (.interface.displayName // $display)})
       | .plugins = (((.plugins // []) | map(select(.name != $plugin))) + [{
           name: $plugin,
           source: {source: "git-subdir", url: $repo, path: $path, ref: $ref},
           policy: {installation: "AVAILABLE", authentication: "ON_INSTALL"},
           category: "Productivity"
         }])
     ' "$MARKETPLACE_FILE" > "$TMP_DIR/marketplace.json" \
     || fail "Could not merge into existing marketplace JSON. Check its format."
else
  # Without jq, safely update an existing Model Team URL by replacing the exact URL
  # saved by the previous install. We never try to rewrite unrelated marketplace JSON.
  if grep -Eq '"name"[[:space:]]*:[[:space:]]*"'"${PLUGIN_NAME}"'"' "$MARKETPLACE_FILE"; then
    MARKETPLACE_NAME="$(sed -n 's/^[[:space:]]*\"name\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p' "$MARKETPLACE_FILE" | sed -n '1p')"
    [[ -n "$MARKETPLACE_NAME" ]] || fail "Cannot read the existing marketplace name. Install jq or fix the marketplace JSON."
    OLD_OWNER="${SAVED_OWNER:-$REPO_OWNER}"
    OLD_REPO="${SAVED_REPO:-$REPO_NAME}"
    OLD_URL="https://github.com/${OLD_OWNER}/${OLD_REPO}.git"
    if [[ -z "$SAVED_OWNER" ]]; then
      # Backward compatibility for projects installed before model-team.env existed.
      DISCOVERED_URL="$(grep -Eo 'https://github.com/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+\.git' "$MARKETPLACE_FILE" | grep -F "/${REPO_NAME}.git" | sed -n '1p' || true)"
      [[ -n "$DISCOVERED_URL" ]] && OLD_URL="$DISCOVERED_URL"
    fi
    if grep -Fq "$OLD_URL" "$MARKETPLACE_FILE"; then
      # GitHub URLs contain no sed replacement metacharacters with the validation above.
      sed "s|${OLD_URL}|${REPO_URL}|g" "$MARKETPLACE_FILE" > "$TMP_DIR/marketplace.json"
      if [[ "$SAVED_REF" != "$REPO_REF" && -n "$SAVED_REF" ]]; then
        printf '  NOTE: existing marketplace ref is preserved because jq is not installed.\n' >&2
      fi
    elif grep -Fq "$REPO_URL" "$MARKETPLACE_FILE"; then
      cp "$MARKETPLACE_FILE" "$TMP_DIR/marketplace.json"
    else
      fail "An existing marketplace contains a Model Team entry, but its source URL cannot be safely identified. Install jq to update it, or edit the marketplace JSON manually."
    fi
  else
    fail "An existing marketplace was found. Install jq to merge Model Team safely, then rerun this installer. Your existing marketplace was not changed."
  fi
fi

info "Installing project-local agents"
mkdir -p "$CONFIG_DIR/agents"
COPIED=0
PRESERVED=0
for source_file in "$SOURCE_DIR"/.codex/agents/*.toml; do
  [[ -f "$source_file" ]] || continue
  destination="$CONFIG_DIR/agents/$(basename "$source_file")"
  if [[ -e "$destination" ]]; then
    if cmp -s "$source_file" "$destination"; then
      printf '  already current: %s\n' "$(basename "$source_file")"
    else
      printf '  preserved existing file: %s\n' "$(basename "$source_file")"
    fi
    PRESERVED=$((PRESERVED + 1))
  else
    cp "$source_file" "$destination"
    printf '  installed: %s\n' "$(basename "$source_file")"
    COPIED=$((COPIED + 1))
  fi
done

info "Registering the project-local plugin marketplace"
mv "$TMP_DIR/marketplace.json" "$MARKETPLACE_FILE"
printf '  updated: %s\n' "$MARKETPLACE_FILE"

info "Configuring Codex for this project"
CONFIG_FILE="$CONFIG_DIR/config.toml"
if [[ ! -f "$CONFIG_FILE" ]]; then
  cat > "$CONFIG_FILE" <<EOF_CONFIG
# Project-local defaults for Codex Model Team.
model = "gpt-6.2-sol"
model_reasoning_effort = "medium"
plan_mode_reasoning_effort = "high"

[agents]
max_concurrent_threads_per_session = 4

[plugins."${PLUGIN_NAME}@${MARKETPLACE_NAME}"]
enabled = true
EOF_CONFIG
  printf '  created project config with Sol / Medium defaults and plugin enabled\n'
else
  # Preserve all existing project choices. Fill only missing root model defaults.
  awk '
    BEGIN { in_table=0; first_table=0; seen_model=0; seen_effort=0; seen_plan=0 }
    {
      lines[NR]=$0
      if ($0 ~ /^[[:space:]]*\[/) {
        if (!first_table) first_table=NR
        in_table=1
      }
      if (!in_table && $0 ~ /^[[:space:]]*model[[:space:]]*=/) seen_model=1
      if (!in_table && $0 ~ /^[[:space:]]*model_reasoning_effort[[:space:]]*=/) seen_effort=1
      if (!in_table && $0 ~ /^[[:space:]]*plan_mode_reasoning_effort[[:space:]]*=/) seen_plan=1
    }
    END {
      if (!first_table) first_table=NR+1
      for (i=1; i<first_table; i++) print lines[i]
      if (!seen_model) print "model = \"gpt-6.2-sol\""
      if (!seen_effort) print "model_reasoning_effort = \"medium\""
      if (!seen_plan) print "plan_mode_reasoning_effort = \"high\""
      if (first_table <= NR) {
        if (first_table > 1 || !seen_model || !seen_effort || !seen_plan) print ""
        for (i=first_table; i<=NR; i++) print lines[i]
      }
    }
  ' "$CONFIG_FILE" > "$TMP_DIR/config.toml"
  mv "$TMP_DIR/config.toml" "$CONFIG_FILE"

  PLUGIN_TABLE="[plugins.\"${PLUGIN_NAME}@${MARKETPLACE_NAME}\"]"
  if grep -Fq "$PLUGIN_TABLE" "$CONFIG_FILE"; then
    if grep -A3 -F "$PLUGIN_TABLE" "$CONFIG_FILE" | grep -Eq '^[[:space:]]*enabled[[:space:]]*=[[:space:]]*false'; then
      printf '  WARNING: Model Team plugin is explicitly disabled in config.toml.\n' >&2
    else
      printf '  plugin enablement already configured\n'
    fi
  else
    printf '\n%s\nenabled = true\n' "$PLUGIN_TABLE" >> "$CONFIG_FILE"
    printf '  enabled Model Team plugin in existing config\n'
  fi
fi

# Save public source coordinates in the project. These are not credentials/secrets.
# On a later run, the owner prompt defaults to this value; --username can override it.
mkdir -p "$CONFIG_DIR"
cat > "$TMP_DIR/model-team.env" <<EOF_SETTINGS
owner=${REPO_OWNER}
repo=${REPO_NAME}
ref=${REPO_REF}
EOF_SETTINGS
mv "$TMP_DIR/model-team.env" "$MODEL_TEAM_CONFIG"

printf '\nCodex Model Team installed in:\n  %s\n' "$TARGET_DIR"
printf '\nSaved toolkit source:\n  %s\n' "$REPO_URL"
printf '  branch/ref: %s\n' "$REPO_REF"
printf '\nNext steps:\n'
printf '  1. cd "%s"\n' "$TARGET_DIR"
printf '  2. Start Codex: codex\n'
printf '  3. Trust this project if Codex asks.\n'
printf '  4. Check marketplaces: codex plugin marketplace list\n'
printf '  5. Ask Codex to use the Model Team skill.\n'
printf '\nAgents installed: %s; existing files preserved: %s\n' "$COPIED" "$PRESERVED"
printf '\nTo change the saved GitHub owner later, rerun this installer and enter a new owner,\n'
printf 'or pass: --username NEW_GITHUB_USERNAME\n'
printf 'Project settings saved in: %s\n' "$MODEL_TEAM_CONFIG"
printf '\nNote: this script does not change ~/.codex/config.toml or ~/.codex/agents/.\n'
