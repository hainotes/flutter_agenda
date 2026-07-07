import 'package:flutter/material.dart';

/// Scroll behavior for the agenda's internal scrollables: no scrollbars and
/// no overscroll glow. The agenda draws its own chrome (timeline, headers,
/// current-time marker), so per-scrollable scrollbars would only add noise —
/// one per pillar on desktop/web.
class NoGlowScroll extends ScrollBehavior {
  const NoGlowScroll();

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
