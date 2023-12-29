import 'package:flutter/material.dart';
import 'package:flutter_agenda/src/models/event_time.dart';
import 'package:flutter_agenda/src/models/time_slot.dart';
import 'package:flutter_agenda/src/styles/agenda_style.dart';
import 'package:flutter_agenda/src/utils/utils.dart';

class BackgroundPainter extends CustomPainter {
  final AgendaStyle agendaStyle;
  final BuildContext context;
  final bool showHourIndicator;
  final EventTime? Function()? mouseOverHourCallback;

  BackgroundPainter({
    required this.agendaStyle,
    required this.context,
    this.showHourIndicator = false,
    this.mouseOverHourCallback,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = agendaStyle.mainBackgroundColor,
    );
    final totalHours = agendaStyle.endHour - agendaStyle.startHour;
    if (agendaStyle.visibleTimeBorder) {
      final borderPaint = Paint()..color = agendaStyle.timelineBorderColor;
      Paint? mouseOverPaint;
      if (showHourIndicator && mouseOverHourCallback != null) {
        mouseOverPaint = Paint()
          ..color = Colors.purple.withOpacity(0.2)
          ..style = PaintingStyle.fill;
      } else {
        mouseOverPaint = null;
      }
      for (int hour = 0; hour < totalHours; hour++) {
        double topOffset = calculateTopOffset(hour);
        canvas.drawLine(
          Offset(0, topOffset),
          Offset(size.width, topOffset),
          borderPaint,
        );
        if (showHourIndicator) {
          final hourText = TextSpan(
            text: Utils.hourFormatter(
              hour + agendaStyle.startHour,
              0,
              context,
            ),
            style: TextStyle(
              color: Colors.black45,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          );
          final textPainter = TextPainter(
            text: hourText,
            textDirection: TextDirection.ltr,
          );
          textPainter.layout(
            minWidth: 0,
            maxWidth: size.width,
          );
          textPainter.paint(
            canvas,
            Offset((size.width - textPainter.width) / 2, topOffset),
          );
          if (mouseOverHourCallback != null) {
            final mouseOverHour = mouseOverHourCallback!();
            if (mouseOverHour != null &&
                mouseOverHour.hour == hour + agendaStyle.startHour) {
              double minuteOffset = 0;
              if (mouseOverHour.minute > 0) {
                switch (agendaStyle.timeSlot) {
                  case TimeSlot.quarter:
                    minuteOffset = (mouseOverHour.minute / 15) *
                        agendaStyle.decorationLineHeight;
                    break;
                  default:
                    if (mouseOverHour.minute >= 30) {
                      minuteOffset = agendaStyle.decorationLineHeight;
                    }
                    break;
                }
              }
              canvas.drawRect(
                Rect.fromLTWH(
                  0,
                  topOffset + minuteOffset,
                  size.width,
                  agendaStyle.decorationLineHeight,
                ),
                mouseOverPaint!,
              );
            }
          }
        }
      }
    }

    if (agendaStyle.visibleDecorationBorder) {
      final drawLimit = size.height / agendaStyle.decorationLineHeight;
      final paint = Paint()..color = agendaStyle.decorationLineBorderColor;
      for (double count = 0; count < drawLimit; count += 1) {
        double topOffset = calculateDecorationLineOffset(count);
        final dashWidth = agendaStyle.decorationLineDashWidth;
        final dashSpace = agendaStyle.decorationLineDashSpaceWidth;
        var startX = 0.0;
        while (startX < size.width) {
          canvas.drawLine(
            Offset(startX, topOffset),
            Offset(startX + agendaStyle.decorationLineDashWidth, topOffset),
            paint,
          );
          startX += dashWidth + dashSpace;
        }
      }
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDayViewBackgroundPainter) {
    return (agendaStyle.mainBackgroundColor !=
            oldDayViewBackgroundPainter.agendaStyle.mainBackgroundColor ||
        agendaStyle.timelineBorderColor !=
            oldDayViewBackgroundPainter.agendaStyle.timelineBorderColor);
  }

  double calculateTopOffset(int hour) => hour * agendaStyle.timeSlot.height;

  double calculateDecorationLineOffset(double count) =>
      count * agendaStyle.decorationLineHeight;
}
