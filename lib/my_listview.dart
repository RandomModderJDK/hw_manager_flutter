import 'package:flutter/material.dart';

class FloatingButtonCardListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(int) child;

  const FloatingButtonCardListView(
      {super.key, required this.itemCount, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        padding:
            const EdgeInsets.only(bottom: kFloatingActionButtonMargin + 64),
        itemCount: itemCount,
        itemBuilder: (context, position) => Card(
              margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 3),
              shape: OutlineInputBorder(
                  borderSide: BorderSide(
                      width: 1.5,
                      color: Theme.of(context).colorScheme.inversePrimary),
                  borderRadius: const BorderRadius.all(Radius.circular(10.0))),
              child: child(position),
            ));
  }
}
