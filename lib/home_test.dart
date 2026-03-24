import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class HomeTest extends StatefulWidget {
  const HomeTest({super.key});

  @override
  State<HomeTest> createState() => _HomeTestState();
}

class _HomeTestState extends State<HomeTest> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Flutter is working")),
    );
  }
}
