# CI/CD Monitoring Guide - iTrac Sekolah

**Version:** 1.0  
**Last Updated:** 2026-09-18  
**Purpose:** Monitor GitHub Actions builds and deployments for the iTrac Sekolah Flutter app

---

## Quick Start

1. **Access Workflows:** https://github.com/[OWNER]/itracscholl/actions
2. **Monitor Builds:** Watch for red ❌ or green ✅ status
3. **View Logs:** Click on failed workflow to debug
4. **Re-run Failed Builds:** Click "Re-run all jobs" on workflow detail page

---

## Workflow Overview

### Build Workflow: `build-android-multi.yml`

**Triggered By:**
- Push to `main` branch
- Manual trigger via "Run workflow"
- Pull requests (optional)

**Jobs in Order:**
1. **Setup** - Validates environment and dependencies
2. **Build Debug** - Compiles debug APK
3. **Build Release** - Compiles optimized release APK
4. **Upload Artifacts** - Stores APKs for download
5. **Notify** - Sends build status (if configured)

**Execution Time:** ~15-25 minutes (first run may be longer due to dependencies)

**Output Artifacts:**
- `app-itracscholl-debug.apk` - Unoptimized debug build
- `app-itracscholl-release.apk` - Production-ready release build

---

## Monitoring Dashboard

### View Active Workflows

```bash
# Via GitHub CLI
gh run list --repo [OWNER]/itracscholl

# Via Web
https://github.com/[OWNER]/itracscholl/actions
```

### Status Indicators

| Status | Icon | Meaning | Action |
|--------|------|---------|--------|
| In Progress | 🟡 | Build running | Wait for completion |
| Success | ✅ | Build passed all jobs | Download artifacts |
| Failed | ❌ | Build failed at some step | Review logs, fix issue |
| Canceled | ⏹️ | User stopped build | Re-run if accidental |

---

## Common Build Failures & Solutions

### 1. Dependency Resolution Failed

**Error Message:**
```
Gradle sync failed, Unable to find a version that satisfies the constraints
```

**Cause:** Dependency conflict or network issue

**Solution:**
```bash
# In local environment:
cd android_app
flutter clean
flutter pub get
flutter pub upgrade

# Then commit and push to trigger new build
```

### 2. Dart Analysis Failure

**Error Message:**
```
Target of URI doesn't exist: 'package:flutter/material.dart'
```

**Cause:** SDK not properly configured

**Solution:**
```bash
# Locally verify Flutter installation
flutter doctor

# If issues found, run recommended fixes
# Then push fix to main
```

### 3. Build APK Failed

**Error Message:**
```
ERROR: Failed to package the application
```

**Cause:** Dart/Java compilation error

**Solution:**
1. Pull latest code locally
2. Run: `flutter build apk --release`
3. Fix errors shown in output
4. Commit and push

### 4. Android SDK Version Mismatch

**Error Message:**
```
Gradle error: compileSdkVersion 35 not found
```

**Cause:** SDK not installed in CI environment

**Solution:** Already fixed in build.gradle (compileSdk 35)  
If persists, check:
```yaml
# In .github/workflows/build-android-multi.yml
- name: Setup Android SDK
  uses: android-actions/setup-android@v2
  with:
    api-levels: 35  # Matches compileSdk
```

### 5. Flutter Version Incompatibility

**Error Message:**
```
The Dart language version must be 3.7
```

**Cause:** Dart version mismatch

**Solution:** Already handled in workflow (Flutter 3.29.0 includes Dart 3.7+)  
Verify locally:
```bash
flutter --version  # Should show 3.29.0+
```

---

## Monitoring Tasks

### Daily Checks (5 min)

- [ ] Check Actions tab for any red ❌ builds
- [ ] If failed, read error message in build logs
- [ ] Note timestamp of failure

### Weekly Review (15 min)

- [ ] Review last 5 workflow runs
- [ ] Check average build time (should be ~20 min)
- [ ] Verify all output artifacts are present
- [ ] Check for any warnings in logs

### Monthly Analysis (30 min)

- [ ] Analyze build failure patterns
- [ ] Check dependency updates available
- [ ] Review resource usage (build time, storage)
- [ ] Update documentation if procedures changed

---

## Build Performance Optimization

### Current Build Time: ~20 minutes

**Breakdown:**
- Setup & checkout: ~2 min
- Dependency resolution: ~8 min
- Build debug: ~5 min
- Build release: ~5 min

### How to Reduce Build Time

#### Strategy 1: Gradle Build Cache
```yaml
# Already enabled in build.gradle
android {
    buildTypes {
        release {
            minifyEnabled true  # Enables ProGuard
        }
    }
}
```

#### Strategy 2: Parallel Builds
Already configured - debug and release build in parallel.

#### Strategy 3: Cache Dependencies
```yaml
# Add to workflow (if not present)
- uses: actions/cache@v3
  with:
    path: ~/.gradle/caches
    key: gradle-${{ hashFiles('**/build.gradle') }}
```

---

## Artifact Management

### Download APK from Actions

1. Go to https://github.com/[OWNER]/itracscholl/actions
2. Click on the workflow run (green ✅ status)
3. Scroll down to "Artifacts" section
4. Click "app-itracscholl-release.apk" to download

