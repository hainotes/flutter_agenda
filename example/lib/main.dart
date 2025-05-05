import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_agenda/flutter_agenda.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: false,
      ),
      home: const AgendaScreen(),
    );
  }
}

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  AgendaScreenState createState() => AgendaScreenState();
}

List<Resource> resources = <Resource>[];
TimeSlot _selectedTimeSlot = TimeSlot.half;

class AgendaScreenState extends State<AgendaScreen> {
  @override
  void initState() {
    super.initState();
    final letter = _randomLetter();
    resources = [
      Resource(
        head: Header(title: 'Resource $letter', subtitle: 'Event', object: letter),
        events: [
          AgendaEvent(
            title: 'Meeting $letter',
            subtitle: 'Event 1',
            backgroundColor: Colors.red,
            start: EventTime(hour: 15, minute: 0),
            end: EventTime(hour: 16, minute: 30),
          ),
          AgendaEvent(
            title: 'Meeting $letter',
            subtitle: 'Event 2',
            start: EventTime(hour: 9, minute: 0),
            end: EventTime(hour: 18, minute: 0),
          ),
        ],
      ),
      // Resource(
      //   head: Header(title: 'الموارد 2', object: 2),
      //   events: [
      //     AgendaEvent(
      //       title: 'اجتماع G.',
      //       subtitle: 'MG',
      //       backgroundColor: Colors.yellowAccent,
      //       start: EventTime(hour: 9, minute: 10),
      //       end: EventTime(hour: 11, minute: 45),
      //     ),
      //   ],
      // ),
      // Resource(
      //   head: Header(title: 'الموارد 3.', object: 3, color: Colors.yellow),
      //   events: [
      //     AgendaEvent(
      //       title: 'اجتماع أ',
      //       subtitle: 'MA',
      //       start: EventTime(hour: 10, minute: 10),
      //       end: EventTime(hour: 11, minute: 45),
      //       onTap: () {
      //         // ignore: avoid_print
      //         print("meeting A Details");
      //       },
      //     ),
      //   ],
      // ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final letter = _randomLetter();
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Agenda'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  resources.add(
                    Resource(
                      head: Header(title: 'Resource $letter', object: letter),
                      events: [
                        AgendaEvent(
                          title: 'Meeting $letter',
                          subtitle: 'Event',
                          start: EventTime(hour: 10, minute: 10),
                          end: EventTime(hour: 11, minute: 45),
                          onTap: () {
                            // ignore: avoid_print
                            print("Meeting $letter Details");
                          },
                        ),
                      ],
                    ),
                  );
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                setState(() {
                  resources.removeLast();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.event),
              onPressed: () {
                setState(() {
                  resources.first.events.add(AgendaEvent(
                    title: 'Meeting $letter',
                    subtitle: 'MA',
                    start: EventTime(hour: 9, minute: 0),
                    end: EventTime(hour: 11, minute: 45),
                    onTap: () {
                      // ignore: avoid_print
                      print("Meeting $letter Details");
                    },
                  ));
                });
              },
            ),
            TextButton(
              child: const Text("15 min", style: TextStyle(color: Colors.white)),
              onPressed: () {
                setState(() {
                  _selectedTimeSlot = TimeSlot.quarter;
                });
              },
            ),
            TextButton(
              child: const Text("30 min", style: TextStyle(color: Colors.white)),
              onPressed: () {
                setState(() {
                  _selectedTimeSlot = TimeSlot.half;
                });
              },
            ),
            TextButton(
              child: const Text("1h", style: TextStyle(color: Colors.white)),
              onPressed: () {
                setState(() {
                  _selectedTimeSlot = TimeSlot.full;
                });
              },
            ),
            // TextButton(
            //   child: Text("Navigate", style: TextStyle(color: Colors.white)),
            //   onPressed: () {
            //     showModalBottomSheet(
            //         context: context, builder: (context) => SecondScreen());
            //   },
            // ),
          ],
        ),
        body: FlutterAgenda(
          resources: resources,
          agendaStyle: AgendaStyle(
            startHour: 9,
            endHour: 23,
            headerLogo: HeaderLogo.bar,
            fittedWidth: false,
            timeItemWidth: 45,
            timeSlot: _selectedTimeSlot,
            pillarSeperator: true,
            visibleTimeBorder: true,
            visibleDecorationBorder: true,
            visibleCurrentTimeMarker: true,
          ),
          // the click else where (other than an event because it has it's own onTap parameter)
          // you get the object linked to the head object of the pillar which could be you project costume object
          // and the cliked time
          onTap: (clickedTime, object) {
            // ignore: avoid_print
            print("Clicked time: ${clickedTime.hour}:${clickedTime.minute}");
            // ignore: avoid_print
            print("Head Object related to the resource: $object");
            resources.where((resource) => resource.head.object == object).first.events.add(
                  AgendaEvent(
                    title: 'Meeting ${_randomLetter()}',
                    subtitle: 'MA',
                    start: clickedTime,
                    end: EventTime(hour: clickedTime.hour + 1, minute: clickedTime.minute),
                    onTap: () {
                      // ignore: avoid_print
                      print("Meeting Details");
                    },
                  ),
                );
            setState(() {});
          },
          onDoubleTap: (clickedTime, object) {
            // ignore: avoid_print
            print("double tap");
          },
          onLongPress: (clickedTime, object) {
            // ignore: avoid_print
            print("long press");
          },
        ),
      ),
    );
  }

  String _randomLetter() {
    final random = Random();
    final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return letters[random.nextInt(letters.length)];
  }
}
