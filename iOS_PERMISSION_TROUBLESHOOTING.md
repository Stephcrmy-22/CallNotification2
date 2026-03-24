# iOS Microphone Permission Troubleshooting Guide

## Why Automatic Granting Isn't Possible

**iOS Security Policy**: Apple does not allow apps to automatically grant microphone permissions. This is a security feature to protect user privacy.

## What "Permanently Denied" Means

When you see "Permanently Denied" status, it means:
- User previously selected "Don't Allow" when the permission dialog appeared
- iOS has recorded this choice and won't show the dialog again for this app
- The only way to reset this is through iOS Settings or app reinstallation

## Solutions for iOS Permanently Denied

### Solution 1: Enable in Settings (Recommended)

**When Settings opens from app:**
1. **Scroll down** and tap **"Privacy & Security"**
2. **Tap "Microphone"** in the privacy settings
3. **Find "Agora Voice Call"** in the app list
4. **Toggle the switch ON** to enable microphone
5. **Return to app** and try accepting a call again

**Direct navigation:**
Settings → Privacy & Security → Microphone

### Solution 2: App Reinstallation (If not in list)

If the app doesn't appear in the microphone list:

1. **Delete the app** from your device (hold and tap "Remove App")
2. **Reinstall the app** (`flutter run` or from App Store)
3. **Try accepting a call** - permission dialog should appear again
4. **Select "OK"** when prompted

### Solution 3: Reset All Settings (Last Resort)

1. **iOS Settings** → `General` → `Transfer or Reset iPhone`
2. **Choose**: `Reset` → `Reset Location & Privacy`
3. **Reinstall app** and try again

## Why App Doesn't Appear in Microphone Settings

**Common Causes:**
- Permission was never properly requested by the app
- App was installed before microphone permission was configured in Info.plist
- User selected "Don't Allow" on first prompt

**Verification Steps:**
1. **Check Info.plist** has `NSMicrophoneUsageDescription`
2. **Clean build**: `flutter clean && flutter pub get`
3. **Fresh install**: Delete and reinstall app
4. **Test permission flow**: Accept call and grant when prompted

## Debug Information

The app logs permission status to console:
```
Current microphone permission status: PermissionStatus.denied
After request microphone permission status: PermissionStatus.permanentlyDenied
```

## Common iOS Issues

### Issue: App not in Microphone Settings
**Cause**: Permission was never requested or app was installed before permission was configured
**Fix**: Reinstall the app with fresh build

### Issue: Permission dialog doesn't appear
**Cause**: iOS remembers previous "Don't Allow" choice
**Fix**: Enable in Settings or reinstall app

### Issue: Settings toggle won't enable
**Cause**: iOS system issue or corrupted app installation
**Fix**: Reinstall app or reset location & privacy settings

### Issue: Settings opens to wrong screen
**Cause**: `AppSettings.openAppSettings()` opens general app settings
**Fix**: Navigate manually to Privacy & Security → Microphone

## Testing Steps

1. **Clean build**: `flutter clean && flutter pub get`
2. **Delete app** completely from device
3. **Rebuild**: `flutter run` 
4. **Accept call** and grant permission when prompted
5. **Verify**: Permission should work now

## Prevention

To avoid permanently denied status:
- Always select "OK" when permission dialog first appears
- Don't select "Don't Allow" during testing
- Test with fresh app installations regularly

## iOS Settings Navigation Path

**Exact Path**: Settings → Privacy & Security → Microphone → [App Name]

**Visual Guide:**
```
Settings App
    ↓
Privacy & Security (scroll down to find)
    ↓
Microphone (in privacy settings)
    ↓
Agora Voice Call (in app list)
    ↓
Toggle Switch ON
```
