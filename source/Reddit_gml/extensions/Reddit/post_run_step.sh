#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Paths / utils
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
Utils="$SCRIPT_DIR/scriptUtils.sh"
# shellcheck source=/dev/null
. "$Utils"

# Always init the script (sets LOG_LABEL/LOG_LEVEL, pulls EXTENSION_NAME, etc.)
scriptInit

# -----------------------------------------------------------------------------
# Fetch extension options
# -----------------------------------------------------------------------------
# Version locks (kept for parity; not used directly here)
optionGetValue "versionStable" RUNTIME_VERSION_STABLE
optionGetValue "versionBeta"   RUNTIME_VERSION_BETA
optionGetValue "versionDev"    RUNTIME_VERSION_DEV
optionGetValue "versionLTS"    RUNTIME_VERSION_LTS

# Extension specific
optionGetValue "outputPath"  OUTPUT_PATH
optionGetValue "projectName" PROJECT_NAME

# -----------------------------------------------------------------------------
# Validate project name (3–16 of a–z, 0–9, hyphen)
# -----------------------------------------------------------------------------
if [[ -z "${PROJECT_NAME:-}" ]]; then
  logError "Extension option 'Project Name' is required and cannot be empty."
fi

if ! [[ "$PROJECT_NAME" =~ ^[a-z0-9-]{3,16}$ ]]; then
  logError "Project name must be 3-16 chars and only contain lowercase letters, numbers, or hyphens."
fi

# -----------------------------------------------------------------------------
# Resolve the output directory (relative to YYprojectDir)
# -----------------------------------------------------------------------------
pathResolve "${YYprojectDir:-/}" "${OUTPUT_PATH:-.}" OUTPUT_DIR

# -----------------------------------------------------------------------------
# Ensure output/project directory exists (matches BAT behavior)
# -----------------------------------------------------------------------------
mkdir -p "$OUTPUT_DIR"

# -----------------------------------------------------------------------------
# Verify the app exists in Devvit; fail if NOT found
# - Install devvit locally (per-project)
# - Use npx devvit list apps and search for PROJECT_NAME as a token
# -----------------------------------------------------------------------------
pushd "$OUTPUT_DIR" >/dev/null

# Install devvit locally for this project only
if ! command -v npm >/dev/null 2>&1; then
  logError "npm was not found on PATH. Please install Node.js/npm."
fi

npm install --save-dev devvit@latest >/dev/null 2>&1 || {
  logError "Failed to install devvit locally (npm install --save-dev devvit@latest)."
}

DEVVIT_LIST="$(mktemp -t "devvit_apps.XXXXXX.txt")"
# Capture both stdout/stderr like the BAT (it redirects 2>&1)
# Do not let a non-zero exit crash the script before we can show a useful error.
if ! npx devvit list apps >"$DEVVIT_LIST" 2>&1; then
  : # handled below by checking file/content
fi

if [[ ! -f "$DEVVIT_LIST" ]]; then
  popd >/dev/null
  logError "Could not retrieve Devvit app list."
fi

# If list is empty, treat as failure (mirrors BAT's "file missing" intent, but stricter)
if [[ ! -s "$DEVVIT_LIST" ]]; then
  rm -f "$DEVVIT_LIST"
  popd >/dev/null
  logError "Could not retrieve Devvit app list."
fi

# Match as a standalone field anywhere on a line (handles leading whitespace, etc.)
if ! awk -v needle="$PROJECT_NAME" '
  {
    for (i=1; i<=NF; i++) if ($i==needle) { found=1; exit }
  }
  END { exit found ? 0 : 1 }
' "$DEVVIT_LIST"; then
  rm -f "$DEVVIT_LIST"
  popd >/dev/null
  logError "Devvit app '$PROJECT_NAME' was not found. Create the app first: https://developers.reddit.com/new."
fi

rm -f "$DEVVIT_LIST"
logInformation "Devvit app '$PROJECT_NAME' confirmed."
popd >/dev/null

# -----------------------------------------------------------------------------
# Make sure we have a devvit project (zip fallback only, per BAT)
# - BAT checks for setup-gamemaker-devvit.bat to decide if template exists
# - On bash, prefer .sh, but keep parity by accepting either as "project exists"
# -----------------------------------------------------------------------------
TEMPLATE_ZIP="$SCRIPT_DIR/GameMakerRedditTemplate.zip"
if [[ ! -f "$OUTPUT_DIR/setup-gamemaker-devvit.bat" && ! -f "$OUTPUT_DIR/setup-gamemaker-devvit.sh" ]]; then
  mkdir -p "$OUTPUT_DIR"

  if [[ ! -f "$TEMPLATE_ZIP" ]]; then
    logError "Fallback zip not found: $TEMPLATE_ZIP"
  fi

  logInformation "Local template project found, expanding..."

  # Extract as-is into ./$OUTPUT_DIR (similar spirit to Expand-Archive ... '%OUTPUT_DIR%')
  if command -v unzip >/dev/null 2>&1; then
    unzip -q -o "$TEMPLATE_ZIP" -d "$OUTPUT_DIR" || {
      logError "Failed to expand fallback zip."
    }
  else
    # macOS/Linux typically have one of these; use whatever is available.
    if command -v bsdtar >/dev/null 2>&1; then
      bsdtar -xf "$TEMPLATE_ZIP" -C "$OUTPUT_DIR" || {
        logError "Failed to expand fallback zip."
      }
    else
      logError "Neither 'unzip' nor 'bsdtar' is available to extract $TEMPLATE_ZIP."
    fi
  fi

  logInformation "Local template project extracted."
fi

# -----------------------------------------------------------------------------
# Run the template's setup script
# - BAT runs setup-gamemaker-devvit.bat with: (YYoutputFolder, PROJECT_NAME)
# - Bash prefers setup-gamemaker-devvit.sh; if only .bat exists and cmd is present,
#   it will try to run it (useful on Git-Bash/MSYS).
# -----------------------------------------------------------------------------
pushd "$OUTPUT_DIR/$PROJECT_NAME" >/dev/null

if [[ -x "./setup-gamemaker-devvit.sh" ]]; then
  ./setup-gamemaker-devvit.sh "${YYoutputFolder:-}" "$PROJECT_NAME"
elif [[ -f "./setup-gamemaker-devvit.sh" ]]; then
  sh ./setup-gamemaker-devvit.sh "${YYoutputFolder:-}" "$PROJECT_NAME"
else
  popd >/dev/null
  logError "Current folder '$PWD' not valid devvit GameMaker project (missing setup-gamemaker-devvit.sh/.bat)."
fi

npm install --no-fund --no-audit >/dev/null 2>&1 || {
  popd >/dev/null
  logError "Failed to install dependencies."
}

popd >/dev/null

logInformation "Project build updated successfully."

# Match BAT’s non-zero exit for tool runner behavior
exit 1
