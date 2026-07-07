import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_agenda/flutter_agenda.dart';
import 'package:flutter_agenda/src/styles/background_painter.dart';
import 'package:flutter_agenda/src/styles/current_time_marker_painter.dart';
import 'package:flutter_agenda/src/utils/scroll_config.dart';
import 'package:flutter_agenda/src/utils/utils.dart';
import 'package:flutter_agenda/src/views/event_view.dart';

class PillarView extends StatefulWidget {
  final dynamic headObject;
  final List<AgendaEvent> events;
  final int length;
  final ScrollController scrollController;
  final AgendaStyle agendaStyle;
  final Function(EventTime, dynamic)? callBack;
  final Function(EventTime, dynamic)? longCallBack;
  final Function(EventTime, dynamic)? doubleCallBack;
  final double width;

  PillarView({
    Key? key,
    required this.headObject,
    required this.events,
    required this.length,
    required this.scrollController,
    required this.agendaStyle,
    this.callBack,
    this.doubleCallBack,
    this.longCallBack,
    this.width = 0.0,
  }) : super(key: key);

  @override
  State<PillarView> createState() => _PillarViewState();
}

class _PillarViewState extends State<PillarView> {
  final ValueNotifier<int> _currentTimeMarkerNotifier = ValueNotifier<int>(0);

  // Hover state is kept in notifiers (not setState) so moving the mouse only
  // repaints the background layer instead of rebuilding the whole pillar and
  // re-running the O(n^2) event layout pass on every pointer move.
  final ValueNotifier<bool> _showHourIndicator = ValueNotifier<bool>(false);
  final ValueNotifier<EventTime?> _mouseOverHour =
      ValueNotifier<EventTime?>(null);
  late final Listenable _backgroundRepaint =
      Listenable.merge([_showHourIndicator, _mouseOverHour]);

  EventTime? _tappedHour;
  dynamic _tappedObject;
  Timer? _currentTimeMarkerTimer;

  // Memoized event-column layout. The expensive packing pass only runs when
  // the event list changes (length or element instances); hover / repaints
  // reuse the cached result. [_cachedFor] is a snapshot copy so in-place
  // mutations of the caller's list are detected too.
  List<List<AgendaEvent>>? _cachedCols;
  List<List<int>>? _cachedSpans;
  List<AgendaEvent>? _cachedFor;

  @override
  void initState() {
    super.initState();
    _syncCurrentTimeMarkerTimer();
  }

