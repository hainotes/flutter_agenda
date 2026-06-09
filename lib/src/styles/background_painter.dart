import 'package:flutter/material.dart';
import 'package:flutter_agenda/src/models/event_time.dart';
import 'package:flutter_agenda/src/models/time_slot.dart';
import 'package:flutter_agenda/src/styles/agenda_style.dart';
import 'package:flutter_agenda/src/utils/utils.dart';

class BackgroundPainter extends CustomPainter {
  final AgendaStyle agendaStyle;
  final BuildContext context;

  /// Live hover state, read at paint time. The painter repaints when [repaint]
  /// fires, so these always reflect the current pointer position.
  final bool Function() showHourIndicator;
  final EventTime? Function() mouseOverHour;

  BackgroundPainter({
    required this.agendaStyle,
    required this.context,
    required Listenable repaint,
    required this.showHourIndicator,
    required this.mouseOverHour,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final bool showIndicator = showHourIndicator();
    final EventTime? overHour = mouseOverHour();

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = agendaStyle.mainBackgroundColor,
    );
    final totalHours = agendaStyle.endHour - agendaStyle.startHour;
    if (agendaStyle.visibleTimeBorder) {
      final borderPaint = Paint()..color = agendaStyle.timelineBorderColor;
      final Paint? mouseOverPaint = showIndicator
          ? (Paint()
            ..color = Colors.purple.withValues(alpha: 0.2)
            ..style = PaintingStyle.fill)
          : null;
      for (int hour = 0; hour < totalHours; hour++) {
        double topOffset = calculateTopOffset(hour);
        canvas.drawLine(
          Offset(0, topOffset),
          Offset(size.width, topOffset),
          borderPaint,
        );
        if (showIndicator) {
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
          if (overHour != null &&
              overHour.hour == hour + agendaStyle.startHour) {
            double minuteOffset = 0;
            if (overHour.minute > 0) {
              switch (agendaStyle.timeSlot) {
                case TimeSlot.quarter:
                  minuteOffset =
                      (overHour.minute / 15) * agendaStyle.decorationLineHeight;
                  break;
                default:
                  if (overHour.minute >= 30) {
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
            if (minuteOffset > 0) {
              final mouseOverHourText = TextSpan(
                text: Utils.hourFormatter(
                  overHour.hour,
                  agendaStyle.timeSlot == TimeSlot.quarter
                      ? overHour.minute
                      : 30,
                  context,
                ),
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              );
              final mouseOverHourTextPainter = TextPainter(
                text: mouseOverHourText,
                textDirection: TextDirection.ltr,
              );
              mouseOverHourTextPainter.layout(
                minWidth: 0,
                maxWidth: size.width,
              );
              mouseOverHourTextPainter.paint(
                canvas,
                Offset(
                  (size.width - textPainter.width) / 2,
                  topOffset + minuteOffset,
                ),
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
  bool shouldRepaint(covariant BackgroundPainter old) {
    return agendaStyle.mainBackgroundColor !=
            old.agendaStyle.mainBackgroundColor ||
        agendaStyle.timelineBorderColor !=
            old.agendaStyle.timelineBorderColor ||
        showHourIndicator() != old.showHourIndicator() ||
        mouseOverHour() != old.mouseOverHour();
  }

  double calculateTopOffset(int hour) => hour * agendaStyle.timeSlot.height;

  double calculateDecorationLineOffset(double count) =>
      count * agendaStyle.decorationLineHeight;
}
