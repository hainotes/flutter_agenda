import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_agenda/flutter_agenda.dart';
import 'package:flutter_agenda/src/controllers/scroll_linker.dart';
import 'package:flutter_agenda/src/utils/scroll_config.dart';
import 'package:flutter_agenda/src/utils/utils.dart';
import 'package:flutter_agenda/src/extensions/expand_equally.dart';
import 'package:flutter_agenda/src/extensions/separator.dart';
import 'package:flutter_agenda/src/views/pillar_view.dart';

class FlutterAgenda extends StatefulWidget {
  /// Agenda visualization only one required parameter [pillarsList].
  FlutterAgenda({
    Key? key,
    required this.resources,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.agendaStyle = const AgendaStyle(),
  }) : super(key: key);

  /// list of pillar Object:
  ///
  /// [head] employee/resource.
  ///
  /// [events] (appointments/Todos) linked to the head.
  final List<Resource> resources;

  /// longpress callback in an empty space in the calendar.
  ///
  /// gives the exact Clicked [eventTime].
  ///
  /// the dynamic object is the object you passed to the head object.
  /// it could be one of your won project custom resource object.
  final Function(EventTime, dynamic)? onTap;

  final Function(EventTime, dynamic)? onDoubleTap;

  final Function(EventTime, dynamic)? onLongPress;

  /// if you want to customize the view more
  final AgendaStyle agendaStyle;

  @override
  _FlutterAgendaState createState() => _FlutterAgendaState();
}

class _FlutterAgendaState extends State<FlutterAgenda> {
  // scroll linkers
  late ScrollLinker _horizontalScrollLinker;
  late ScrollLinker _verticalScrollLinker;
  // vertical scroll controllers
  List<ScrollController> _verticalScrollControllers = <ScrollController>[];
  // horizontal (header, body) scroll controllers
  late ScrollController _headerScrollController;
  late ScrollController _bodyScrollController;
  Timer? _autoScrollTimer;
  double _clientHeight = 0.0;

  @override
  void initState() {
    super.initState();
    // init scroll linkers
    _verticalScrollLinker = ScrollLinker();
    _horizontalScrollLinker = ScrollLinker();

    // sychronize the scroll of the vertical scrollers
    _headerScrollController = _horizontalScrollLinker.addAndGet();
    _bodyScrollController = _horizontalScrollLinker.addAndGet();

    // sychronize the scroll of the horizontal scrollers
    _verticalScrollControllers.add(_verticalScrollLinker.addAndGet());
    for (int i = 0; i < widget.resources.length; i++) {
      _verticalScrollControllers.add(_verticalScrollLinker.addAndGet());
    }
    _syncAutoScrollTimer();
  }

