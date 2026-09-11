# MA Motion Mobile M01 — Backend Contract Audit

This document records the mobile-facing contracts that are already confirmed
by the completed Laravel backend and must be reused by Flutter.

## Confirmed foundation/auth routes

- GET `/api/v1/health`
- POST `/api/v1/auth/register`
- POST `/api/v1/auth/login`
- POST `/api/v1/auth/logout`
- POST `/api/v1/auth/forgot-password`
- POST `/api/v1/auth/reset-password`
- GET `/api/v1/me`

Laravel verification has existing tests for:
- registration
- login
- token-authenticated `/me`
- logout
- inactive-account rejection
- role authorization
- auth rate limiting
- standard API error contracts

## Confirmed Maker/account routes

- PATCH `/api/v1/me/maker-profile`
- PATCH `/api/v1/me/profile`
- POST `/api/v1/me/profile-image`
- DELETE `/api/v1/me/profile-image`
- PUT `/api/v1/me/password`
- DELETE `/api/v1/me/account`
- GET `/api/v1/me/maker-statistics`
- GET `/api/v1/me/artworks`
- GET `/api/v1/makers`
- GET `/api/v1/makers/{maker}`
- GET `/api/v1/makers/{maker}/shows`
- GET `/api/v1/makers/{maker}/shows/{show}`

The backend also has verified Maker artwork CRUD/media security tests and
Maker show CRUD/public-show tests.

## Confirmed discovery routes

- GET `/api/v1/discovery`
- GET `/api/v1/discovery/artworks`
- GET `/api/v1/discovery/makers`
- GET `/api/v1/discovery/filters`
- GET `/api/v1/discovery/locations`
- GET `/api/v1/discovery/search`

Existing Laravel tests verify:
- public artwork-only discovery behavior
- Type/Style filters
- location autocomplete
- radius filtering
- artwork-location first with Maker-location fallback
- unified artwork + Maker search
- pagination/filter validation

## M01 Flutter contract

Flutter must never talk directly to MySQL.

Architecture:

Flutter UI
→ Riverpod
→ Repository
→ ApiGateway (Dio)
→ HTTPS `/api/v1`
→ Laravel
→ MariaDB / Laravel storage

M01 deliberately does not submit the current Maker onboarding yet. That is
Maker-flow M02. M01 creates and verifies the shared infrastructure M02+ will
reuse.

## Environment

Run against a real backend by supplying either the Hostinger origin or full
API base URL:

`--dart-define=MA_API_BASE_URL=https://example.com`

The app normalizes that to:

`https://example.com/api/v1`

If a full `/api/v1` URL is supplied, it is preserved.
