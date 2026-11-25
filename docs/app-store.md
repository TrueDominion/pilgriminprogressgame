# App Store Plan

Status: phase 1 research, 2026-11-23. Every item marked **verify** must be re-checked in App Store Connect and the App Review Guidelines at submission time; Apple changes these often. Nothing here is legal advice.

## 1. Accounts and identity (decide before phase 5)

Status 2026-11-24: owner has an Apple Developer account (enrolled as an individual, no D-U-N-S yet). TestFlight works on it now; the seller decision below is only needed before the store launch. Steps: `docs/testflight.md`.

| Item | Recommendation | Why |
|---|---|---|
| Apple Developer Program | Enrol as an **organisation**, not an individual | An individual account shows your legal name as the seller and, for EU sales, publishes your personal address, phone and email under the Digital Services Act trader rules. An organisation needs a legal entity and a D-U-N-S number (free, takes days to weeks). **verify** |
| Bundle ID | `com.matthewmeza.pilgrim` (confirmed by owner 2026-11-25) | Cannot be changed after the first upload. Neutral enough to keep if the app moves to an organisation account later (app transfer keeps the bundle ID). **verify** |
| App name | "Pilgrim in Progress" | A web search found no app with this exact name; similar titles exist ("The Pilgrim's Progress" on Steam, Amanita Design's "Pilgrims" on iOS). Reserve it by creating the App Store Connect record early in phase 2. Run a USPTO trademark search before spending on marketing. |
| EU distribution | Include the EU only once the seller entity is set | See above. |

## 2. Privacy

- **Data collected: none.** No analytics, no ads, no accounts, no network calls, no crash reporting SDKs. App Privacy label: **Data Not Collected**.
- **App Tracking Transparency prompt:** not needed; the app does not track.
- **Privacy policy URL:** required for every app. Host on the existing website (`pilgriminprogress` repo) at `/privacy`. Draft: `docs/privacy-policy.md`.
- **Privacy manifest:** Godot's iOS export includes `PrivacyInfo.xcprivacy` declaring its required-reason API use (file timestamps, system boot time, disk space, user defaults). Check it is present in the Xcode project before archiving. **verify** with Godot 4.7.2.

## 3. Age rating

Apple's ratings are now 4+, 9+, 13+, 16+, 18+ (12+ and 17+ were retired in 2025), set by a questionnaire in App Store Connect, and can vary by region.

Expected answers: cartoon or fantasy violence **infrequent/mild** (Apollyon's darts and swipes, arrows; no blood, no death shown); frightening themes **infrequent/mild** (Apollyon, the dark valley, Giant Despair); no user-generated content, no web access, no chat, no purchases, no gambling, no medical content. Expected result: **9+**. **verify** by answering the live questionnaire.

## 4. Kids Category: recommendation is **do not join**

Restrictions that come with it (Guideline 1.3 and 5.1.4):

- You must choose one age band: 5 and under, 6 to 8, or 9 to 11. Our audience is 8 to adult, which fits none of them cleanly.
- No third-party analytics or advertising (we have none anyway).
- A parental gate before any link out of the app, any permission request or any purchase (including the support link in Credits).
- Kids-category standards apply to every future update, **even if you later leave the category**.

The benefit is a small browsing shelf. The cost is a permanent constraint and a mismatched age band. The game meets the spirit of the rules regardless (no data, no ads, no links except the support page). Market it as "for families" in the description instead.

## 5. Export compliance

The app uses no encryption beyond what iOS provides and makes no network connections. Set `ITSAppUsesNonExemptEncryption = NO` in the Info.plist (Godot export option or Xcode), and answer "No" to the encryption question. No export documentation needed. **verify** the setting is in the exported plist.

## 6. AI-generated content disclosure

As of the October 2026 App Review Guidelines (as reported; read the live page before submitting), there is **no general requirement to label AI-generated art in a game**. The AI rules that exist cover apps that let users generate content (moderation duties, guideline 1.2), sharing user data with AI services (5.1.2) and a new rule against apps that behave differently after review (2.5.19). None apply to a game whose art was made with AI tools during development.

Recommendation: disclose anyway, briefly, in the in-game credits ("Art and audio generated with Higgsfield and finished by hand") and in the App Store description's last line. It costs nothing, matches the faith-based audience's expectation of honesty, and pre-empts a reviewer or a one-star review raising it.

## 7. Screenshots and preview (from Apple's specifications, 2026)

- **Required:** one set for 6.9-inch iPhone (or 6.5-inch), and one set for 13-inch iPad if the app runs on iPad. Up to 10 per size. PNG or JPEG.
- **Sizes (landscape):** iPhone 6.9-inch 2868 x 1320 (also 2796 x 1290, 2736 x 1260); iPad 13-inch 2752 x 2064 or 2732 x 2048. **verify** in App Store Connect's media manager before export; Apple added iPhone 18 Pro sizes in September 2026.
- **iPad:** recommend shipping as a universal app. Families play on iPads; the game already handles 4:3 via ScreenFit.
- **Preview video:** 15 to 30 seconds, H.264 or ProRes 422 HQ, under 500 MB, up to 3 per localisation. **Guideline 2.3.4 allows only screen captures of the app itself**, with optional narration and text overlays. Higgsfield-generated footage would be rejected. We capture gameplay from the game (a debug build with a clean HUD) and edit it; Higgsfield can contribute the caption-band art only. Previews autoplay muted, so captions carry the message.
- **Screenshot plan (6 frames):** 1. The burden (stage 1, Christian bent under the load) "Carry the burden." 2. The Slough "Keep moving." 3. The Cross "Feel it fall." 4. Double jump on Hill Difficulty "Run free." 5. Apollyon "Stand firm." 6. The Celestial City "Reach the City." Each is a real in-game capture with a parchment caption band.

## 8. Pricing recommendation: **$4.99 one-time**

- Premium, ad-free, story-led mobile games mostly sit between $2.99 and $6.99. **verify** comparables before launch (pull 5 current titles in Adventure and Family).
- $4.99 signals a finished, crafted game to parents and churches without being a hurdle; Family Sharing (on by default for paid apps) makes it one purchase per family.
- Below $2.99 trains buyers to wait for free and does not fund the credits; above $6.99 needs reviews and screenshots the game will not have at launch.
- Plan one launch-week visibility push (church networks, your site), and use a temporary price drop to $2.99 around Easter rather than discounting at launch.
- Revenue maths is yours to model; with Apple's Small Business Program the commission is 15% (enrol, it is not automatic). **verify**

## 9. Listing copy (draft)

- **Subtitle (30 chars):** "A pilgrim's journey in pixels"
- **Promotional text (170 chars):** "Carry the burden. Feel it fall at the Cross. Walk John Bunyan's road from the City of Destruction to the Celestial City in a hand-crafted pixel adventure."
- **Description, first lines:** "Christian carries a burden he cannot put down. It slows every step and drags at every jump, until he reaches the Cross. Pilgrim in Progress is a short, family-friendly side-scrolling adventure based on John Bunyan's The Pilgrim's Progress (1678). No ads. No in-app purchases. No data collected."
- **Keywords (100 chars, draft):** `pilgrim,bunyan,christian,bible,faith,platformer,pixel,adventure,allegory,family,story,church,kjv`
- **Support URL:** the website's support page. **Marketing URL:** the website home page.
- **Category:** Games, primary Adventure, secondary Family.

## 10. TestFlight plan

- Internal testing first (you and up to 100 App Store Connect users), no review needed.
- External group of 10 to 20 testers: a mix of 4 to 5 families with children aged 8 to 12, 3 to 4 adult readers of Bunyan, 2 to 3 experienced platformer players, and 2 people who rarely play games. External builds need a short beta review (usually within a day).
- Two rounds of one week each. Feedback through TestFlight's built-in screenshot feedback plus a 6-question form (ends: could you finish? where did you get stuck? did the Cross land? anything confusing or uncomfortable for children?).
- Exit criteria: no crash in the last round; every tester finished stage 4; median full playthrough between 45 and 70 minutes.

## 11. Most common rejection reasons and how we avoid them

| Guideline | Reason | Our defence |
|---|---|---|
| 2.1 App completeness | Crashes, broken links, placeholder content | Full playthrough on device before submission; no "TBD" strings (a CI check greps content for TBD) |
| 2.3.3 / 2.3.4 | Screenshots or preview not showing the real app | Real captures only |
| 2.3.7 | Misleading name or keywords (e.g. other games' names) | No competitor names in keywords |
| 4.0 Design | Not using the safe area, broken on iPad | ScreenFit and safe-area HUD; test on iPad simulator |
| 5.1.1 | Privacy policy missing or inaccurate | Policy live on the website before submission; label "Data Not Collected" matches reality |
| 2.5.1 | Private or non-public APIs | Godot official export templates only |
| 4.2 Minimum functionality | Thin apps | Not a risk for a full game |
| Metadata | Age rating answers inconsistent with content | Answer conservatively; mention Apollyon in the review notes |
| 2.5.19 (new) | App behaves differently after review | No remote config or server switches exist |
| Review access | Reviewer cannot reach later content | Review notes explain the stage select after completion and offer Pilgrim's Aid for fast verification |
