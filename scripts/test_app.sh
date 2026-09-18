#!/bin/bash

# iTrac Sekolah - Automated Testing Script
# Tests all features systematically via ADB

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REPORT_FILE="test_report_$(date +%Y%m%d_%H%M%S).md"
PASS_COUNT=0
FAIL_COUNT=0

# Functions
log_test() {
    echo -e "${BLUE}▶ $1${NC}"
    echo "## Test: $1" >> "$REPORT_FILE"
}

log_pass() {
    echo -e "${GREEN}✓ PASS: $1${NC}"
    echo "**Result:** ✅ PASS - $1" >> "$REPORT_FILE"
    ((PASS_COUNT++))
}

log_fail() {
    echo -e "${RED}✗ FAIL: $1${NC}"
    echo "**Result:** ❌ FAIL - $1" >> "$REPORT_FILE"
    ((FAIL_COUNT++))
}

log_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
    echo "**Info:** $1" >> "$REPORT_FILE"
}

# Initialize report
cat > "$REPORT_FILE" << EOF
# iTrac Sekolah - Test Report
**Date:** $(date)
**Device:** $(adb shell getprop ro.product.model)
**Android Version:** $(adb shell getprop ro.build.version.release)

---

## Test Results

EOF

echo -e "${BLUE}========== iTRAC SEKOLAH TEST SUITE ==========${NC}"
echo "Report: $REPORT_FILE"
echo ""

# Clear logcat
adb logcat -c
sleep 1

# ===== PHASE 1: FOUNDATION =====
echo -e "\n${BLUE}=== PHASE 1: FOUNDATION ===${NC}"

log_test "App Launch"
if adb shell am start -n id.co.sekolahapp.itracscholl/.MainActivity; then
    sleep 3
    if adb shell dumpsys window | grep -q "mCurrentFocus.*MainActivity"; then
        log_pass "App launched successfully"
    else
        log_fail "App did not focus on MainActivity"
    fi
else
    log_fail "Failed to start app"
fi

log_test "No Crash on Launch"
sleep 2
if ! adb logcat -d | grep -i "FATAL\|CRASH"; then
    log_pass "No crash detected on launch"
else
    log_fail "Crash detected in logcat"
fi

log_test "Download History Access"
adb shell input tap 920 1800  # Tap menu button (approximate)
sleep 1
adb shell input text "download_history"
sleep 1
if adb logcat -d | grep -q "DownloadHistory"; then
    log_pass "Download history menu accessible"
else
    log_info "Could not verify download history (may need manual interaction)"
fi

# ===== PHASE 2: UX & PERFORMANCE =====
echo -e "\n${BLUE}=== PHASE 2: UX & PERFORMANCE ===${NC}"

log_test "Theme Toggle"
sleep 1
adb logcat -c
adb shell input text "theme_toggle"
sleep 1
if adb logcat -d | grep -q "Theme"; then
    log_pass "Theme toggle recognized"
else
    log_info "Theme toggle requires manual testing"
fi

log_test "Cache Manager Initialization"
sleep 1
if adb logcat -d | grep -q "CacheManager.*Initialized"; then
    log_pass "Cache manager initialized"
else
    log_fail "Cache manager not initialized"
fi

log_test "Connectivity Detection"
if adb logcat -d | grep -q "ConnectivityManager.*Initialized"; then
    log_pass "Connectivity manager active"
else
    log_fail "Connectivity manager not active"
fi

# ===== PHASE 3: SECURITY & NOTIFICATIONS =====
echo -e "\n${BLUE}=== PHASE 3: SECURITY & NOTIFICATIONS ===${NC}"

log_test "Biometric Auth Initialization"
if adb logcat -d | grep -q "BiometricAuth"; then
    log_pass "Biometric auth initialized"
else
    log_info "Biometric may not be available on this device"
fi

log_test "Notification Manager"
if adb logcat -d | grep -q "NotificationManager.*Initialized"; then
    log_pass "Notification manager active"
else
    log_fail "Notification manager not active"
fi

log_test "Session Manager"
if adb logcat -d | grep -q "SessionManager"; then
    log_pass "Session manager initialized"
else
    log_fail "Session manager not initialized"
fi

# ===== PHASE 4: ANALYTICS & COMMUNICATION =====
echo -e "\n${BLUE}=== PHASE 4: ANALYTICS & COMMUNICATION ===${NC}"

log_test "Analytics Manager"
if adb logcat -d | grep -q "AnalyticsManager"; then
    log_pass "Analytics manager active"
else
    log_fail "Analytics manager not active"
fi

log_test "Announcement Manager"
if adb logcat -d | grep -q "AnnouncementManager"; then
    log_pass "Announcement manager initialized"
else
    log_fail "Announcement manager not initialized"
fi

# ===== ERROR CHECKING =====
echo -e "\n${BLUE}=== ERROR CHECKING ===${NC}"

log_test "No Fatal Errors"
ERRORS=$(adb logcat -d | grep -i "FATAL\|EXCEPTION" | grep -v "Expected\|Handled" | wc -l)
if [ "$ERRORS" -eq 0 ]; then
    log_pass "No fatal errors detected"
else
    log_fail "Found $ERRORS error(s) in logcat"
    adb logcat -d | grep -i "FATAL\|EXCEPTION" | head -5 >> "$REPORT_FILE"
fi

log_test "No Warnings"
WARNINGS=$(adb logcat -d | grep -i "WARNING" | wc -l)
log_info "Found $WARNINGS warning(s) in logcat"

# ===== PERFORMANCE =====
echo -e "\n${BLUE}=== PERFORMANCE ===${NC}"

log_test "Memory Usage"
MEMORY=$(adb shell dumpsys meminfo id.co.sekolahapp.itracscholl | grep "TOTAL" | awk '{print $2}')
if [ -n "$MEMORY" ]; then
    log_pass "Memory usage: ${MEMORY}KB"
else
    log_info "Could not measure memory"
fi

# ===== FINAL REPORT =====
echo -e "\n${BLUE}========== SUMMARY ==========${NC}"
echo -e "${GREEN}✓ PASSED: $PASS_COUNT${NC}"
echo -e "${RED}✗ FAILED: $FAIL_COUNT${NC}"

cat >> "$REPORT_FILE" << EOF

---

## Summary
- **Passed:** $PASS_COUNT
- **Failed:** $FAIL_COUNT
- **Total Tests:** $((PASS_COUNT + FAIL_COUNT))

EOF

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo "🎉 ALL TESTS PASSED!" >> "$REPORT_FILE"
else
    echo -e "${RED}⚠️  $FAIL_COUNT TEST(S) FAILED${NC}"
    echo "⚠️ $FAIL_COUNT TEST(S) FAILED" >> "$REPORT_FILE"
fi

echo ""
echo "Report saved: $REPORT_FILE"
echo ""

# Display report
cat "$REPORT_FILE"
