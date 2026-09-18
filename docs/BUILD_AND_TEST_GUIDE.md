# iTrac Sekolah - Build & Test Guide

**Date:** 2026-09-18  
**Purpose:** Complete instructions for building release APK and testing all features

---

## Prerequisites Check

Before building, verify your environment:

```powershell
# Check Flutter installation
flutter --version
# Should show: Flutter X.X.X, Dart X.X.X

# Check Java installation
java -version
# Should show Java 17+

# Check Android SDK
flutter doctor
# All items should have ✓ (green check)
```

**If any prerequisites are missing, install them:**

### Install Flutter

```powershell
# Download Flutter SDK from https://flutter.dev/docs/get-started/install/windows

# Extract to preferred location (e.g., C:\flutter)
# Then add to PATH:
# 1. Right-click "This PC" > Properties
# 2. Click "Advanced system settings"
# 3. Click "Environment Variables"
# 4. Under "System variables", click "New"
# 5. Variable name: FLUTTER_HOME
# 6. Variable value: C:\flutter
# 7. Edit "Path" and add: %FLUTTER_HOME%\bin

# Verify installation
flutter --version
```

### Install Java 17

```powershell
# Download from https://www.oracle.com/java/technologies/downloads/

# Set JAVA_HOME environment variable:
# JAVA_HOME = C:\Program Files\Java\jdk-17.0.X
```

### Setup Android SDK

```powershell
# Flutter will guide you through Android SDK setup
flutter doctor --android-licenses
# Accept all licenses by typing 'y'
```

---

## Step 1: Build Release APK

### From Project Directory

```powershell
cd F:\itracscholl\android_app
flutter clean
flutter pub get
flutter build apk --release
```

### Expected Output

```
✓ Built build/app/outputs/apk/release/app-release.apk (123.5 MB)
```

### Build Time

- **First build:** 20-30 minutes (dependencies download)
- **Subsequent builds:** 10-15 minutes (cached)

### Troubleshooting Build Failures

**"method not found" error:**
```powershell
flutter clean
rm pubspec.lock
flutter pub get
flutter build apk --release
```

**"Gradle sync failed":**
```powershell
cd F:\itracscholl\android_app\android
gradlew clean
cd ..
flutter build apk --release
```

**"Android SDK not found":**
```powershell
flutter doctor -v
# Follow instructions in output
```

---

## Step 2: Verify APK was Created

```powershell
ls "F:\itracscholl\android_app\build\app\outputs\apk\release\"
# Should show: app-release.apk
```

### APK Properties

| Property | Value |
|----------|-------|
| Filename | app-release.apk |
| Location | `android_app/build/app/outputs/apk/release/` |
| Size | ~120 MB |
| Signature | Release keystore (production-signed) |

---

## Step 3: Install on Device/Emulator

### Device (Physical Phone)

```powershell
# Connect phone via USB cable
# Enable Developer Mode on phone (tap Build Number 7 times in Settings)
# Enable USB Debugging

# Verify device connection
adb devices
# Should show your device serial

# Install APK
adb install -r "F:\itracscholl\android_app\build\app\outputs\apk\release\app-release.apk"

# Wait for "Success"
```

### Emulator

```powershell
# Start emulator first
# (via Android Studio or command line)

# Install APK
adb install -r "F:\itracscholl\android_app\build\app\outputs\apk\release\app-release.apk"
```

### Verify Installation

```powershell
adb shell pm list packages | grep itracscholl
# Should show: package:id.co.sekolahapp.itracscholl
```

---

## Step 4: Run Automated Tests

### Prerequisites

- Device/emulator must be connected and app installed
- Android Debug Bridge (ADB) must be available
- Bash shell (Git Bash or WSL on Windows)

### Execute Test Script

```bash
cd F:\itracscholl
bash scripts/test_app.sh
```

### What Gets Tested

**Phase 1: Foundation**
- ✅ App launches without crashes
- ✅ Error handling works
- ✅ Download history accessible
- ✅ Session management active

**Phase 2: UX & Performance**
- ✅ Theme toggle (Dark/Light)
- ✅ Cache manager initialized
- ✅ Connectivity detection works
- ✅ Offline banner appears

**Phase 3: Security & Notifications**
- ✅ Biometric auth available
- ✅ Notifications badge shows
- ✅ Session timeout works
- ✅ Push notifications tracked

**Phase 4: Analytics & Communication**
- ✅ Analytics events recorded
- ✅ Announcements display
- ✅ No fatal errors in logs
- ✅ Memory usage normal

### Test Output

Script generates:
- **Console output** - Color-coded results (green ✅, red ❌, yellow ⚠️)
- **Report file** - `test_report_YYYYMMDD_HHMMSS.md` with detailed results

---

## Step 5: Manual Testing (Recommended)

Use the test report template for comprehensive manual testing:

```powershell
# Open the template
notepad F:\itracscholl\docs\TEST_REPORT_TEMPLATE.md

# Fill in results as you test each feature
```

### Quick Manual Test Checklist

1. **Launch App** - Tap icon, app opens in ~3 seconds
2. **Menu Button** - Tap menu (⋮), see 10+ options
3. **Download History** - Menu > Download History, see list
4. **Theme Toggle** - Menu > Theme > Dark, verify colors change
5. **Cache Stats** - Menu > Cache Stats, see number of cached pages
6. **Offline Mode** - Turn off WiFi, verify orange banner appears
7. **Biometric** - Menu > Biometric, toggle enable
8. **Notifications** - Menu > Notifications, see notification list
9. **Analytics** - Menu > Analytics, see event dashboard
10. **Announcements** - Menu > Announcements, see school messages

