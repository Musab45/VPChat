import 'package:flutter/material.dart';

class OnlineStatus extends StatelessWidget {
  final bool isOnline;

  const OnlineStatus({Key? key, required this.isOnline}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? Colors.green : Colors.grey,
      ),
    );
  }
}
