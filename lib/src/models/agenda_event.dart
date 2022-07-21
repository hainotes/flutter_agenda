import 'package:flutter/material.dart';
import 'package:flutter_agenda/src/models/event_time.dart';

class AgendaEvent {
  static const defaultTextStyle = const TextStyle(
      color: Color(0xFF535353), fontSize: 11, fontWeight: FontWeight.w400);

  static const defaultSubtitleStyle =
      const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF363636));

  final String title;

  final String subtitle;

  final EventTime start;

  final EventTime end;

  final EdgeInsets padding;

  final EdgeInsets? margin;

  final VoidCallback? onTap;

  final BoxDecoration? decoration;

  final Color backgroundColor;

  final TextStyle textStyle;

  final TextStyle subtitleStyle;

  final Widget Function(
          AgendaEvent event, BuildContext context, double height, double width)?
      builder;

  AgendaEvent({
    required this.title,
    this.subtitle: "",
    required this.start,
    required this.end,
    this.padding: const EdgeInsets.all(10),
    this.margin,
    this.onTap,
    this.decoration,
    this.backgroundColor: const Color(0xFF323D6C),
    this.textStyle: defaultTextStyle,
    this.subtitleStyle: defaultSubtitleStyle,
    this.builder,
  }) : assert(end.isAfter(start));
}
