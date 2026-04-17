# Contract Accepted: Sprint 4

Contract approved at 2026-04-17T12:00:00Z. The Generator may proceed with implementation.

## Review Summary

The revised Sprint 4 contract (v2.0) adequately addresses all 4 critical issues and 6 important issues identified in the initial review:

### Critical Issues — Resolved
1. **Home page refresh mechanism**: `HomeRepository.watchAllGames()` returns `Stream<List<Game>>`; HomeBloc subscribes reactively. Success criteria SM3, SM4, RD1–RD4 verify this end-to-end.
2. **Initial focus state**: First game in first row is auto-focused on `HomeLoaded`. `focusedRowIndex = 0`, `focusedCardIndex = 0`. Success criterion SM8 confirms.
3. **LaunchStatus simplified**: Enum reduced to `{idle, launching, error}`. Status transitions explicitly documented with 2-second auto-return to idle. Success criterion GL8 verifies.
4. **Game entity metadata field**: Noted as Sprint 5 extension. Sprint 4 UI handles `metadata == null` with gradient fallback, placeholder text, and empty genre chips. Clear and workable approach.

### Important Issues — Resolved
5. **Row ordering**: Explicitly specified as Recently Added → All Games → Favorites (§2.2, criterion R1).
6. **Empty row behavior**: Rows with zero games are filtered out and hidden (§2.2, criteria R4, R5).
7. **Loading/error state UI**: Shimmer/skeleton loading state and error state with retry button are specified with dedicated widgets (§2.4, criteria L7, L8).
8. **B/Escape behavior**: Explicitly specified — does nothing on home page (§2.4, criterion N6).
9. **Responsive card rows**: Breakpoints specified with card count ranges (§2.4, criterion R11).
10. **Sound effects**: `playFocusMove()`, `playFocusSelect()`, `playPageTransition()` specified for home page interactions (§2.4, criteria S1–S5).

### Minor Observations (non-blocking)
- The contract references `game.metadata?.heroImageUrl` in DynamicBackground, but the `metadata` field on `Game` is noted as a Sprint 5 addition. The Generator should add the nullable `metadata` field to `Game` in Sprint 4 (defaulting to null) so the code compiles, with actual metadata population deferred to Sprint 5.
- The `cached_network_image` dependency is correctly deferred to Sprint 5.
- Page transition animations are specified (300ms enter, 200ms exit, fade + slide) in §4.2.

The contract is complete, testable, and ready for implementation.