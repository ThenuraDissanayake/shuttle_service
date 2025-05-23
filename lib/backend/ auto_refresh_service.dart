import 'dart:async';
import 'package:flutter/material.dart';

class AutoRefreshService {
  Timer? _timer;

  void startAutoRefresh(VoidCallback callback, {int seconds = 5}) {
    _timer = Timer.periodic(Duration(seconds: seconds), (timer) {
      callback(); // Call the function every `seconds`
    });
  }

  void stopAutoRefresh() {
    _timer?.cancel(); // Stop the timer
  }
}
