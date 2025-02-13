import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_agenda/src/models/agenda_event.dart';
import 'package:flutter_agenda/src/models/time_slot.dart';
import 'package:flutter_agenda/src/styles/agenda_style.dart';
import 'package:flutter_agenda/src/utils/utils.dart';

class EventView extends StatelessWidget {
  final AgendaEvent event;
  final int length;
  final AgendaStyle agendaStyle;
  final double width;

  const EventView({
    Key? key,
    required this.event,
    required this.length,
    required this.agendaStyle,
    this.width = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top(),
      height: height(),
      left: event.left,
      width: event.width,
      child: GestureDetector(
        onTap: event.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(agendaStyle.eventRadius),
          child: Container(
            decoration: event.decoration ??
                (BoxDecoration(
                    color: event.borderColor == event.backgroundColor
                        ? event.backgroundColor.withValues(alpha: 0.4)
                        : event.backgroundColor,
                    border: Border(
                      left: BorderSide(
                          color: event.borderColor,
                          width: agendaStyle.eventBorderWidth),
                      bottom: BorderSide(color: Color(0xFFBCBCBC)),
                    ))),
            padding: event.padding,
            margin: event.margin,
            child: event.builder != null
                ? event.builder!(
                    event,
                    context,
                    math.max(
                        0.0,
                        height() -
                            (event.padding.top) -
                            (event.padding.bottom)),
                    math.max(
                        0.0,
                        agendaStyle.pillarWidth -
                            (event.padding.left) -
                            (event.padding.right)),
                  )
                : (Utils.eventText)(
                    event,
                    context,
                    math.max(
                        0.0,
                        height() -
                            (event.padding.top) -
                            (event.padding.bottom)),
                    math.max(
                        0.0,
                        agendaStyle.pillarWidth -
                            (event.padding.left) -
                            (event.padding.right)),
                  ),
          ),
        ),
      ),
    );
  }

  double top() {
    return calculateTopOffset(
            event.start.hour, event.start.minute, agendaStyle.timeSlot.height) -
        agendaStyle.startHour * agendaStyle.timeSlot.height;
  }

  double height() {
    return calculateTopOffset(0, event.end.difference(event.start).inMinutes,
            agendaStyle.timeSlot.height) +
        1;
  }

  double calculateTopOffset(
    int hour, [
    int minute = 0,
    double? hourRowHeight,
  ]) {
    return (hour + (minute / 60)) * (hourRowHeight ?? 60);
  }
}