---

## Step 6: Performance Verification

### Measure Startup Time

```powershell
adb logcat -c
adb shell am start -n id.co.sekolahapp.itracscholl/.MainActivity
# Note time until UI appears (should be <5 seconds)
```

### Check Memory Usage

```powershell
adb shell dumpsys meminfo id.co.sekolahapp.itracscholl
# Look for "TOTAL" line - should be <200 MB
```

### Monitor Battery Impact

After 1 hour of normal use:
- Battery drain should be <5%
- App should not get killed by system
- Notifications should still work

---

## Step 7: CI/CD Verification (Alternative)

If building locally is not feasible:

1. **Push to Main:**
   ```bash
   git add .
   git commit -m "Release build"
   git push origin main
   ```

2. **GitHub Actions Will:**
   - Build APK automatically
   - Run tests (if configured)
   - Store APK as artifact (90 days)

3. **Download from GitHub:**
   - Go to https://github.com/[OWNER]/itracscholl/actions
   - Click latest successful workflow
   - Scroll to "Artifacts"
   - Download app-itracscholl-release.apk

---

## Testing Scenarios

### Scenario 1: Happy Path
1. Launch app → No crashes
2. Navigate pages → Data loads
3. Click menu items → Dialogs appear
4. Close app → Session persists
5. Reopen → Restores state

**Expected:** All steps succeed, app responsive

### Scenario 2: Offline Mode
1. Launch app, load pages (online)
2. Turn off WiFi/mobile
3. Verify orange banner appears
4. Navigate to cached page
5. Content displays from cache
6. Turn WiFi back on → banner disappears

**Expected:** Offline content loads, banner toggles correctly

### Scenario 3: Session Timeout
1. Launch app
2. Leave idle for 10 minutes
3. Verify warning dialog appears
4. Click "Continue" → session extends
5. Or wait 5 more minutes → auto logout

**Expected:** Warning appears, logout works after timeout

### Scenario 4: Biometric Authentication
1. Menu > Biometric
2. Enable biometric
3. Attempt authentication
4. Provide fingerprint/face
5. Verify success/failure message

**Expected:** Auth dialog appears, biometric prompt works (if device supports)

### Scenario 5: Notifications
1. Menu > Notifications
2. Verify badge shows unread count
3. Tap notification → mark as read
4. Badge updates
5. Delete notification

**Expected:** Badge toggles, delete works, list updates

---

## Debugging Failed Tests

### If Automated Tests Fail

1. **Check Logcat:**
   ```powershell
   adb logcat | grep -i error
   ```

2. **Check App Crash:**
   ```powershell
   adb logcat | grep -i "FATAL\|CRASH"
   ```

3. **Verify Device State:**
   ```powershell
   adb shell getprop ro.build.version.release  # Android version
   adb shell getprop ro.product.model          # Device model
   ```

4. **Reinstall App:**
   ```powershell
   adb uninstall id.co.sekolahapp.itracscholl
   adb install -r app-release.apk
   ```

### If Specific Feature Fails

**Theme not toggling:**
- Clear app cache: `adb shell pm clear id.co.sekolahapp.itracscholl`
- Reinstall and test again

**Offline mode not detecting:**
- Verify phone actually loses connectivity
- Check with: `adb shell ping 8.8.8.8`

**Biometric not prompting:**
- Device may not support biometric
- Check with: `adb shell pm list features | grep biometric`

**Notifications not appearing:**
- Verify Firebase is configured
- Check Google Play Services installed: `adb shell pm list packages | grep gms`

---

## Sign-Off Checklist

Before considering build complete:

- [ ] APK built successfully (no errors)
- [ ] App installs on device (adb install succeeds)
- [ ] App launches (opens within 5 seconds)
- [ ] No crashes on startup
- [ ] Automated tests pass (or document failures)
- [ ] Manual tests completed (use test report template)
- [ ] All 4 phases verified working:
  - [ ] Phase 1: Foundation (error handling, sessions, downloads)
  - [ ] Phase 2: UX (theme, cache, offline)
  - [ ] Phase 3: Security (biometric, notifications)
  - [ ] Phase 4: Analytics (events, announcements)
- [ ] Performance acceptable (startup <5s, memory <200MB)
- [ ] Test report documented

---

## Next Steps

### If All Tests Pass ✅
1. Generate final test report
2. Commit test results to git
3. Create GitHub Release
4. Submit to Play Store (manual process)

### If Tests Fail ❌
1. Document failure details
2. Check CI/CD logs for specifics
3. Fix issues in code
4. Rebuild and retest
5. Repeat until all tests pass

---

## Commands Reference

```powershell
# Build
flutter build apk --release

# Install
adb install -r build/app/outputs/apk/release/app-release.apk

# Test
bash scripts/test_app.sh

# View Logs
adb logcat -d | grep -i "error\|fatal"

# Check Device
adb devices

# Uninstall
adb uninstall id.co.sekolahapp.itracscholl

# Clear Cache
adb shell pm clear id.co.sekolahapp.itracscholl
```

---

**Status:** Ready for Build & Test  
**Last Updated:** 2026-09-18  
**Maintained By:** [YOUR NAME]
