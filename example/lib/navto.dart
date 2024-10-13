import 'package:flutter/material.dart';

class SecondScreen extends StatefulWidget {
  const SecondScreen({super.key});

  @override
  State<SecondScreen> createState() => _SecondScreenState();
}

bool _set = true;

class _SecondScreenState extends State<SecondScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Second Screen'),
        if (_set)
          Container(
            height: 80,
            width: 80,
            color: Colors.red,
          ),
        TextButton(
            onPressed: () {
              setState(() {
                _set = !_set;
              });
            },
            child: const Text('dzf,'))
      ],
    );
  }
}
