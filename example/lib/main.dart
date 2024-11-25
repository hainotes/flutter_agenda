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
bool _isloading = true;
TimeSlot _selectedTimeSlot = TimeSlot.half;

class AgendaScreenState extends State<AgendaScreen> {
  @override
  void initState() {
    super.initState();
    resources = [
      Resource(
        head: Header(title: 'الموارد 1.', subtitle: '3 التعيينات', object: 1),
        events: [
          AgendaEvent(
            title: 'اجتماع D.',
            subtitle: 'ب',
            backgroundColor: Colors.red,
            start: EventTime(hour: 15, minute: 0),
            end: EventTime(hour: 16, minute: 30),
          ),
          AgendaEvent(
            title: 'اجتماع Z.',
            subtitle: 'MZ.',
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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Agenda'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _isloading = !_isloading;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  resources.addAll([
                    Resource(
                      head: Header(title: 'الموارد 4.', object: 4),
                      events: [
                        AgendaEvent(
                          title: 'اجتماع أ',
                          subtitle: 'MA',
                          start: EventTime(hour: 10, minute: 10),
                          end: EventTime(hour: 11, minute: 45),
                          onTap: () {
                            // ignore: avoid_print
                            print("meeting A Details");
                          },
                        ),
                      ],
                    ),
                    Resource(
                      head: Header(title: 'الموارد 4.', object: 4),
                      events: [
                        AgendaEvent(
                          title: 'اجتماع أ',
                          subtitle: 'MA',
                          start: EventTime(hour: 10, minute: 10),
                          end: EventTime(hour: 11, minute: 45),
                          onTap: () {
                            // ignore: avoid_print
                            print("meeting A Details");
                          },
                        ),
                      ],
                    )
                  ]);
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                setState(() {
                  resources.removeAt(0);
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.event),
              onPressed: () {
                setState(() {
                  resources.first.events.add(AgendaEvent(
                    title: 'اجتماع أ',
                    subtitle: 'MA',
                    start: EventTime(hour: 9, minute: 0),
                    end: EventTime(hour: 11, minute: 45),
                    onTap: () {
                      // ignore: avoid_print
                      print("meeting A Details");
                    },
                  ));
                });
              },
            ),
            TextButton(
              child:
                  const Text("15 min", style: TextStyle(color: Colors.white)),
              onPressed: () {
                setState(() {
                  _selectedTimeSlot = TimeSlot.quarter;
                });
              },
            ),
            TextButton(
              child:
                  const Text("30 min", style: TextStyle(color: Colors.white)),
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
        body: _isloading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : FlutterAgenda(
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
                  print(
                      "Clicked time: ${clickedTime.hour}:${clickedTime.minute}");
                  // ignore: avoid_print
                  print("Head Object related to the resource: $object");
                  resources
                      .where((resource) => resource.head.object == object)
                      .first
                      .events
                      .add(AgendaEvent(
                        title: 'اجتماع أ',
                        subtitle: 'MA',
                        start: clickedTime,
                        end: EventTime(
                            hour: clickedTime.hour + 1,
                            minute: clickedTime.minute),
                        onTap: () {
                          // ignore: avoid_print
                          print("meeting A Details");
                        },
                      ));

                  setState(() {});
                },
              ),
      ),
    );
  }
}
