# Delta Key Generator

An Android app that generates Platoboost links for the Delta service (Service ID 6).

## Features

- **Get Key (Device HWID)** — Generates a stable hardware-based identifier stored in the app's localStorage, then calls the Platoboost API to generate a link. Re-running this button always produces the same HWID on the same device (matches your existing `~/.platoboost_identifier` behavior in Node/Termux).
- **Random Key** — Generates a fresh random HWID on every tap (one-shot, not persisted).
- Copy HWID / Copy link / Open link buttons.
- Shows the current HWID at the top of the screen.
- Auto-fails over between `api.platoboost.com` and `api.platoboost.net`.

## How it works

The app is a tiny WebView wrapper (`MainActivity.kt`) that loads a self-contained HTML/JS app from `app/src/main/assets/index.html`. All the Platoboost API logic lives in that single HTML file - it's essentially your Node.js script ported to browser JavaScript.

The HWID is generated using:
- `window.crypto.subtle.digest('SHA-256', ...)` for hashing (the browser equivalent of Node's `crypto.createHash('sha256')`)
- `window.crypto.getRandomValues()` for random bytes (the browser equivalent of `crypto.randomBytes()`)
- `localStorage` to persist the device HWID across launches (the browser equivalent of writing to `~/.platoboost_identifier`)

## Project structure

```
delta-key-generator/
├── app/
│   ├── build.gradle.kts
│   ├── proguard-rules.pro
│   └── src/main/
│       ├── AndroidManifest.xml
│       ├── assets/index.html             ← All the app logic (HTML/CSS/JS)
│       ├── java/com/deltakey/app/
│       │   └── MainActivity.kt           ← WebView wrapper
│       └── res/
│           ├── drawable/                  ← Vector launcher icons
│           ├── mipmap-anydpi-v26/         ← Adaptive icon (Android 8+)
│           ├── mipmap-{m,h,x,xx,xxx}hdpi/ ← PNG launcher icons (Android 5-7)
│           ├── values/                    ← strings, colors, theme
│           └── xml/network_security_config.xml
├── gradle/wrapper/gradle-wrapper.properties
├── .github/workflows/build.yml            ← GitHub Actions cloud build
├── .gitignore
├── build-termux.sh                        ← Termux build script
├── build.gradle.kts
├── settings.gradle.kts
├── gradle.properties
├── gradlew
└── README.md
```

## How to build the APK

You have **three** options. Pick whichever is easiest for you.

---

### Option 1: GitHub Actions (easiest - no setup, no PC, no Termux tooling)

This builds the APK in the cloud for free and lets you download it.

1. Create a free GitHub account if you don't have one.
2. Create a new repository (e.g. `delta-key-generator`).
3. Upload all the files from this project to the repo (drag-and-drop on github.com works).
4. Go to the **Actions** tab → click **Build APK** workflow → **Run workflow**.
5. Wait ~5-10 minutes for the build to finish.
6. Click into the run → scroll down to **Artifacts** → download `delta-key-generator-apk`.
7. Unzip the downloaded file → you get `app-debug.apk` → install on your phone.

---

### Option 2: Termux (build directly on your phone)

1. Install [Termux](https://f-droid.org/en/packages/com.termux/) from F-Droid (the Play Store version is outdated).

2. Give Termux storage access:
   ```bash
   termux-setup-storage
   ```

3. Install prerequisites:
   ```bash
   pkg update && pkg upgrade -y
   pkg install -y openjdk-17 git unzip wget
   ```

4. Copy this project folder into Termux's home directory. From Termux:
   ```bash
   # If you downloaded the project zip to ~/storage/downloads/
   cp ~/storage/downloads/delta-key-generator.zip ~/
   cd ~
   unzip delta-key-generator.zip
   cd delta-key-generator
   ```

5. Install Android SDK:
   ```bash
   pkg install -y android-sdk android-sdk-build-tools
   ```
   If `android-sdk` package is not available, install via `sdkmanager`:
   ```bash
   mkdir -p ~/android-sdk/cmdline-tools
   wget -O /tmp/cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
   unzip /tmp/cmdline-tools.zip -d ~/android-sdk/cmdline-tools/
   mv ~/android-sdk/cmdline-tools/cmdline-tools ~/android-sdk/cmdline-tools/latest
   export ANDROID_SDK_ROOT=~/android-sdk
   yes | ~/android-sdk/cmdline-tools/latest/bin/sdkmanager --licenses
   ~/android-sdk/cmdline-tools/latest/bin/sdkmanager "platforms;android-34" "build-tools;34.0.0" "platform-tools"
   ```

6. Run the build script:
   ```bash
   cd ~/delta-key-generator
   bash build-termux.sh
   ```

7. The APK will be at:
   ```
   ~/delta-key-generator/app/build/outputs/apk/debug/app-debug.apk
   ```

8. Copy it to your Downloads and install:
   ```bash
   cp ~/delta-key-generator/app/build/outputs/apk/debug/app-debug.apk ~/storage/downloads/DeltaKeyGenerator.apk
   termux-open ~/storage/downloads/DeltaKeyGenerator.apk
   ```

---

### Option 3: Android Studio on a PC (most reliable)

1. Download and install [Android Studio](https://developer.android.com/studio).
2. Open Android Studio → **Open** → select this project folder.
3. Wait for the initial Gradle sync to finish (downloads dependencies, ~2-5 minutes).
4. Click the green ▶️ Run button (or **Build → Build Bundle(s) / APK(s) → Build APK(s)**).
5. The APK is at `app/build/outputs/apk/debug/app-debug.apk`.
6. Transfer it to your phone (USB, email, cloud drive) and install.

---

## Installing the APK on your phone

After you have the APK file (`app-debug.apk`):

1. On your phone, open **Settings → Apps → Special access → Install unknown apps** (or **Settings → Security → Unknown sources** on older Android).
2. Allow your file manager (e.g. Files, Chrome) to install unknown apps.
3. Open the APK file from your file manager.
4. Tap **Install**.

---

## Customizing

- **Change the service ID**: Edit `SERVICE_ID = 6` in `app/src/main/assets/index.html`. Use `8` for Delta iOS, etc.
- **Change app name**: Edit `<string name="app_name">` in `app/src/main/res/values/strings.xml`.
- **Change colors**: Edit the CSS in `index.html` (look for `--bg`, `#6366f1`, etc.) or `res/values/colors.xml` for native UI.

---

## Troubleshooting

**"Could not connect to Platoboost API"**
- Check your internet connection.
- The app already tries both `api.platoboost.com` and `api.platoboost.net` automatically.

**HWID changes between installs**
- The HWID is stored in the app's localStorage. Uninstalling the app clears localStorage, so the HWID will change. This matches your Node script's behavior of clearing `~/.platoboost_identifier`.

**Build fails on Termux**
- Termux builds can be flaky. If it fails, try GitHub Actions (Option 1) instead - it's the most reliable.
- Make sure you have enough free storage (~3 GB) for the Android SDK.

**"App not installed" when installing APK**
- Make sure you have allowed unknown sources for your file manager.
- If a previous version is installed, uninstall it first.
