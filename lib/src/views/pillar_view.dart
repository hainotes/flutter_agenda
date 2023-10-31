import 'package:flutter/material.dart';
import 'package:flutter_agenda/flutter_agenda.dart';
import 'package:flutter_agenda/src/styles/background_painter.dart';
import 'package:flutter_agenda/src/utils/utils.dart';
import 'package:flutter_agenda/src/views/event_view.dart';

class PillarView extends StatelessWidget {
  final dynamic headObject;
  final List<AgendaEvent> events;
  final int length;
  final ScrollController scrollController;
  final AgendaStyle agendaStyle;
  final Function(EventTime, dynamic)? callBack;
  final double width;

  PillarView({
    Key? key,
    required this.headObject,
    required this.events,
    required this.length,
    required this.scrollController,
    required this.agendaStyle,
    this.callBack,
    this.width = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      physics: ClampingScrollPhysics(),
      child: GestureDetector(
        onTapDown: (tapdetails) => callBack!(
            tappedHour(tapdetails.localPosition.dy, agendaStyle.timeSlot.height,
                agendaStyle.startHour),
            headObject),
        child: Container(
          height: height(),
          width: width > 0.0
              ? width
              : agendaStyle.fittedWidth
                  ? Utils.pillarWidth(
                      context,
                      length,
                      agendaStyle.timeItemWidth,
                      agendaStyle.pillarWidth,
                      MediaQuery.of(context).orientation)
                  : agendaStyle.pillarWidth,
          decoration: agendaStyle.pillarSeperator
              ? BoxDecoration(
                  border: Border(left: BorderSide(color: Color(0xFFCECECE))))
              : BoxDecoration(),
          child: Stack(
            children: [
              ...[
                Positioned.fill(
                  child: CustomPaint(
                    painter: BackgroundPainter(
                      agendaStyle: agendaStyle,
                    ),
                  ),
                )
              ],
              ...events.map((event) {
                return EventView(
                  event: event,
                  length: length,
                  agendaStyle: agendaStyle,
                  width: width,
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
    return (agendaStyle.endHour - agendaStyle.startHour) *
        agendaStyle.timeSlot.height;
  }
}