  @override
  void didUpdateWidget(covariant PillarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agendaStyle.visibleCurrentTimeMarker !=
        widget.agendaStyle.visibleCurrentTimeMarker) {
      _syncCurrentTimeMarkerTimer();
    }
  }

  void _syncCurrentTimeMarkerTimer() {
    if (widget.agendaStyle.visibleCurrentTimeMarker) {
      _currentTimeMarkerTimer ??=
          Timer.periodic(Duration(seconds: 60), (timer) {
        _currentTimeMarkerNotifier.value += 1;
      });
    } else {
      _currentTimeMarkerTimer?.cancel();
      _currentTimeMarkerTimer = null;
    }
  }

  @override
  void dispose() {
    _currentTimeMarkerTimer?.cancel();
    _currentTimeMarkerNotifier.dispose();
    _showHourIndicator.dispose();
    _mouseOverHour.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = _resolveWidth(context);
    final geometry = _computeGeometry(width);
    return ScrollConfiguration(
      behavior: const NoGlowScroll(),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: ClampingScrollPhysics(),
        child: MouseRegion(
          onEnter: (event) {
            _showHourIndicator.value = true;
            _mouseOverHour.value = tappedHour(
              event.localPosition.dy,
              widget.agendaStyle.timeSlot.height,
              widget.agendaStyle.startHour,
            );
          },
          onExit: (event) {
            _showHourIndicator.value = false;
            _mouseOverHour.value = null;
          },
          onHover: (event) {
            final hovered = tappedHour(
              event.localPosition.dy,
              widget.agendaStyle.timeSlot.height,
              widget.agendaStyle.startHour,
            );
            final current = _mouseOverHour.value;
            if (current == null ||
                hovered.hour != current.hour ||
                hovered.minute != current.minute) {
              _mouseOverHour.value = hovered;
            }
          },
          child: GestureDetector(
            onTapDown: (tapdetails) {
              _tappedHour = tappedHour(
                  tapdetails.localPosition.dy,
                  widget.agendaStyle.timeSlot.height,
                  widget.agendaStyle.startHour);
              _tappedObject = widget.headObject;
            },
            onTap: () {
              if (_tappedHour != null) {
                widget.callBack?.call(_tappedHour!, _tappedObject);
              }
            },
            onDoubleTapDown: (details) {
              _tappedHour = tappedHour(
                  details.localPosition.dy,
                  widget.agendaStyle.timeSlot.height,
                  widget.agendaStyle.startHour);
              _tappedObject = widget.headObject;
            },
            onDoubleTap: () {
              if (_tappedHour != null) {
                widget.doubleCallBack?.call(_tappedHour!, _tappedObject);
              }
            },
            onLongPressDown: (details) {
              _tappedHour = tappedHour(
                  details.localPosition.dy,
                  widget.agendaStyle.timeSlot.height,
                  widget.agendaStyle.startHour);
              _tappedObject = widget.headObject;
            },
            onLongPress: () {
              if (_tappedHour != null) {
                widget.longCallBack?.call(_tappedHour!, _tappedObject);
              }
            },
            child: Container(
              height: height(),
              width: width,
              decoration: widget.agendaStyle.pillarSeperator
                  ? BoxDecoration(
                      border:
                          Border(left: BorderSide(color: Color(0xFFCECECE))))
                  : BoxDecoration(),
              child: Stack(
                children: [
                  ...[
                    Positioned.fill(
                      child: CustomPaint(
                        painter: BackgroundPainter(
                          agendaStyle: widget.agendaStyle,
                          context: context,
                          repaint: _backgroundRepaint,
                          showHourIndicator: () =>
                              _showHourIndicator.value &&
                              widget.headObject != null,
                          mouseOverHour: () => _mouseOverHour.value,
                        ),
                      ),
                    ),
                    if (widget.headObject != null)
                      ValueListenableBuilder(
                        valueListenable: _currentTimeMarkerNotifier,
                        builder: (context, value, child) {
                          return Positioned.fill(
                            child: CustomPaint(
                              painter: CurrentTimeMarkerPainter(
                                agendaStyle: widget.agendaStyle,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                  ...widget.events.map((event) {
                    final g = geometry[event];
                    return EventView(
                      event: event,
                      length: widget.length,
                      agendaStyle: widget.agendaStyle,
                      left: g?.left ?? 0.0,
                      width: g?.width ?? 0.0,
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _resolveWidth(BuildContext context) {
    if (widget.width > 0.0) {
      return widget.width;
    }
    if (widget.agendaStyle.fittedWidth) {
      return Utils.pillarWidth(
        context,
        widget.length,
        widget.agendaStyle.timeItemWidth,
        widget.agendaStyle.pillarWidth,
        MediaQuery.of(context).orientation,
      );
    }
    return widget.agendaStyle.pillarWidth;
  }

  /// Whether the cached layout snapshot still matches the current event list.
  /// Compares length and element identity, so both replacing the list and
  /// mutating it in place (add/remove/replace) invalidate the cache.
  bool _cacheIsFresh() {
    final cached = _cachedFor;
    if (cached == null || _cachedCols == null) {
      return false;
    }
    if (cached.length != widget.events.length) {
      return false;
    }
    for (int i = 0; i < cached.length; i++) {
      if (!identical(cached[i], widget.events[i])) {
        return false;
      }
    }
    return true;
  }

  /// Packs events into non-overlapping columns and, for each event, computes
  /// how many subsequent columns it can safely span into. Cached against a
  /// snapshot of [widget.events].
  void _ensureColumns() {
    if (_cacheIsFresh()) {
      return;
    }
    final events = widget.events.toList();
    events.sort((a, b) {
      int result = a.start.compareTo(b.start);
      if (result == 0) {
        result = a.end.compareTo(b.end);
      }
      return result;
    });

    final List<List<AgendaEvent>> eventCols = [];
    for (final event in events) {
      bool added = false;
      for (final col in eventCols) {
        if (col.isEmpty || event.start.compareTo(col.last.end) >= 0) {
          col.add(event);
          added = true;
          break;
        }
      }
      if (!added) {
        eventCols.add([event]);
      }
    }

    final List<List<int>> spans = [];
    for (int colIndex = 0; colIndex < eventCols.length; colIndex++) {
      final col = eventCols[colIndex];
      final colSpans = <int>[];
      for (final e in col) {
        int span = 0;
        // Extend across later columns only while every later column is free of
        // overlap; stop at the first column that actually overlaps this event.
        for (int nextColIndex = colIndex + 1;
            nextColIndex < eventCols.length;
            nextColIndex++) {
          final nextCol = eventCols[nextColIndex];
          final noOverlap = nextCol.every((nextEvent) =>
              nextEvent.start.compareTo(e.end) >= 0 ||
              nextEvent.end.compareTo(e.start) <= 0);
          if (!noOverlap) {
            break;
          }
          span++;
        }
        colSpans.add(span);
      }
      spans.add(colSpans);
    }

    _cachedCols = eventCols;
    _cachedSpans = spans;
    // Snapshot copy: detects in-place mutation of the caller's list.
    _cachedFor = List<AgendaEvent>.of(widget.events);
  }

  /// Resolves the per-event pixel geometry for the given pillar [width] from the
  /// memoized column layout. O(events); no model mutation.
  Map<AgendaEvent, ({double left, double width})> _computeGeometry(
      double width) {
    _ensureColumns();
    final geometry = <AgendaEvent, ({double left, double width})>{};
    final cols = _cachedCols!;
    final spans = _cachedSpans!;
    if (cols.isEmpty) {
      return geometry;
    }
    final eventWidth = width / cols.length;
    for (int colIndex = 0; colIndex < cols.length; colIndex++) {
      final col = cols[colIndex];
      final colSpans = spans[colIndex];
      final left = colIndex * eventWidth;
      for (int i = 0; i < col.length; i++) {
        geometry[col[i]] = (left: left, width: eventWidth * (1 + colSpans[i]));
      }
    }
    return geometry;
  }

  EventTime tappedHour(double tapPosition, double itemHeight, int startHour) {
    double hourCount = (tapPosition / itemHeight);
    int hour = startHour + hourCount.floor();
    if (hour < 0) {
      hour = 0;
    } else if (hour > 23) {
      hour = 23;
    }
    double minuteCount = hourCount - hourCount.floor();
    int minute;
    if (minuteCount >= 0.75) {
      minute = 45;
    } else if (minuteCount >= 0.5) {
      minute = 30;
    } else if (minuteCount >= 0.25) {
      minute = 15;
    } else {
      minute = 0;
    }
    return EventTime(hour: hour, minute: minute);
  }

  double height() {
    return (widget.agendaStyle.endHour - widget.agendaStyle.startHour) *
        widget.agendaStyle.timeSlot.height;
  }
}
