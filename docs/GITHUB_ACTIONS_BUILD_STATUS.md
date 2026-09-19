# GitHub Actions Build Status - iTrac Sekolah

**Build Triggered:** 2026-09-18  
**Commit:** 7ad4da8  
**Workflow:** Build Android (Multi-School)  
**Repository:** https://github.com/adicitycom/itracscholl

---

## 📊 Real-Time Monitoring

### View Build Status

**Option 1: Direct URL**
```
https://github.com/adicitycom/itracscholl/actions
```

**Option 2: GitHub CLI**
```bash
gh run list --repo adicitycom/itracscholl --workflow build-android-multi.yml
```

**Option 3: Latest Run**
```bash
gh run view --repo adicitycom/itracscholl
```

---

## 🔄 Build Progress

### Expected Timeline

| Phase | Duration | Status |
|-------|----------|--------|
| Setup (checkout, Java, Flutter) | ~2 min | ⏳ |
| Dependencies resolution | ~8 min | ⏳ |
| Icon generation | ~2 min | ⏳ |
| Google Services config | ~1 min | ⏳ |
| Build debug APK | ~5 min | ⏳ |
| Build release APK | ~5 min | ⏳ |
| Build AAB (Play Store) | ~5 min | ⏳ |
| Upload artifacts | ~1 min | ⏳ |
| **Total** | **~30 minutes** | ⏳ |

---

## ✅ What to Expect

### Successful Build Status
```
✅ Checkout code
✅ Setup Java
✅ Setup Flutter
✅ Install ImageMagick
✅ Generate icon
✅ Setup Google Services JSON
✅ Setup keystore
✅ Get dependencies
✅ Build APK (release)
✅ Build AAB (release)
✅ Upload artifacts
```

### Available Artifacts After Success

| Artifact | Size | Purpose |
|----------|------|---------|
| `apk-itracscholl` | ~120 MB | Release APK for testing |
| `aab-itracscholl` | ~90 MB | Android App Bundle for Play Store |

---

## 📥 Download Built APK

### After Build Completes (green ✅)

1. **Go to Actions Tab**
   ```
   https://github.com/adicitycom/itracscholl/actions
   ```

2. **Click Latest Workflow Run**
   - Look for: "Phase 4 Complete: Add test automation..."
   - Status: ✅ All jobs passed

3. **Scroll to "Artifacts" Section**
   - Find: `apk-itracscholl`
   - Click download icon

4. **Extract and Install**
   ```powershell
   # Extract ZIP
   Expand-Archive -Path apk-itracscholl.zip -DestinationPath .
   
   # Install on device/emulator
   adb install -r app-itracscholl-release.apk
   ```

---

## 🐛 If Build Fails

### Common Failure Points

**1. Keystore Decryption Failed**
```
Error: Permission denied
Reason: ANDROID_KEYSTORE_BASE64 secret not set
```
**Fix:** Add GitHub secret in Settings > Secrets

**2. Google Services JSON Failed**
```
Error: Invalid password
Reason: SECRETS_PASSPHRASE secret incorrect
```
**Fix:** Verify passphrase matches encryption

**3. Flutter Build Failed**
```
Error: Gradle sync failed
Reason: Dependency version conflict
```
**Fix:** 
- Update pubspec.yaml locally
- Test build locally first
- Commit and re-push

**4. Artifact Upload Failed**
```
Error: File not found
Reason: Build path mismatch
```
**Fix:** Verify paths in workflow match actual outputs

### Debug Failed Build

1. **Click Failed Job** in workflow run
2. **Expand Failed Step** (red ❌)
3. **Read Error Message** - exact error shown
4. **Fix Locally:**
   ```bash
   cd android_app
   flutter clean
   flutter pub get
   flutter build apk --release
   ```
5. **Commit Fix** and push to re-trigger

---

## 🔐 Required Secrets (Already Configured)

### GitHub Secrets Used

