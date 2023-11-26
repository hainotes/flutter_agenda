import 'package:flutter/material.dart';
import 'package:flutter_agenda/src/styles/agenda_style.dart';

class CurrentTimeMarkerPainter extends CustomPainter {
  final AgendaStyle agendaStyle;

  CurrentTimeMarkerPainter({
    required this.agendaStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (agendaStyle.visibleCurrentTimeMarker) {
      final totalHours = agendaStyle.endHour - agendaStyle.startHour;
      final totalSeconds = totalHours * 3600;
      final now = DateTime.now();
      final nowSeconds =
          ((now.hour - agendaStyle.startHour) * 3600) + (now.minute * 60);
      final topOffset = size.height * (nowSeconds / totalSeconds);
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
  bool shouldRepaint(CurrentTimeMarkerPainter oldDayViewBackgroundPainter) {
    return true;
  }
}
