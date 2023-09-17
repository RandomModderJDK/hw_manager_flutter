import 'package:flutter/material.dart';

class FloatingButtonCardListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(int) child;

  const FloatingButtonCardListView({super.key, required this.itemCount, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: kFloatingActionButtonMargin + 64),
      itemCount: itemCount,
      itemBuilder: (context, position) => child(position),
    );
  }
}
