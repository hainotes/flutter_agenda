import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_agenda/src/models/time_slot.dart';
import 'package:flutter_agenda/src/styles/agenda_style.dart';

class BackgroundPainter extends CustomPainter {
  final AgendaStyle agendaStyle;
  DateTime? _currentMarkerTime;

  BackgroundPainter({
    required this.agendaStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = agendaStyle.mainBackgroundColor,
    );
    final totalHours = agendaStyle.endHour - agendaStyle.startHour;
    if (agendaStyle.visibleTimeBorder) {
      for (int hour = 1; hour < totalHours; hour++) {
        double topOffset = calculateTopOffset(hour);
        canvas.drawLine(
          Offset(0, topOffset),
          Offset(size.width, topOffset),
          Paint()..color = agendaStyle.timelineBorderColor,
        );
      }
    }

    if (agendaStyle.visibleDecorationBorder) {
      final height = min(size.height, totalHours * agendaStyle.timeSlot.height);
      final drawLimit = height / agendaStyle.decorationLineHeight;
      for (double count = 0; count < drawLimit; count += 1) {
        double topOffset = calculateDecorationLineOffset(count);
        final paint = Paint()..color = agendaStyle.decorationLineBorderColor;
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

    if (agendaStyle.visibleCurrentTimeMarker) {
      final totalSeconds = totalHours * 3600;
      _currentMarkerTime = DateTime.now();
      final nowSeconds =
          ((_currentMarkerTime!.hour - agendaStyle.startHour) * 3600) +
              (_currentMarkerTime!.minute * 60);
      double topOffset = size.height * (nowSeconds / totalSeconds);
      final paint = Paint()
        ..color = Colors.redAccent
        ..strokeWidth = 2.0;
      canvas.drawCircle(
        Offset(0, topOffset),
        4.0,
        paint,
      );
      canvas.drawLine(
        Offset(0, topOffset),
        Offset(size.width, topOffset),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDayViewBackgroundPainter) {
    return (agendaStyle.mainBackgroundColor !=
                oldDayViewBackgroundPainter.agendaStyle.mainBackgroundColor ||
            agendaStyle.timelineBorderColor !=
                oldDayViewBackgroundPainter.agendaStyle.timelineBorderColor) ||
        (_currentMarkerTime != null &&
            DateTime.now().difference(_currentMarkerTime!) >=
                (const Duration(minutes: 1)));
  }

  double calculateTopOffset(int hour) => hour * agendaStyle.timeSlot.height;

  double calculateDecorationLineOffset(double count) =>
      count * agendaStyle.decorationLineHeight;
}
