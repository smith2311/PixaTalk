import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyDateUtil {
  // For getting formatted time from millisecondsSinceEpoch String
  static String getFormattedTime(
      {required BuildContext context, required String time}) {
    final date = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    return DateFormat.jm().format(date);  // Format the date using DateFormat
  }

  // For getting formatted time for sent & read
  static String getLastMessageTime({
    required BuildContext context,
    required String time,
    bool showYear = false,
  }) {
    final DateTime sent = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    final DateTime now = DateTime.now();

    final String formattedTime = DateFormat('h:mm a').format(sent);

    if (now.day == sent.day &&
        now.month == sent.month &&
        now.year == sent.year) {
      return formattedTime;
    }

    final String formattedDate = showYear
        ? '${sent.day} ${_getMonth(sent)} ${sent.year}'
        : '${sent.day} ${_getMonth(sent)}';

    return '$formattedTime - $formattedDate';
  }


  static String _getMonth(DateTime date) {
    switch (date.month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sept';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return 'NA';
    }
  }
  static String getLastActiveTime({
    required BuildContext context,
    required String lastActive,
  }) {
    final DateTime lastSeen = DateTime.fromMillisecondsSinceEpoch(int.parse(lastActive));
    final DateTime now = DateTime.now();

    if (now.difference(lastSeen).inMinutes < 1) {
      return 'Just now';
    }

    if (now.day == lastSeen.day &&
        now.month == lastSeen.month &&
        now.year == lastSeen.year) {
      return 'Last seen at ${DateFormat.jm().format(lastSeen)}';
    }

    if (now.year == lastSeen.year) {
      return 'Last seen on ${DateFormat('d MMM').format(lastSeen)} at ${DateFormat.jm().format(lastSeen)}';
    }

    return 'Last seen on ${DateFormat('d MMM yyyy').format(lastSeen)} at ${DateFormat.jm().format(lastSeen)}';
  }

}
