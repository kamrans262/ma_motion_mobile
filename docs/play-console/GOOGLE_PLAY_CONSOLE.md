# MA Motion — Google Play Console

Start here when creating the app. This guide uses the Android package already in the project. Screenshots are the only store images still waiting. Send them and they will be added to section 4.

Created 10 November 2026.

## Values to use

| Field | Enter this |
|---|---|
| App name | MA Motion |
| Default language | English (United States) |
| App or game | App |
| Free or paid | Free |
| Package name | `com.mamotion.ma_motion_mobile` |
| Version | 1.0.0 (version code 1) |
| Category | Art & Design |
| Ads | No |
| In-app purchases | No |
| Designed for children | No |
| Target age | 18 and older |

The package name is locked the first time an Android App Bundle is uploaded. Build that bundle from this project only.

## 1. Create the app

1. Open [Google Play Console](https://play.google.com/console) with the developer account that should own MA Motion.
2. Click **Create app**.
3. App name: `MA Motion`
4. Default language: **English (United States)**
5. App or game: **App**
6. Free or paid: **Free**
7. Accept the declarations:
   - Developer Program Policies
   - US export laws. The app uses normal HTTPS only.
8. Click **Create app**.

Play then opens the dashboard. Finish the tasks below in this order. Do not start a production release in this pass.

## 2. App content

Open **Policy and programs**, then **App content**. Complete each item with these answers.

### Privacy policy

Play requires a public URL before the listing can be submitted. The app collects a name, email address, password, and salon photo.

Stop on this task until that page exists. Paste the URL into **Privacy policy**. Do not use a placeholder.

### App access

Choose **All or some functionality is restricted**.

Reviewer instructions:

1. Install the app.
2. Sign in with the Maker demo account below.
3. The account should already have a finished Maker profile so discovery opens.

Demo account: add the email and password when you have a real Maker login on the production API. Do not invent one in the form.

### Ads

**No**, the app does not contain ads.

### Content rating

Start the questionnaire. Category: the closest art and design choice, not a game.

Answer **No** to violence, sexual content, language, controlled substances, gambling, and crude humor.

Answer **Yes** to users being able to share images with other people. Makers upload a salon image, and discovery shows artwork from the server.

Submit the questionnaire and apply the rating it returns.

### Target audience and content

- Target age group: **18 and older** only.
- The app is **not** designed for children.
- Do not opt in to Designed for Families.

The product creates accounts and publishes a Maker profile, so keep it out of the children’s program.

### News

**No.** MA Motion is not a news app.

### Data safety

Use these answers. They match the current app.

Data is collected and sent to the MA Motion API over HTTPS. It is not sold. It is not used for advertising or tracking.

| Data | Collected | Shared | Purpose |
|---|---|---|---|
| Name | Yes | No | Account management |
| Email address | Yes | No | Account management |
| Password / credentials | Yes | No | Account management, sent only to log in or register |
| Photos | Yes | No | Maker salon image chosen from the photo library |
| App interactions, crash logs, device location | No | No | Not collected by this version |

Also answer:

- Encrypted in transit: **Yes**
- Users can request deletion: the API can delete an account, but this version has no delete-account screen. Say that a user requests deletion by contacting the support email. Do not claim an in-app delete button.
- Data collection is required for the Maker account. Discovery after sign-in depends on that account.

### Government apps

**No.**

### Financial features

**No.** This version does not take payments.

### Health

**No**, if Play shows a health declaration. The app is not a health or medical app.

## 3. Store settings

Open **Grow users**, then **Store presence**, then **Store settings**.

- App category: **Art & Design**
- Tags: art, if the tag list offers it
- Email: a mailbox you actually read
- Phone: add one if the form requires it
- Website: optional

External marketing is off unless you have a campaign URL.

## 4. Main store listing

Open **Grow users**, then **Store presence**, then **Store listings**, then the English (United States) listing.

### Name

`MA Motion`

### Short description

80 characters maximum. Paste this. It is 56 characters.

```
Join as a Maker, set up your salon, and discover artwork.
```

### Full description

```
MA Motion is a place where art and design live.

Join as a Maker. Create your account, write your profile, and choose a salon image from your photo library. Add your location, website, and contact email, then choose the types and styles that describe your work.

When your profile is ready, discover artwork, search the collection, and filter by type, style, and location.

This release is the Maker app. Sign in with a Maker account to use it.
```

Do not mention the Appreciator button. In this build that button does nothing.

### App icon

Upload this file:

`docs/play-console/icon-512.png`

It is 512×512, under 1 MB, made from `assets/logo.png`. The wordmark is centered on the app splash color `#0F2419`. Play rounds the icon itself. Do not pre-round the file.

### Feature graphic

Upload this file:

`docs/play-console/feature-graphic-1024x500.png`

It is 1024×500 and uses the same logo. Play requires it before a production release.

### Phone screenshots

Not ready. Play needs at least two phone screenshots. Minimum short side is 320 px. Use portrait shots of the real app, JPEG or 24-bit PNG, no mock status bars that do not match the app.

When you send the screenshots, they will be listed here and saved in `docs/play-console/screenshots/`.

Suggested set, in this order:

1. Splash with the MA logo
2. Maker or Appreciator choice
3. Sign in
4. Maker registration
5. Artwork discovery
6. Search or filters

### Tablet, wear, and TV

Skip. This release is a phone app. The Android id also runs on a large screen, but do not upload tablet graphics until there is a tablet layout.

## 5. App signing

Open **Test and release**, then **App integrity**.

Choose **Play App Signing**. Google holds the app signing key. This project signs the upload with a separate upload key.

| Upload key | Value |
|---|---|
| File | `android/upload-keystore.jks` |
| Alias | `upload` |
| Certificate subject | CN=MA Motion Mobile, OU=Android, O=MA Motion, C=US |
| SHA-1 | `3E:2E:E2:FB:33:86:3D:A8:58:F4:0A:5B:27:6E:CC:6E:00:7D:B6:2B` |
| SHA-256 | `99:39:85:9A:16:59:70:8A:70:62:CF:6B:A3:89:EF:28:29:1E:18:8A:E0:40:7E:83:4D:04:9F:6E:B1:9E:D3:34` |
| Valid | 10 November 2026 through 28 March 2054 |

The store password and key password stay in `android/key.properties`. They are not copied here.

Release builds already use this upload key. Do not reset the upload key.

## 6. Build the bundle

From the project root, with the real API host:

```
flutter build appbundle --release --dart-define=MA_API_BASE_URL=https://YOUR_API_HOST
```

The file to upload is:

`build/app/outputs/bundle/release/app-release.aab`

If `MA_API_BASE_URL` is omitted, the app points at an invalid host and sign-in fails for reviewers.

## 7. Internal testing

Use an internal test track before production.

1. Open **Test and release**, then **Testing**, then **Internal testing**.
2. Select the countries you want testers in.
3. Create a release.
4. Upload `app-release.aab`.
5. Release name: `1.0.0 (1)`
6. Release notes:

```
First Maker release. Create an account, set up your salon profile, and discover artwork.
```

7. Review the bundle. Confirm the package is `com.mamotion.ma_motion_mobile` and the version is `1.0.0 (1)`.
8. Save, review, and roll out to internal testing only.

Add tester email addresses on the internal testing page and send them the opt-in link.

New personal Play accounts usually cannot go to production until a closed test has at least 12 testers opted in for 14 days. The dashboard states this if it applies to the account. Organization accounts are often exempt. Stay on internal testing until that requirement is either finished or confirmed absent.

## Before production

These are still open. Production should wait for them.

- Privacy policy URL
- Support email, and a phone number if the form requires one
- Maker demo account for review
- Phone screenshots
- A real `MA_API_BASE_URL` in the uploaded bundle
- A way for a Maker to delete an account. The server route exists. The app does not show it yet. Play expects account deletion for apps that let people register.

Send the screenshots when you have them. The listing text, icon, and feature graphic above are ready to paste.
