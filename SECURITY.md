# Security

GigFlow stores personal task data per user in Cloud Firestore. This document lists the threat model, each control, and how it is **verified**.

## Threat model (what we protect against)

| Threat | Control | Verified by |
|---|---|---|
| Reading or writing another user's tasks (IDOR / broken access control) | Firestore rules: `users/{uid}/tasks/**` is accessible only when `request.auth.uid == uid`; everything else is denied by default | `security/firestore-rules.test.mjs`: cross-user read/list/write/delete all fail |
| Unauthenticated access | Every rule requires `request.auth != null` | Rules tests: signed-out reads and writes fail |
| Mass assignment / schema tampering (extra fields such as `isAdmin`, wrong types, oversized strings) | `hasAll` + `hasOnly` key allow-list, type checks, enum checks, size limits, doc-id length limit | Rules tests: 11 malformed-payload cases are rejected |
| Tampering with history (rewriting `createdAt`) | `update` requires `createdAt` to be unchanged | Rules test: "createdAt cannot be rewritten" |
| Credential stuffing / brute force | Firebase Auth rate limiting (`too-many-requests` is surfaced to the user) | `firebase_error_mapper_test` |
| Account enumeration | Email-enumeration protection (Firebase default) returns `invalid-credential` for both cases; the password-reset message is identical whether or not the account exists | Manual + `auth_bloc` code review |
| Weak passwords | Client: at least 6 characters with a letter and a number on sign-up; server: Firebase minimum | `validators_test` |
| Session leakage between accounts | `TaskBloc` is scoped to the `/tasks` route, so sign-out closes the Firestore listener; the Google session is also signed out | `task_bloc_test`, device test |
| Data exfiltration via device backup | `android:allowBackup="false"` plus `dataExtractionRules` exclude all app data from cloud backup and device transfer | Release manifest inspected with `aapt2` |
| Network interception | All Firebase traffic is TLS; `usesCleartextTraffic="false"` | Manifest |
| Sensitive data in logs | Logs print only error *codes*, only in debug builds (`kDebugMode`) | Code review (`grep` for `print`/`debugPrint`) |
| Leaked secrets in the repo | Keystore and `android/key.properties` live outside git and are `.gitignore`d; local test credentials are kept in gitignored `*.local.md`. History scanned: no keystore, password, service-account or `.env` content ever committed | `git log -p` secret scan |
| Supply chain | `pubspec.lock` and `security/package-lock.json` are committed; `@grpc/grpc-js` is pinned to a patched version (GHSA-m9gg-hp2v-232j, GHSA-f596-whhp-79r4); `npm audit`: 0 vulnerabilities | CI + `npm audit` |
| Over-privileged CI token | Workflow token is `contents: read` by default; only the release job gets `contents: write` | `.github/workflows/ci.yml` |
| Release tampering | Release APKs are signed with a dedicated upload key (SHA-1 `31:6A:3D:…:46`), R8-minified, and published with `SHA256SUMS.txt` | `apksigner verify --print-certs` |

## About the API keys in this repo

`lib/firebase_options.dart`, `google-services.json` and `GoogleService-Info.plist` contain Firebase **client** identifiers. They are designed to ship inside the app and are not secrets; authorization is enforced by the security rules above. As defence in depth, the project owner should restrict these keys in Google Cloud Console (Credentials → API key → Application restrictions: Android app `dev.gigflow.gigflow` + SHA-1, iOS bundle `dev.gigflow.gigflow`).

## Running the security tests

```bash
npm install -g firebase-tools
npm ci --prefix security
firebase emulators:exec --only firestore --project demo-gigflow "npm --prefix security test"
```

The `demo-` project ID guarantees the tests run only against the local emulator, never production. CI runs this suite on every push.

## Recommended next steps (not required for this release)

- Enable **Firebase App Check** (Play Integrity / App Attest) so only genuine app builds can reach the backend.
- Enable a stronger **password policy** in Firebase Authentication settings.
- Turn on GitHub **secret scanning**, **Dependabot alerts** and **branch protection** for `main` once the repository is public.

## Reporting a vulnerability

Please open a private security advisory on this repository rather than a public issue.
