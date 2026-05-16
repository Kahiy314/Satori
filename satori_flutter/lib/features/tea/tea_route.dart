import 'package:flutter/material.dart';

import '../../services/entitlement_controller.dart';
import 'tea_view.dart';

Future<T?> openTeaPage<T>(
  BuildContext context, {
  EntitlementController? entitlementController,
}) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      builder: (_) => TeaView(
        entitlementController: entitlementController,
      ),
    ),
  );
}
