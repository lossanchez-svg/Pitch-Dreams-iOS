#!/usr/bin/env bash
#
# test-all-devices.sh — Multi-device test runner for PitchDreams iOS
#
# Usage:
#   ./scripts/test-all-devices.sh [--quick|--full] [--install-runtimes] [--list] [--cleanup]
#
# Modes:
#   --quick   5 representative devices on installed runtimes (default)
#   --full    All valid device/iOS combos
#   --list    Show the device matrix and exit
#   --cleanup Remove all PD-Test-* simulators
#   --install-runtimes  Download missing iOS runtimes before testing

set -euo pipefail

# ─── Config ──────────────────────────────────────────────────────────────────
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$PROJECT_DIR/PitchDreams.xcodeproj"
SCHEME="PitchDreams"
RESULTS_DIR="/tmp/pd-test-results-$$"
SIM_PREFIX="PD-Test"
MAX_PARALLEL=4

# ─── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Device definitions ─────────────────────────────────────────────────────
# Format: "display_name|simctl_device_type_id|min_ios_major"
#
# min_ios_major: the earliest major iOS version this device type exists in.
# Devices that don't exist in older iOS versions are skipped for those runtimes.

DEVICE_DEFS=(
  "iPhone SE 3rd gen|com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation|15"
  "iPhone 14|com.apple.CoreSimulator.SimDeviceType.iPhone-14|16"
  "iPhone 16|com.apple.CoreSimulator.SimDeviceType.iPhone-16|18"
  "iPhone 16 Plus|com.apple.CoreSimulator.SimDeviceType.iPhone-16-Plus|18"
  "iPhone 16 Pro Max|com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro-Max|18"
  "iPhone 17|com.apple.CoreSimulator.SimDeviceType.iPhone-17|26"
  "iPad mini 6th gen|com.apple.CoreSimulator.SimDeviceType.iPad-mini-6th-generation|15"
  "iPad 10th gen|com.apple.CoreSimulator.SimDeviceType.iPad-10th-generation|16"
  "iPad Air 5th gen|com.apple.CoreSimulator.SimDeviceType.iPad-Air-5th-generation|15"
  "iPad Pro 13in M4|com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M4-8GB|18"
)

# Quick mode: representative subset covering small/standard/large iPhone + standard/large iPad
QUICK_DEVICES=(
  "iPhone SE 3rd gen"
  "iPhone 17"
  "iPad 10th gen"
  "iPad Air 5th gen"
  "iPad Pro 13in M4"
)

# Target iOS versions (major.minor)
TARGET_IOS_VERSIONS=("16.0" "17.5" "18.4" "26.4")

# ─── Helpers ─────────────────────────────────────────────────────────────────

get_field() {
  echo "$1" | cut -d'|' -f"$2"
}

get_installed_runtimes() {
  xcrun simctl list runtimes -j 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for rt in data.get('runtimes', []):
    if rt.get('isAvailable') and 'iOS' in rt.get('name', ''):
        print(rt['version'] + '|' + rt['identifier'])
" 2>/dev/null || true
}

runtime_id_for_version() {
  local target_ver="$1"
  local target_major="${target_ver%%.*}"
  while IFS='|' read -r ver rid; do
    local major="${ver%%.*}"
    if [[ "$major" == "$target_major" ]]; then
      echo "$rid"
      return 0
    fi
  done <<< "$INSTALLED_RUNTIMES"
  return 1
}

runtime_version_for_major() {
  local target_major="$1"
  while IFS='|' read -r ver rid; do
    local major="${ver%%.*}"
    if [[ "$major" == "$target_major" ]]; then
      echo "$ver"
      return 0
    fi
  done <<< "$INSTALLED_RUNTIMES"
  return 1
}

sim_name() {
  local device_name="$1"
  local ios_ver="$2"
  local safe_name="${device_name// /-}"
  echo "${SIM_PREFIX}-${safe_name}-iOS${ios_ver}"
}

