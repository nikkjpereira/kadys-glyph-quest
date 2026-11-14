extends RefCounted
## Rename-safe metadata. Updating a public store brand does not require
## changing the Android package ID (which would break installed apps).
const DISPLAY_NAME := "Kady's Glyph Quest"
const TITLE_LINE_1 := "KADY'S"
const TITLE_LINE_2 := "GLYPH QUEST"
const VERSION := "0.5.0"
const ANDROID_APPLICATION_ID := "com.nefariousmedia.kadysglyphquest"
const ADS_ENABLED := false
const IN_APP_PURCHASES_ENABLED := false
const PRIVACY_FIRST := true
## Product concepts are RESERVED, not actual store products or entitlements.
const FUTURE_PRODUCTS := ["remove_ads", "booster_pack", "cosmetic_theme"]
## Recommended monetization policy:
## - No ads in levels, between retry taps, or during tutorials.
## - Rewarded ads must be explicitly chosen and award only after verification.
## - Purchases must verify Play Billing and restore nonconsumables.
## - Age-appropriate content and family policy review before publishing.
