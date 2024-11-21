import 'package:flutter/material.dart';
import 'package:picture_perfect/src/presentation/widgets/common/dynamic_scaffold.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return DynamicScaffold(
      child: ListView(
        children: [
          ListTile(
            title: const Text('Poll #1'),
          )
        ],
      ),
    );
  }
}
