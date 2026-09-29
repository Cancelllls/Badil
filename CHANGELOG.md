# Changelog

All notable changes to the **Badil (بَديل)** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-09-29

### Added
- **Open Boycott Database Integration**: Ingested the golden-source [TechForPalestine](https://github.com/TechForPalestine/boycott-israeli-consumer-goods-dataset) dataset (883 international brands across 101 parent companies) combined with local Egyptian and Arab market data, expanding the offline database to 959 products.
- **GS1 Barcode Country Prefix Engine**: Added an offline GS1 3-digit country code detection table (40+ countries). Even uncataloged barcodes instantly display their country of origin and alert flags (e.g., prefix `729` 🇮🇱 Israel alert, `622` 🇪🇬 Egypt, `628` 🇸🇦 Saudi Arabia).
- **Full Bilingual (Arabic & English) Architecture**: Added complete bilingual dictionary (`AppStrings`) and zero-dependency `LocaleController` with dynamic RTL/LTR directionality switching and SQLite-backed setting persistence.
- **Instant Language Toggle**: Integrated 1-tap `AR | EN` switch button into the scanner top bar and header navigation.
- **Community Alternative Submission**: Added bilingual suggestion sheet allowing users to recommend local Egyptian and Arab alternatives for products.
- **Automated Open Data Ingestion Pipeline**: Created `tool/import_open_data.py` to pull, normalize, and compile offline SQLite FTS5 seed databases directly from open datasets.
- **CI/CD Workflow Dispatch**: Upgraded GitHub Actions release workflow with dynamic version tag resolution and manual dispatch support.

### Changed
- **UI/UX Pro Max Redesign**: Re-engineered UI theme with obsidian dark background (`#0A0F1D`), high-contrast semantic borders, and emerald/crimson accent badges.
- **Modern Scanner Interface**: Implemented frosted glass floating control bar, animated pulsing laser reticle, and uncataloged barcode alert banner.
- **Redesigned Product Result Sheet**: Enhanced product inspection modal with status pills, manufacturer badges, verified reason cards, and elevated alternative product cards with quality star ratings.
- **Optimized Search & Filter**: Added segmented status filters (*All / Boycott / Safe Alternatives*), category filter chips, and debounced FTS5 search queries.
- **Categories Grid**: Redesigned category screen with modern 2-column card layout, custom icons, and localized category names.

---

## [1.0.0] - 2026-09-28

### Added
- **Initial Release of Badil (بَديل)**: 100% offline-first barcode scanner and alternatives discovery engine for Android.
- **Offline SQLite FTS5 Engine**: Bundled local database (`badil_seed.db`) with full-text search and < 10ms barcode query latency without network connectivity.
- **Arabic Text Normalization**: Built-in SQLite tokenizer query normalization for Arabic diacritics and character variants (`أ/إ/آ -> ا`, `ة -> ه`, `ى -> ي`).
- **Mobile Barcode Scanner**: Hardware camera scanner with automatic torch toggle and haptic feedback.
- **Curated Egyptian Alternatives**: Seeded alternatives database highlighting Egyptian brands (*Spiro Spathis, V7, Corona, Bimbo, Lamar, Juhayna, Domty, Oxi, Feba, Eva Cosmetics*).
- **F-Droid Privacy Compliance**: Zero proprietary Google Play Services, zero analytics/telemetry, and clean GPL-3.0 copyleft architecture.
- **GitHub Actions Release Pipeline**: Automated multi-architecture APK compilation (`arm64-v8a` and universal builds).
