# TestFlight: first build on your iPhone

Written 2026-11-24 for Godot 4.7.2 and current Xcode. Menu names in Apple's sites and in Godot move often; anything marked **verify** may be worded differently on your screen.

Time: about 60 to 90 minutes the first time (mostly downloads), about 10 minutes for each build after that.

## 0. Decide once (cannot be changed later)

| Item | Value |
|---|---|
| Bundle ID | `com.matthewmeza.pilgrim` |
| App name | Pilgrim in Progress |
| SKU (private, any text) | `pilgrim-001` |

The bundle ID is permanent for this app. It does not tie the app to your individual account: an app can be transferred to an organisation account later and keeps its bundle ID. **verify**

## 1. Apple setup (once, in a browser)

1. **Find your Team ID.** developer.apple.com → Account → Membership details → Team ID (10 characters). You will type it into Godot. It is an identifier, not a password.
2. **Register the bundle ID.** developer.apple.com → Certificates, IDs & Profiles → Identifiers → **+** → App IDs → App → Explicit, `com.matthewmeza.pilgrim`, description "Pilgrim in Progress". No extra capabilities. Register.
3. **Create the app record** (this also reserves the name). appstoreconnect.apple.com → Apps → **+** → New App → iOS, name "Pilgrim in Progress", primary language English (U.S.), the bundle ID above, SKU `pilgrim-001`, Full Access. If the name is taken, tell Claude before choosing another.

## 2. Mac tools (once)

1. **Xcode** from the Mac App Store. Open it once and let it install components, including the iOS platform.
2. Xcode → Settings → Accounts → **+** → Apple ID. Sign in with your developer account.
3. **Godot 4.7.2** (standard build, not .NET) from godotengine.org → Download → Archive → 4.7.2-stable. Move it to Applications.
4. Open Godot → Editor → Manage Export Templates → **Download and Install** (4.7.2). About 1 GB.

## 3. Get the project (each new build)

1. github.com/TrueDominion/pilgriminprogressgame → green **Code** button → **Download ZIP** (branch `main`).
2. Unzip it. In Godot's Project Manager → **Import** → pick `game/project.godot` inside the unzipped folder → Import & Edit. The first import takes a minute.

## 4. Export from Godot

1. Project → Export → **Add…** → iOS.
2. Set:
   - App Store Team ID: your Team ID
   - Bundle Identifier: `com.matthewmeza.pilgrim`
   - Short Version: `0.1.0`; Version: `1` (raise Version by 1 for every upload)
   - Export Method (release): App Store
   - Leave icons empty for now; Godot's default icon is fine for TestFlight.
3. If the panel shows red text at the bottom, the templates or Team ID are missing; fix those first.
4. **Export Project…** → make a new folder `~/pilgrim-ios` → file name `Pilgrim` → untick **Export With Debug** → Save. Godot writes an Xcode project there. If Godot asks to build the .ipa itself and it fails, that is fine; the Xcode project is what you need.
5. Godot remembers these settings in `game/export_presets.cfg`. Do not commit that file from your Mac; Claude will add the iOS preset to the repo once your first build works.

## 5. Quick test on your phone (optional, fastest check)

1. Plug in the iPhone, unlock it, tap **Trust**. On the phone: Settings → Privacy & Security → Developer Mode → On (it restarts).
2. Open `~/pilgrim-ios/Pilgrim.xcodeproj`. Select the Pilgrim target → Signing & Capabilities → tick **Automatically manage signing**, Team: yours.
3. At the top, choose your iPhone as the destination → press ▶ (Run).

## 6. Upload to TestFlight

1. In Xcode, destination: **Any iOS Device (arm64)**.
2. Product → **Archive**. When it finishes, the Organizer opens.
3. **Distribute App** → App Store Connect → Upload (or **TestFlight Internal Only**) → keep the defaults → Upload. **verify**
4. App Store Connect → your app → TestFlight. The build shows "Processing" for 10 to 30 minutes, and Apple emails you when it is ready.
5. If it asks about encryption: the app uses none beyond iOS itself, so answer that it uses no non-exempt encryption.
6. Internal Testing → **+** → create a group "Family" → add yourself (and anyone on your team) → add the build.
7. On the iPhone: install **TestFlight** from the App Store, open the invite, Install.

## If something fails

Send Claude the exact error text or a screenshot. Common ones:

| Error | Fix |
|---|---|
| "No account for team" / signing errors | Xcode → Settings → Accounts, sign in again; pick the Team under Signing & Capabilities. |
| "Bundle identifier is not available" | The ID was not registered in step 1.2, or is spelled differently. |
| "Redundant binary upload" | Raise Version in Godot (step 4.2) and export again. |
| Missing iOS platform in Xcode | Xcode → Settings → Components → install iOS. |
