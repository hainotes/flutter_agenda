import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_agenda/flutter_agenda.dart';
import 'package:flutter_agenda/src/styles/background_painter.dart';
import 'package:flutter_agenda/src/styles/current_time_marker_painter.dart';
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
  EventTime? _tappedHour;
  dynamic _tappedObject;
  Timer? _currentTimeMarkerTimer;
  bool _showHourIndicator = false;
  EventTime? _mouseOverHour;

  @override
  void initState() {
    super.initState();
    if (widget.agendaStyle.visibleCurrentTimeMarker) {
      _currentTimeMarkerTimer = Timer.periodic(Duration(seconds: 60), (timer) {
        _currentTimeMarkerNotifier.value += 1;
      });
    }
  }

  @override
  void dispose() {
    if (_currentTimeMarkerTimer != null) {
      _currentTimeMarkerTimer!.cancel();
    }
    _currentTimeMarkerNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<List<AgendaEvent>> eventCols = [];
    final events = widget.events.toList();
    events.sort((a, b) {
      int result = a.start.compareTo(b.start);
      if (result == 0) {
        result = a.end.compareTo(b.end);
      }
      return result;
    });
    for (final event in events) {
      bool added = false;
      for (final col in eventCols) {
        if (col.isNotEmpty) {
          final lastEvent = col.last;
          if (event.start.compareTo(lastEvent.end) >= 0) {
            col.add(event);
            added = true;
            break;
          }
        } else {
          col.add(event);
          added = true;
          break;
        }
      }
      if (!added) {
        eventCols.add([event]);
      }
    }
    final width = widget.width > 0.0
        ? widget.width
        : widget.agendaStyle.fittedWidth
            ? Utils.pillarWidth(
                context,
                widget.length,
                widget.agendaStyle.timeItemWidth,
                widget.agendaStyle.pillarWidth,
                MediaQuery.of(context).orientation,
              )
            : widget.agendaStyle.pillarWidth;
    for (int colIndex = 0; colIndex < eventCols.length; colIndex++) {
      final col = eventCols[colIndex];
      final eventWidth = width / eventCols.length;
      final eventLeft = colIndex * eventWidth;
      for (final e in col) {
        e.left = eventLeft;
        e.width = eventWidth;
        // Extend width if there are no overlapping events in next columns
        for (int nextColIndex = colIndex + 1; nextColIndex < eventCols.length; nextColIndex++) {
          final nextCol = eventCols[colIndex + 1];
          if (nextCol.every((nextEvent) => nextEvent.start.compareTo(e.end) >= 0 || nextEvent.end.compareTo(e.start) <= 0)) {
            e.width += eventWidth;
          }
        }
      }
    }
    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: ClampingScrollPhysics(),
      child: MouseRegion(
        onEnter: (event) => setState(() {
          _showHourIndicator = true;
          _mouseOverHour = tappedHour(
            event.localPosition.dy,
            widget.agendaStyle.timeSlot.height,
            widget.agendaStyle.startHour,
          );
        }),
        onExit: (event) => setState(() {
          _showHourIndicator = false;
          _mouseOverHour = null;
        }),
        onHover: (event) {
          final mouseOverHour = tappedHour(
            event.localPosition.dy,
            widget.agendaStyle.timeSlot.height,
            widget.agendaStyle.startHour,
          );
          if (_mouseOverHour == null || mouseOverHour.hour != _mouseOverHour!.hour || mouseOverHour.minute != _mouseOverHour!.minute) {
            setState(() => _mouseOverHour = mouseOverHour);
          }
        },
        child: GestureDetector(
          onTapDown: (tapdetails) {
            _tappedHour = tappedHour(tapdetails.localPosition.dy, widget.agendaStyle.timeSlot.height, widget.agendaStyle.startHour);
            _tappedObject = widget.headObject;
          },
          onTap: () {
            if (_tappedHour != null) {
              widget.callBack?.call(_tappedHour!, _tappedObject);
            }
          },
          onDoubleTapDown: (details) {
            _tappedHour = tappedHour(details.localPosition.dy, widget.agendaStyle.timeSlot.height, widget.agendaStyle.startHour);
            _tappedObject = widget.headObject;
          },
          onDoubleTap: () {
            if (_tappedHour != null) {
              widget.doubleCallBack?.call(_tappedHour!, _tappedObject);
            }
          },
          onLongPressDown: (details) {
            _tappedHour = tappedHour(details.localPosition.dy, widget.agendaStyle.timeSlot.height, widget.agendaStyle.startHour);
            _tappedObject = widget.headObject;
          },
          onLongPress: () {
            if (_tappedHour != null) {
              widget.longCallBack?.call(_tappedHour!, _tappedObject);
            }
          },
          child: Container(
            height: height(),
            width: widget.width > 0.0
                ? widget.width
                : widget.agendaStyle.fittedWidth
                    ? Utils.pillarWidth(
                        context, widget.length, widget.agendaStyle.timeItemWidth, widget.agendaStyle.pillarWidth, MediaQuery.of(context).orientation)
                    : widget.agendaStyle.pillarWidth,
            decoration:
                widget.agendaStyle.pillarSeperator ? BoxDecoration(border: Border(left: BorderSide(color: Color(0xFFCECECE)))) : BoxDecoration(),
            child: Stack(
              children: [
                ...[
                  Positioned.fill(
                    child: CustomPaint(
                      painter: BackgroundPainter(
                        agendaStyle: widget.agendaStyle,
                        context: context,
                        showHourIndicator: _showHourIndicator && widget.headObject != null,
                        mouseOverHourCallback: () => _mouseOverHour,
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
                  return EventView(
                    event: event,
                    length: widget.length,
                    agendaStyle: widget.agendaStyle,
                    width: widget.width,
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  EventTime tappedHour(double tapPosition, double itemHeight, int startHour) {
    double hourCount = (tapPosition / itemHeight);
    int hour = (startHour + hourCount.floor());
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
    return (widget.agendaStyle.endHour - widget.agendaStyle.startHour) * widget.agendaStyle.timeSlot.height;
  }
}
