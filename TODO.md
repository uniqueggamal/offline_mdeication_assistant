# Theme/UI Matching Plan for MedicationEditorScreen

## Status: [IN PROGRESS] ✅ Steps 1-5 ✅ Completed (AppBar, cards, status pill, bottom bar, stock colors)

**Goal**: Match MedicationEditorScreen theme/UI with MedicationsScreen using MedListColors, AppBar, cards, status pill.

## Steps:
- [x] **Step 1**: Add imports and update Scaffold/AppBar with MedListColors.primaryColor/white styling.
- [x] **Step 2**: Replace _sectionCard with Material card style matching CardMedList (white, elev 1, radius 14, padding 12, title w700).
- [x] **Step 3**: Convert status SegmentedButton to _StatusPill using medicationStatusColor alpha 0.14.
- [x] **Step 4**: Style bottom bar and image picker with MedListColors.card, matching radii/shadows.
- [x] **Step 5**: Update stock colors to MedListColors.stock* equivalents; style group chip with primaryColor.
- [ ] **Step 6**: Apply consistent text weights (w700 for titles), verify paddings.
- [ ] **Step 7**: Test with `flutter run`; mark complete.

**Completed**: Steps 1-5.

**Next**: Step 6 - Text styles & final tweaks, then test.

