import 'package:flutter/material.dart';
import 'reader_chrome.dart';

class ReaderNotFound extends StatelessWidget {
  const ReaderNotFound({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReaderScaffold(
      title: 'Study mode',
      child: Center(child: Text('Material not found.')),
    );
  }
}