  void _syncAutoScrollTimer() {
    if (widget.agendaStyle.autoScrollToCurrentTime) {
      _autoScrollTimer ??= Timer.periodic(Duration(minutes: 1), (timer) {
        _scrollToCurrentTime();
      });
    } else {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.agendaStyle.autoScrollToCurrentTime) {
      final height = MediaQuery.of(context).size.height;
      if (_clientHeight != height) {
        _clientHeight = height;
        // Scroll after the pending frame so the scrollables are laid out and
        // attached before jumping.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scrollToCurrentTime();
        });
      }
    }
  }

  @override
  void dispose() {
    if (_autoScrollTimer != null) {
      _autoScrollTimer!.cancel();
    }
    // disposing the vetical scrollers
    for (var i = 0; i < _verticalScrollControllers.length; i++) {
      _verticalScrollControllers[i].dispose();
    }
    // clearing the vertical scrollers list
    _verticalScrollControllers.clear();
    // disposing the horizontal scrollers
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FlutterAgenda oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agendaStyle.autoScrollToCurrentTime !=
        widget.agendaStyle.autoScrollToCurrentTime) {
      _syncAutoScrollTimer();
    }
    if ((widget.resources.length + 1) > _verticalScrollControllers.length) {
      while (_verticalScrollControllers.length < (widget.resources.length + 1)) {
        _verticalScrollControllers.add(_verticalScrollLinker.addAndGet());
      }
    } else if ((widget.resources.length + 1) < _verticalScrollControllers.length) {
      while (_verticalScrollControllers.length > (widget.resources.length + 1)) {
        final controller = _verticalScrollControllers.removeLast();
        // Always dispose: _LinkedScrollController.dispose() also unregisters it
        // from the ScrollLinker. Skipping it when hasClients == false leaks the
        // controller and its offset listener.
        controller.dispose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.agendaStyle.direction,
      child: Stack(
        children: <Widget>[
          _buildMainContent(context),
          _buildTimeLines(context),
          _buildHeaders(context),
          _buildCorner(),
        ],
      ),
    );
  }

  Widget _buildCorner() {
    return Positioned(
      left: widget.agendaStyle.direction == TextDirection.ltr ? 0 : null,
      right: widget.agendaStyle.direction == TextDirection.rtl ? 0 : null,
      top: 0,
      child: SizedBox(
        width: widget.agendaStyle.timeItemWidth + 1,
        height: widget.agendaStyle.headerHeight,
        child: DecoratedBox(
          position: DecorationPosition.background,
          decoration: BoxDecoration(
            color: widget.agendaStyle.cornerColor,
            border: Border(
                right: (!widget.agendaStyle.cornerRight && widget.agendaStyle.direction != TextDirection.rtl)
                    ? BorderSide.none
                    : BorderSide(
                        color: widget.agendaStyle.timelineBorderColor.withValues(alpha: 0.4),
                      ),
                left: (!widget.agendaStyle.cornerRight && widget.agendaStyle.direction != TextDirection.ltr)
                    ? BorderSide.none
                    : BorderSide(
                        color: widget.agendaStyle.timelineBorderColor.withValues(alpha: 0.4),
                      ),
                bottom: !widget.agendaStyle.cornerBottom
                    ? BorderSide.none
                    : BorderSide(
                        color: widget.agendaStyle.timelineBorderColor.withValues(alpha: 0.4),
                      )),
          ),
          child: widget.agendaStyle.cornerBuilder != null ? widget.agendaStyle.cornerBuilder!(context) : null,
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: widget.agendaStyle.direction == TextDirection.ltr ? widget.agendaStyle.timeItemWidth : 0,
        right: widget.agendaStyle.direction == TextDirection.rtl ? widget.agendaStyle.timeItemWidth : 0,
        top: widget.agendaStyle.headerHeight,
      ),
      child: ScrollConfiguration(
        behavior: NoGlowScroll(),
        child: ListView(
          scrollDirection: Axis.horizontal,
          // reverse: widget.agendaStyle.direction == TextDirection.rtl,
          controller: _bodyScrollController,
          children: [
            for (int i = 0; i < widget.resources.length; i++)
              PillarView(
                headObject: widget.resources[i].head.object,
                length: widget.resources.length,
                scrollController: _verticalScrollControllers[i + 1],
                events: widget.resources[i].events,
                callBack: (p0, p1) => widget.onTap?.call(p0, p1),
                doubleCallBack: (p0, p1) => widget.onDoubleTap?.call(p0, p1),
                longCallBack: (p0, p1) => widget.onLongPress?.call(p0, p1),
                agendaStyle: widget.agendaStyle,
                width: widget.resources[i].width,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeLines(BuildContext context) {
    return Container(
      alignment: widget.agendaStyle.direction == TextDirection.rtl ? Alignment.topLeft : Alignment.topRight,
      width: widget.agendaStyle.timeItemWidth + 1,
      padding: EdgeInsets.only(top: widget.agendaStyle.headerHeight),
      decoration: BoxDecoration(
        color: widget.agendaStyle.timelineColor,
        border: Border(
          right: widget.agendaStyle.direction == TextDirection.ltr
              ? BorderSide(color: widget.agendaStyle.timelineBorderColor.withValues(alpha: 0.5))
              : BorderSide.none,
          left: widget.agendaStyle.direction == TextDirection.rtl
              ? BorderSide(color: widget.agendaStyle.timelineBorderColor.withValues(alpha: 0.5))
              : BorderSide.none,
        ),
      ),
      child: ScrollConfiguration(
        behavior: NoGlowScroll(),
        child: ListView(
          controller: _verticalScrollControllers[0],
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          children: [for (var i = widget.agendaStyle.startHour; i < widget.agendaStyle.endHour; i += 1) i].map((hour) {
            return Container(
              height: widget.agendaStyle.timeSlot.height,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: widget.agendaStyle.timelineBorderColor.withValues(alpha: 0.8),
                    width: 0.8,
                  ),
                ),
                color: widget.agendaStyle.timelineItemColor,
              ),
              child: widget.agendaStyle.timeSlot.height == 80 && widget.agendaStyle.timeSlot == TimeSlot.half
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                          child: Text(
                            Utils.hourFormatter(hour, 0, context),
                            style: widget.agendaStyle.timeItemTextStyle
                                .copyWith(color: widget.agendaStyle.timeItemTextColor, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                          child: Text(
                            Utils.hourFormatter(hour, 30, context),
                            style: widget.agendaStyle.timeItemTextStyle.copyWith(color: widget.agendaStyle.timeItemTextColor),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ].expandEqually().seperate(widget.agendaStyle.timelineBorderColor).toList(),
                    )
                  : widget.agendaStyle.timeSlot.height == 160
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                              child: Text(
                                Utils.hourFormatter(hour, 0, context),
                                style: widget.agendaStyle.timeItemTextStyle
                                    .copyWith(color: widget.agendaStyle.timeItemTextColor, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                              child: Text(
                                Utils.minFormatter(15),
                                style: widget.agendaStyle.timeItemTextStyle.copyWith(color: widget.agendaStyle.timeItemTextColor),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                              child: Text(
                                Utils.hourFormatter(hour, 30, context),
                                style: widget.agendaStyle.timeItemTextStyle.copyWith(color: widget.agendaStyle.timeItemTextColor),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                              child: Text(
                                Utils.minFormatter(45),
                                style: widget.agendaStyle.timeItemTextStyle.copyWith(color: widget.agendaStyle.timeItemTextColor),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ].expandEqually().seperate(widget.agendaStyle.timelineBorderColor).toList(),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            Utils.hourFormatter(hour, 0, context),
                            style: widget.agendaStyle.timeItemTextStyle
                                .copyWith(color: widget.agendaStyle.timeItemTextColor, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHeaders(BuildContext context) {
    return Container(
      alignment: widget.agendaStyle.direction == TextDirection.rtl ? Alignment.topRight : Alignment.topLeft,
      decoration: BoxDecoration(
        color: widget.agendaStyle.pillarColor,
        border: !widget.agendaStyle.headBottomBorder
            ? null
            : Border(bottom: BorderSide(color: widget.agendaStyle.timelineBorderColor.withValues(alpha: 0.4))),
      ),
      height: widget.agendaStyle.headerHeight,
      padding: EdgeInsets.only(
          left: widget.agendaStyle.direction == TextDirection.ltr ? widget.agendaStyle.timeItemWidth : 0,
          right: widget.agendaStyle.direction == TextDirection.rtl ? widget.agendaStyle.timeItemWidth : 0),
      child: ScrollConfiguration(
        behavior: NoGlowScroll(),
        child: ListView(
          scrollDirection: Axis.horizontal,
          controller: _headerScrollController,
          shrinkWrap: true,
          children: widget.resources.map((pillar) {
            return GestureDetector(
              onTap: pillar.head.onTap,
              child: Container(
                width: pillar.width > 0.0
                    ? pillar.width
                    : widget.agendaStyle.fittedWidth
                        ? Utils.pillarWidth(context, widget.resources.length, widget.agendaStyle.timeItemWidth, widget.agendaStyle.pillarWidth,
                            MediaQuery.of(context).orientation)
                        : widget.agendaStyle.pillarWidth,
                height: pillar.head.height,
                decoration: BoxDecoration(
                  color: pillar.head.backgroundColor,
                  border: !widget.agendaStyle.headSeperator ? null : Border(left: BorderSide(color: widget.agendaStyle.timelineBorderColor)),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                        child: widget.agendaStyle.headerLogo == HeaderLogo.circle
                            ? Material(
                                color: pillar.head.color.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(50),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 20.0,
                                      sigmaY: 7.0,
                                    ),
                                    child: Container(
                                      width: widget.agendaStyle.headerHeight - 10,
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Center(
                                        child: Text(
                                          pillar.head.title.isEmpty
                                              ? ''
                                              : pillar.head.title.substring(0, 1).toUpperCase(),
                                          style: pillar.head.textStyle.copyWith(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                width: 5,
                                height: widget.agendaStyle.headerHeight,
                                decoration: BoxDecoration(
                                  color: pillar.head.color,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                      ),
                      pillar.head.subtitle != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pillar.head.title,
                                  style: pillar.head.textStyle,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  pillar.head.subtitle ?? '',
                                  style: pillar.head.subtitleStyle,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          : Text(
                              pillar.head.title,
                              style: pillar.head.textStyle,
                              textAlign: TextAlign.center,
                            ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _scrollToCurrentTime() {
    if (!mounted) {
      return;
    }
    // The scrollables may be detached (e.g. the agenda is kept alive but not
    // laid out inside an Offstage/TabBarView); reading the group offset would
    // then throw.
    if (!_verticalScrollLinker.hasAttachedControllers) {
      return;
    }
    final totalHours = widget.agendaStyle.endHour - widget.agendaStyle.startHour;
    if (totalHours <= 0) {
      return;
    }
    final totalSeconds = totalHours * 3600;
    final now = DateTime.now();
    final nowSeconds = ((now.hour - widget.agendaStyle.startHour) * 3600) + (now.minute * 60);
    // Nothing to scroll to when "now" falls outside [startHour, endHour].
    if (nowSeconds < 0 || nowSeconds > totalSeconds) {
      return;
    }
    final agendaHeight = widget.agendaStyle.timeSlot.height * totalHours;
    final currentTimeOffset = agendaHeight * (nowSeconds / totalSeconds);
    final visibleHeight = MediaQuery.of(context).size.height - widget.agendaStyle.headerHeight - widget.agendaStyle.timeSlot.height;
    if ((_verticalScrollLinker.offset + visibleHeight) < currentTimeOffset || _verticalScrollLinker.offset > currentTimeOffset) {
      final maxOffset = (agendaHeight - visibleHeight).clamp(0.0, agendaHeight);
      final target = (currentTimeOffset - (visibleHeight / 2)).clamp(0.0, maxOffset);
      _verticalScrollLinker.jumpTo(target);
    }
  }
}
