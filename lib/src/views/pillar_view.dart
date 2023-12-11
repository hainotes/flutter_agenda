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
  final double width;

  PillarView({
    Key? key,
    required this.headObject,
    required this.events,
    required this.length,
    required this.scrollController,
    required this.agendaStyle,
    this.callBack,
    this.longCallBack,
    this.width = 0.0,
  }) : super(key: key);

  @override
  State<PillarView> createState() => _PillarViewState();
}

class _PillarViewState extends State<PillarView> {
  int _tapDownTime = 0;
  EventTime? _tappedHour;
  dynamic _tappedObject;
  Timer? _currentTimeMarkerTimer;
  final ValueNotifier<int> _currentTimeMarkerNotifier = ValueNotifier<int>(0);

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
    final List<List<AgendaEvent>> eventColumns = [];
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
      for (final column in eventColumns) {
        if (column.isEmpty) {
          column.add(event);
          added = true;
          break;
        } else {
          final lastEvent = column.last;
          if (lastEvent.end.isBefore(event.start) ||
              lastEvent.end.isAtSameMomentAs(event.start)) {
            column.add(event);
            added = true;
            break;
          }
        }
      }
      if (!added) {
        eventColumns.add([event]);
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
                MediaQuery.of(context).orientation)
            : widget.agendaStyle.pillarWidth;
    for (int colIndex = 0; colIndex < eventColumns.length; colIndex++) {
      final columnWidth = width / eventColumns.length;
      final column = eventColumns[colIndex];
      for (final event in column) {
        event.width = columnWidth;
        event.left = event.width * colIndex;
        if (colIndex < (eventColumns.length - 1)) {
          for (int nextColIndex = colIndex + 1;
              nextColIndex < eventColumns.length;
              nextColIndex++) {
            bool overlap = false;
            final nextColumn = eventColumns[nextColIndex];
            for (final nextEvent in nextColumn) {
              // Find overlap between event and nextEvent
              if (event.start.isAtSameMomentAs(nextEvent.start) ||
                  (event.start.isBefore(nextEvent.start) &&
                      event.end.isAfter(nextEvent.end)) ||
                  (event.start.isAfter(nextEvent.start) &&
                      event.start.isBefore(nextEvent.end)) ||
                  (event.end.isAfter(nextEvent.start) &&
                      event.end.isBefore(nextEvent.end)) ||
                  event.end.isAtSameMomentAs(nextEvent.end)) {
                overlap = true;
                break;
              }
            }
            if (overlap) {
              break;
            }
            event.width += columnWidth;
          }
        }
      }
    }
    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: ClampingScrollPhysics(),
      child: GestureDetector(
        onTapDown: (tapdetails) {
          _tappedHour = tappedHour(tapdetails.localPosition.dy,
              widget.agendaStyle.timeSlot.height, widget.agendaStyle.startHour);
          _tappedObject = widget.headObject;
          _tapDownTime = DateTime.now().millisecondsSinceEpoch;
        },
        onTap: () {
          if (DateTime.now().millisecondsSinceEpoch - _tapDownTime < 250) {
            widget.callBack?.call(_tappedHour!, _tappedObject);
          }
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
                      context,
                      widget.length,
                      widget.agendaStyle.timeItemWidth,
                      widget.agendaStyle.pillarWidth,
                      MediaQuery.of(context).orientation)
                  : widget.agendaStyle.pillarWidth,
          decoration: widget.agendaStyle.pillarSeperator
              ? BoxDecoration(
                  border: Border(left: BorderSide(color: Color(0xFFCECECE))))
              : BoxDecoration(),
          child: Stack(
            children: [
              ...[
                Positioned.fill(
                  child: CustomPaint(
                    painter: BackgroundPainter(
                      agendaStyle: widget.agendaStyle,
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
    return (widget.agendaStyle.endHour - widget.agendaStyle.startHour) *
        widget.agendaStyle.timeSlot.height;
  }
}