### Retention Policy

- **Default:** Artifacts kept for 90 days
- **Size Limit:** ~100 MB per artifact
- **Storage:** GitHub free tier allows 500 MB

### Clean Up Old Artifacts

```bash
# Via GitHub CLI
gh run delete [RUN_ID] --repo [OWNER]/itracscholl
```

---

## Deployment Process

### Manual Deployment via Artifacts

1. **Build on Main:**
   ```bash
   git push origin main
   # Wait for workflow to complete
   ```

2. **Download Release APK:**
   - Go to Actions > Latest Run > Artifacts
   - Download `app-itracscholl-release.apk`

3. **Test on Device:**
   ```bash
   adb install -r app-itracscholl-release.apk
   # Run test suite from docs/TEST_REPORT_TEMPLATE.md
   ```

4. **Deploy to Play Store (Manual):**
   - Upload APK to Google Play Console
   - Fill in release notes
   - Set rollout percentage
   - Submit for review

---

## Troubleshooting Workflow

### Step 1: Identify Failure Point

Look for the ❌ in workflow visualization:

```
✅ Checkout Code
✅ Setup Flutter
❌ Build Release  ← Failed here
⏭️ Upload Artifacts (skipped)
```

### Step 2: Review Error Logs

Click the failed job (e.g., "Build Release") and scroll to error message:

```
Error: [Detailed error message and stack trace]
```

### Step 3: Reproduce Locally

Run the same command locally:

```bash
flutter build apk --release
```

### Step 4: Fix and Test

1. Fix the issue in code
2. Test locally: `flutter build apk --release`
3. Commit and push to trigger CI
4. Wait for green ✅ status

### Step 5: Manual Re-run (if needed)

If transient failure (network timeout, etc.):

1. Go to Actions > Failed workflow
2. Click "Re-run all jobs"
3. Wait for result

---

## Monitoring Metrics

### Track These Metrics Weekly

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Build Success Rate | 95%+ | [ ] | [ ] ✅ [ ] ⚠️ |
| Avg Build Time | <25 min | [ ] min | [ ] ✅ [ ] ⚠️ |
| Failed Test Count | 0 | [ ] | [ ] ✅ [ ] ⚠️ |
| Coverage | >80% | [ ]% | [ ] ✅ [ ] ⚠️ |

### Record Monthly

```markdown
**September 2026**
- Success Rate: 100% (5/5 builds passed)
- Avg Build Time: 22 minutes
- Issues: None
- Performance: ✅ Excellent
```

---

## Alerting & Notifications

### Recommended Setup

#### Via Email
```yaml
# Add to workflow to notify on failure
- name: Notify Slack on Failure
  if: failure()
  run: |
    curl -X POST ${{ secrets.SLACK_WEBHOOK }} \
      -d '{"text":"Build failed: ${{ github.run_id }}"}'
```

#### Via Slack
1. Create Slack webhook in workspace
2. Add to GitHub secrets as `SLACK_WEBHOOK`
3. Use in workflow above

#### Via GitHub
- Watch repository (bell icon)
- Select "All Activity" or "Custom" 
- Enable "Actions" notifications

---

## Emergency Response

### If Build is Stuck

1. **Wait 30 seconds** - CI may be catching up
2. **Check Status:** https://www.githubstatus.com
3. **Cancel Run:**
   ```bash
   gh run cancel [RUN_ID] --repo [OWNER]/itracscholl
   ```
4. **Push Again:** Trigger new workflow
   ```bash
   git commit --allow-empty -m "Retry build"
   git push
   ```

### If Build Never Completes (>1 hour)

1. **Cancel immediately:**
   ```bash
   gh run cancel [RUN_ID]
   ```

2. **Check Workflow File:**
   - Look for infinite loops
   - Check for blocking I/O
   - Verify timeout values

3. **Contact GitHub Support** if persists

---

## Maintenance Tasks

### Monthly Maintenance Checklist

- [ ] Review workflow file for deprecations
- [ ] Update Flutter version if needed
- [ ] Clean up old artifacts
- [ ] Test artifact download process
- [ ] Verify APK signature process
- [ ] Check for new security updates

### Update Flutter Version

1. **Update workflow file:**
   ```yaml
   # In .github/workflows/build-android-multi.yml
   - uses: subosito/flutter-action@v2
     with:
       flutter-version: '3.30.0'  # New version
   ```

2. **Test locally first:**
   ```bash
   flutter upgrade
   flutter build apk --release
   ```

3. **Commit and push** to trigger new workflow

---

## References

- **GitHub Actions Docs:** https://docs.github.com/en/actions
- **Flutter CI/CD Guide:** https://flutter.dev/docs/deployment/cd
- **Android Build Guide:** https://developer.android.com/build

---

## Support

**Report Issues:**
- GitHub Issues: https://github.com/[OWNER]/itracscholl/issues
- Check existing issues before creating

**Common Searches:**
- "flutter build failed"
- "gradle sync failed"
- "android sdk not found"

---

**Last Reviewed:** [DATE]  
**Next Review:** [DATE + 1 MONTH]  
**Reviewer Name:** [YOUR NAME]