| Secret | Purpose | Status |
|--------|---------|--------|
| `SECRETS_PASSPHRASE` | Decrypt google-services.json | ✅ Set |
| `ANDROID_KEYSTORE_BASE64` | Release signing key | ✅ Set |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password | ✅ Set |
| `ANDROID_KEY_PASSWORD` | Key password | ✅ Set |
| `ANDROID_KEY_ALIAS` | Key alias | ✅ Set |

**Location:** Settings > Secrets and variables > Actions

---

## 📋 Build Configuration

### Multi-School Support

The workflow automatically builds for **all schools** defined in:
```
android_app/schools/schools.json
```

**Current Build Matrix:**
- School ID: `itracscholl` (from schools.json)
- Output: `app-itracscholl-release.apk`

**To Add New School:**
1. Add entry to `schools/schools.json`
2. Add `schools/{SCHOOL_ID}/google-services.json.enc` (encrypted)
3. Push to main → workflow auto-includes in matrix

---

## 🚀 Deployment Path

### From GitHub Actions to Play Store

**Step 1: Build (Automatic)**
✅ GitHub Actions builds APK & AAB

**Step 2: Download Artifact**
✅ Download AAB from artifacts

**Step 3: Test (Manual)**
```bash
# Install APK on device
adb install app-itracscholl-release.apk

# Run test script
bash scripts/test_app.sh

# Or manual testing with template
# docs/TEST_REPORT_TEMPLATE.md
```

**Step 4: Upload to Play Store (Manual)**
- Go to Google Play Console
- Create new release
- Upload AAB
- Fill release notes
- Set rollout percentage
- Submit for review

---

## 📈 Workflow Optimization

### Caching Strategy (Currently Disabled)

To speed up builds, consider enabling cache:

```yaml
# Add to .github/workflows/build-android-multi.yml after checkout

- uses: actions/cache@v3
  with:
    path: |
      ~/.gradle/caches
      ~/.gradle/wrapper
    key: gradle-${{ hashFiles('**/build.gradle') }}
    restore-keys: |
      gradle-
```

**Benefits:**
- Gradle cache: 30-50% faster
- Flutter cache: 20-30% faster
- Total impact: ~10 minutes saved

---

## 🔔 Notifications

### Get Notified on Build Status

**Option 1: GitHub Email**
- Go to Notifications settings
- Enable "Actions" notifications

**Option 2: GitHub CLI Watch**
```bash
gh run list --repo adicitycom/itracscholl --watch
```

**Option 3: Slack Integration (Optional)**
Add webhook to workflow:
```yaml
- name: Notify Slack on Success
  if: success()
  run: |
    curl -X POST ${{ secrets.SLACK_WEBHOOK }} \
      -d '{"text":"✅ Build succeeded: ${{ github.run_id }}"}'
```

---

## ✨ Quick Reference Commands

```bash
# View all recent runs
gh run list --repo adicitycom/itracscholl

# View specific workflow
gh run list --repo adicitycom/itracscholl --workflow build-android-multi.yml

# View latest run logs
gh run view --repo adicitycom/itracscholl --log

# Cancel a run
gh run cancel [RUN_ID] --repo adicitycom/itracscholl

# Re-run failed jobs
gh run rerun [RUN_ID] --repo adicitycom/itracscholl

# Download artifact
gh run download [RUN_ID] --repo adicitycom/itracscholl -n apk-itracscholl
```

---

## 📞 Support

**Issues?**
- Check GitHub Status: https://www.githubstatus.com
- Review workflow logs for specific error
- Verify all secrets are set correctly
- Contact: [support email]

**Workflow Documentation:**
- GitHub Actions Docs: https://docs.github.com/en/actions
- Flutter CI Guide: https://flutter.dev/docs/deployment/cd
- Android Build Guide: https://developer.android.com/build

---

**Status:** Build In Progress ⏳  
**Last Updated:** 2026-09-18  
**Next Update:** When build completes
