import 'package:flutter/widgets.dart';

import '../../core/services/app_services.dart';

class AppScope extends InheritedWidget {
  final AppServices services;
  final String userId;

  const AppScope({
    super.key,
    required this.services,
    required this.userId,
    required super.child,
  });

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget.services != services || oldWidget.userId != userId;
}

