# Web Login & Signup Responsiveness Plan

## Goal Description
Improve the visual layout of the Login and Signup screens on web and large screens. Currently, the forms stretch across the entire screen width, which provides a poor user experience. The goal is to center the content in a constrained container (like a Card) for a professional look.

## Proposed Changes

### Authentication Screens
#### [MODIFY] [login_screen.dart](file:///Users/ousmane/Documents/silkoul_ahzabou/lib/screens/auth/login_screen.dart)
- Wraps the main content in a `Center` widget.
- Uses `ConstrainedBox` with a `maxWidth` of 500 pixels.
- On Web (`kIsWeb`), wraps the form in a `Card` with elevation and padding.
- Preserves existing mobile layout logic (full width).

#### [MODIFY] [signup_screen.dart](file:///Users/ousmane/Documents/silkoul_ahzabou/lib/screens/auth/signup_screen.dart)
- Applies the same responsive layout logic as the Login screen.
- Wraps content in `Center` -> `ConstrainedBox` -> `Card` (on Web).

## Verification Plan
### Manual Verification
- **Mobile**: Verify that the layout remains unchanged and looks good on small screens.
- **Web/Desktop**: Resize the window to verify that the form remains centered and does not stretch beyond 500px width.
- Verify that the `Card` styling appears only on web/desktop.

---

# [PAUSED] Google Auth Mobile Setup

## Goal Description
Configure Google Sign-In for Android and iOS native flows. Currently using the web-based OAuth flow which works but is less integrated.

## Required Steps (To Be Resumed)
1.  Generate SHA-1 fingerprint for Android.
2.  Add SHA-1 to Google Cloud Console (Android Client).
3.  Configure URL Schemes for iOS in `Info.plist`.
4.  Test native sign-in flow on physical devices/emulators.

---

# [PENDING] Infrastructure & Monitoring

## Goal Description
Automate SSL certificate management and implement server monitoring for the VPS deployment.

## Proposed Strategy (Brainstormed)
- **SSL**: Use Nginx Proxy Manager (Docker) for GUI-based management of Let's Encrypt certificates.
- **Monitoring**: Deploy Uptime Kuma for status checks and alerting.
- **Log Viewing**: Deploy Dozzle for easy log access.

See [infrastructure_brainstorm.md](file:///Users/ousmane/.gemini/antigravity/brain/24c1cee2-30d0-4f87-9dc5-a95e2ba80507/infrastructure_brainstorm.md) for details.
