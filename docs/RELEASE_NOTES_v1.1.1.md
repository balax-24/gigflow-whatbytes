# GigFlow v1.1.1 — security hardening

Same features as v1.1.0, plus a security pass. Installs over v1.1.0 (same signing key), and your data is kept.

## Security
- **Stricter Firestore rules**: `createdAt` is immutable on update, document IDs are length-limited, and tenant isolation and schema validation are unchanged. All of it is proven by a 20-case emulator test suite that now runs in CI.
- **No device backups of app data**: `allowBackup=false` plus Android 12+ data-extraction rules, so the sign-in session and cached tasks can't be copied off the device.
- **Cleartext traffic disabled** explicitly.
- **Release builds log nothing**; debug logs contain only error codes.
- **CI least privilege**: the workflow token is read-only except for the release job.
- **Supply chain**: test tooling pins a patched `@grpc/grpc-js` (0 npm audit findings); lockfiles are committed.

See [SECURITY.md](../SECURITY.md) for the full threat model.

## Install
`gigflow-v1.1.1-universal.apk` works on any Android 7.0+ phone. SHA-256 checksums are in `SHA256SUMS.txt`.
