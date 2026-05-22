import 'package:flutter/material.dart';
import '../../../../core/widgets/widgets.dart';
import 'reader_chrome.dart';

class ReaderLoading extends StatelessWidget {
  const ReaderLoading({super.key, this.title = 'Study mode'});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ReaderScaffold(
      title: title,
      child: const LoadingWidget(),
    );
  }
}