sim_exists() {
  xcrun simctl list devices -j 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
name = '$1'
for runtime, devs in data.get('devices', {}).items():
    for d in devs:
        if d['name'] == name and d['isAvailable']:
            print(d['udid'])
            sys.exit(0)
sys.exit(1)
" 2>/dev/null
}

create_sim() {
  local name="$1"
  local device_type="$2"
  local runtime_id="$3"
  xcrun simctl create "$name" "$device_type" "$runtime_id" 2>/dev/null
}

boot_sim() {
  local udid="$1"
  local state
  state=$(xcrun simctl list devices -j 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devs in data.get('devices', {}).items():
    for d in devs:
        if d['udid'] == '$udid':
            print(d['state'])
            sys.exit(0)
" 2>/dev/null || echo "Unknown")
  if [[ "$state" != "Booted" ]]; then
    xcrun simctl boot "$udid" 2>/dev/null || true
  fi
}

shutdown_sim() {
  local udid="$1"
  xcrun simctl shutdown "$udid" 2>/dev/null || true
}

# ─── Parse xcresult for test counts ─────────────────────────────────────────

parse_xcresult() {
  local result_path="$1"
  local log_file="$2"

  # Try xcresulttool first
  if [[ -d "$result_path" ]]; then
    local parsed
    parsed=$(python3 -c "
import json, subprocess, sys
try:
    out = subprocess.check_output(
        ['xcrun', 'xcresulttool', 'get', '--path', '$result_path', '--format', 'json'],
        stderr=subprocess.DEVNULL, text=True
    )
    data = json.loads(out)
    metrics = data.get('metrics', {})
    total = metrics.get('testsCount', {}).get('_value', '0')
    failed = metrics.get('testsFailedCount', {}).get('_value', '0')
    passed = int(total) - int(failed)
    print(f'{total}|{passed}|{failed}')
except Exception:
    print('')
" 2>/dev/null || true)
    if [[ -n "$parsed" && "$parsed" != "0|0|0" ]]; then
      echo "$parsed"
      return
    fi
  fi

  # Fallback: parse from log file
  if [[ -f "$log_file" ]]; then
    local parsed
    parsed=$(grep "Executed .* tests" "$log_file" | tail -1 | sed -E 's/.*Executed ([0-9]+) tests?, with ([0-9]+) failures?.*/\1|\2/' 2>/dev/null || true)
    if [[ -n "$parsed" && "$parsed" =~ ^[0-9]+\|[0-9]+$ ]]; then
      local total failed passed
      total=$(echo "$parsed" | cut -d'|' -f1)
      failed=$(echo "$parsed" | cut -d'|' -f2)
      passed=$((total - failed))
      echo "$total|$passed|$failed"
      return
    fi
  fi

  echo "0|0|0"
}

# ─── Build the test list ────────────────────────────────────────────────────

build_test_matrix() {
  local mode="$1"  # "quick" or "full"
  TEST_COMBOS=()

  for def in "${DEVICE_DEFS[@]}"; do
    local name min_ios
    name=$(get_field "$def" 1)
    min_ios=$(get_field "$def" 3)

    # In quick mode, skip devices not in the quick list
    if [[ "$mode" == "quick" ]]; then
      local in_quick=false
      for qd in "${QUICK_DEVICES[@]}"; do
        if [[ "$name" == "$qd" ]]; then
          in_quick=true
          break
        fi
      done
      [[ "$in_quick" == "false" ]] && continue
    fi

    if [[ "$mode" == "quick" ]]; then
      # Quick mode: only use installed runtimes
      while IFS='|' read -r ver rid; do
        local major="${ver%%.*}"
        if (( major >= min_ios )); then
          TEST_COMBOS+=("$def|$ver|$rid")
        fi
      done <<< "$INSTALLED_RUNTIMES"
    else
      # Full mode: try all target iOS versions
      for target_ver in "${TARGET_IOS_VERSIONS[@]}"; do
        local target_major="${target_ver%%.*}"
        if (( target_major >= min_ios )); then
          local rid
          rid=$(runtime_id_for_version "$target_ver" 2>/dev/null) || true
          if [[ -n "$rid" ]]; then
            local actual_ver
            actual_ver=$(runtime_version_for_major "$target_major")
            TEST_COMBOS+=("$def|$actual_ver|$rid")
          else
            SKIPPED_COMBOS+=("$name on iOS $target_ver (runtime not installed)")
          fi
        fi
      done
    fi
  done
}

# ─── Commands ────────────────────────────────────────────────────────────────

cmd_list() {
  echo -e "${BOLD}PitchDreams Multi-Device Test Matrix${RESET}"
  echo ""
  echo "Installed iOS runtimes:"
  while IFS='|' read -r ver rid; do
    echo -e "  ${GREEN}iOS $ver${RESET} ($rid)"
  done <<< "$INSTALLED_RUNTIMES"
  echo ""

  printf "${BOLD}%-25s %-8s %-8s %-8s %-8s${RESET}\n" "Device" "iOS 16" "iOS 17" "iOS 18" "iOS 26"
  echo "─────────────────────────────────────────────────────────────────"
  for def in "${DEVICE_DEFS[@]}"; do
    local name min_ios
    name=$(get_field "$def" 1)
    min_ios=$(get_field "$def" 3)
    local line="$name"
    # Pad name to 25 chars
    while (( ${#line} < 26 )); do line+=" "; done
    for major in 16 17 18 26; do
      if (( major >= min_ios )); then
        local rid
        rid=$(runtime_id_for_version "${major}.0" 2>/dev/null) || true
        if [[ -n "$rid" ]]; then
          line+="${GREEN}YES${RESET}      "
        else
          line+="${YELLOW}N/A${RESET}      "
        fi
      else
        line+="  -      "
      fi
    done
    echo -e "$line"
  done
  echo ""
  echo -e "${GREEN}YES${RESET} = runtime installed, device compatible"
  echo -e "${YELLOW}N/A${RESET} = runtime not installed (use --install-runtimes)"
  echo "  - = device doesn't exist on this iOS version"
}

cmd_cleanup() {
  echo -e "${CYAN}Cleaning up PD-Test simulators...${RESET}"
  local count=0
  for udid in $(xcrun simctl list devices -j 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devs in data.get('devices', {}).items():
    for d in devs:
        if d['name'].startswith('PD-Test'):
            print(d['udid'])
" 2>/dev/null); do
    xcrun simctl delete "$udid" 2>/dev/null && ((count++)) || true
  done
  echo -e "Removed ${GREEN}$count${RESET} simulators."
}

cmd_install_runtimes() {
  echo -e "${CYAN}Checking iOS runtimes...${RESET}"
  for target_ver in "${TARGET_IOS_VERSIONS[@]}"; do
    local target_major="${target_ver%%.*}"
    if runtime_id_for_version "$target_ver" >/dev/null 2>&1; then
      echo -e "  iOS $target_major: ${GREEN}installed${RESET}"
    else
      echo -e "  iOS $target_major: ${YELLOW}downloading...${RESET}"
      echo "  Running: xcodebuild -downloadPlatform iOS"
      echo "  (This may take a while — each runtime is ~6-8 GB)"
      xcodebuild -downloadPlatform iOS 2>&1 || {
        echo -e "  ${RED}Failed to download iOS $target_major runtime.${RESET}"
        echo "  You may need to download it manually via Xcode > Settings > Platforms."
      }
    fi
  done
}

cmd_test() {
  local mode="$1"
  SKIPPED_COMBOS=()

  echo -e "${BOLD}PitchDreams Multi-Device Test Runner${RESET}"
  echo -e "Mode: ${CYAN}$mode${RESET}"
  echo ""

  # Ensure project is generated
  if [[ ! -d "$PROJECT" ]]; then
    echo -e "${CYAN}Generating Xcode project...${RESET}"
    (cd "$PROJECT_DIR" && xcodegen generate 2>/dev/null)
  fi

  build_test_matrix "$mode"

  if [[ ${#TEST_COMBOS[@]} -eq 0 ]]; then
    echo -e "${RED}No valid device/iOS combinations found.${RESET}"
    echo "Run with --list to see the matrix, or --install-runtimes to download missing runtimes."
    exit 1
  fi

  echo -e "Testing ${GREEN}${#TEST_COMBOS[@]}${RESET} device/iOS combinations:"
  for combo in "${TEST_COMBOS[@]}"; do
    local name ios_ver
    name=$(get_field "$combo" 1)
    ios_ver=$(get_field "$combo" 4)
    echo -e "  - $name (iOS $ios_ver)"
  done
  echo ""

  # Create results directory
  mkdir -p "$RESULTS_DIR"

  # Phase 1: Create/find simulators
  echo -e "${CYAN}Setting up simulators...${RESET}"
  declare -a SIM_UDIDS=()
  declare -a SIM_NAMES_LIST=()
  declare -a SIM_DISPLAY=()
  declare -a SIM_IOS=()

  for combo in "${TEST_COMBOS[@]}"; do
    local name device_type ios_ver runtime_id sname udid
    name=$(get_field "$combo" 1)
    device_type=$(get_field "$combo" 2)
    ios_ver=$(get_field "$combo" 4)
    runtime_id=$(get_field "$combo" 5)
    sname=$(sim_name "$name" "$ios_ver")

    udid=$(sim_exists "$sname" 2>/dev/null) || true
    if [[ -z "$udid" ]]; then
      echo "  Creating $sname..."
      udid=$(create_sim "$sname" "$device_type" "$runtime_id")
    else
      echo "  Found $sname ($udid)"
    fi

    SIM_UDIDS+=("$udid")
    SIM_NAMES_LIST+=("$sname")
    SIM_DISPLAY+=("$name")
    SIM_IOS+=("$ios_ver")
  done
  echo ""

  # Phase 2: Boot simulators
  echo -e "${CYAN}Booting simulators...${RESET}"
  for udid in "${SIM_UDIDS[@]}"; do
    boot_sim "$udid"
  done
  echo "  All simulators booted."
  echo ""

  # Phase 3: Build for testing once (shared across all devices)
  echo -e "${CYAN}Building test bundle (one-time)...${RESET}"
  local first_udid="${SIM_UDIDS[0]}"
  xcodebuild build-for-testing \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$first_udid" \
    -configuration Debug \
    CODE_SIGNING_ALLOWED=NO \
    -quiet 2>&1 || {
      echo -e "${RED}Build failed! Check the project for compile errors.${RESET}"
      exit 1
    }
  echo "  Build complete."
  echo ""

  # Phase 4: Run tests on each device
  echo -e "${CYAN}Running tests...${RESET}"
  local total_pass=0 total_fail=0 total_devices=0 failed_devices=0
  declare -a RESULTS=()

  for i in "${!SIM_UDIDS[@]}"; do
    local udid="${SIM_UDIDS[$i]}"
    local display="${SIM_DISPLAY[$i]}"
    local ios_ver="${SIM_IOS[$i]}"
    local result_path="$RESULTS_DIR/result-$i.xcresult"

    echo -e "  Testing on ${BOLD}$display${RESET} (iOS $ios_ver)..."

    # Remove old result bundle if exists
    rm -rf "$result_path"

    local test_exit=0
    local log_file="$RESULTS_DIR/log-$i.txt"
    set +e
    xcodebuild test-without-building \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -destination "platform=iOS Simulator,id=$udid" \
      -configuration Debug \
      -skip-testing:PitchDreamsTests/APIContractTests \
      -skip-testing:PitchDreamsTests/EndToEndFlowTests \
      -resultBundlePath "$result_path" \
      CODE_SIGNING_ALLOWED=NO \
      2>&1 | tee "$log_file" | grep -E "Executed|TEST SUCCEEDED|TEST FAILED" | tail -3
    test_exit=${PIPESTATUS[0]}
    set -e

    local counts tests passed failed status
    counts=$(parse_xcresult "$result_path" "$log_file")
    tests=$(echo "$counts" | cut -d'|' -f1)
    passed=$(echo "$counts" | cut -d'|' -f2)
    failed=$(echo "$counts" | cut -d'|' -f3)

    if [[ "$test_exit" -ne 0 ]] || [[ "$failed" -gt 0 ]]; then
      status="${RED}FAIL${RESET}"
      ((failed_devices++))
    else
      status="${GREEN}PASS${RESET}"
    fi

    total_pass=$((total_pass + passed))
    total_fail=$((total_fail + failed))
    ((total_devices++))

    RESULTS+=("$display|$ios_ver|$tests|$passed|$failed|$status")
  done
  echo ""

  # Phase 5: Shutdown simulators
  echo -e "${CYAN}Shutting down simulators...${RESET}"
  for udid in "${SIM_UDIDS[@]}"; do
    shutdown_sim "$udid"
  done

  # Phase 6: Print summary
  echo ""
  echo -e "${BOLD}═══════════════════════════════════════════════════════════════════${RESET}"
  echo -e "${BOLD}                    TEST RESULTS SUMMARY${RESET}"
  echo -e "${BOLD}═══════════════════════════════════════════════════════════════════${RESET}"
  echo ""
  printf "${BOLD}%-25s %-8s %-8s %-8s %-8s %-10s${RESET}\n" "Device" "iOS" "Tests" "Pass" "Fail" "Status"
  echo "───────────────────────────────────────────────────────────────────"

  for result in "${RESULTS[@]}"; do
    local r_name r_ios r_tests r_pass r_fail r_status
    r_name=$(echo "$result" | cut -d'|' -f1)
    r_ios=$(echo "$result" | cut -d'|' -f2)
    r_tests=$(echo "$result" | cut -d'|' -f3)
    r_pass=$(echo "$result" | cut -d'|' -f4)
    r_fail=$(echo "$result" | cut -d'|' -f5)
    r_status=$(echo "$result" | cut -d'|' -f6)
    printf "%-25s %-8s %-8s %-8s %-8s %b\n" "$r_name" "$r_ios" "$r_tests" "$r_pass" "$r_fail" "$r_status"
  done

  echo "───────────────────────────────────────────────────────────────────"
  printf "${BOLD}%-25s %-8s %-8s %-8s %-8s${RESET}\n" "TOTAL" "" "" "$total_pass" "$total_fail"
  echo ""

  if [[ ${#SKIPPED_COMBOS[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Skipped (runtime not installed):${RESET}"
    for skip in "${SKIPPED_COMBOS[@]}"; do
      echo "  - $skip"
    done
    echo ""
  fi

  if [[ "$failed_devices" -gt 0 ]]; then
    echo -e "${RED}${BOLD}$failed_devices device(s) had test failures.${RESET}"
    echo -e "Results saved to: $RESULTS_DIR"
    exit $(( failed_devices > 125 ? 125 : failed_devices ))
  else
    echo -e "${GREEN}${BOLD}All $total_devices device(s) passed!${RESET}"
    rm -rf "$RESULTS_DIR"
    exit 0
  fi
}

# ─── Main ────────────────────────────────────────────────────────────────────

# Cache installed runtimes
INSTALLED_RUNTIMES=$(get_installed_runtimes)

MODE="quick"
DO_INSTALL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quick) MODE="quick"; shift ;;
    --full) MODE="full"; shift ;;
    --list) cmd_list; exit 0 ;;
    --cleanup) cmd_cleanup; exit 0 ;;
    --install-runtimes) DO_INSTALL=true; shift ;;
    -h|--help)
      echo "Usage: $0 [--quick|--full] [--install-runtimes] [--list] [--cleanup]"
      echo ""
      echo "Options:"
      echo "  --quick             Test 5 representative devices on installed runtimes (default)"
      echo "  --full              Test all valid device/iOS combos"
      echo "  --list              Show the device/iOS matrix and exit"
      echo "  --cleanup           Remove all PD-Test-* simulators"
      echo "  --install-runtimes  Download missing iOS runtimes before testing"
      echo "  -h, --help          Show this help"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ "$DO_INSTALL" == "true" ]]; then
  cmd_install_runtimes
  # Refresh runtimes cache
  INSTALLED_RUNTIMES=$(get_installed_runtimes)
fi

cmd_test "$MODE"
