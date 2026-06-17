import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppSnackBars {
  static const Duration cartSuccessDuration = Duration(seconds: 4);
  static const String cartSuccessMessage =
      '\u062a\u0645 \u0625\u0636\u0627\u0641\u0629 \u0627\u0644\u062e\u062f\u0645\u0627\u062a \u0625\u0644\u0649 \u0627\u0644\u0633\u0644\u0629 \u0628\u0646\u062c\u0627\u062d';
  static const String viewCartLabel =
      '\u0639\u0631\u0636 \u0627\u0644\u0633\u0644\u0629';

  static void showCartSuccess(
    ScaffoldMessengerState messenger, {
    required VoidCallback onViewCart,
    Duration duration = cartSuccessDuration,
  }) {
    developer.log('Showing cart success snackbar', name: 'AppSnackBars');
    messenger.clearSnackBars();

    late final ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
        controller;
    var isClosed = false;

    void closeSnackBar() {
      if (isClosed) return;
      isClosed = true;
      developer.log('Closing cart success snackbar', name: 'AppSnackBars');
      controller.close();
    }

    controller = messenger.showSnackBar(
      SnackBar(
        content: const Text(cartSuccessMessage),
        backgroundColor: AppColors.success,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        closeIconColor: Colors.white,
        action: SnackBarAction(
          label: viewCartLabel,
          textColor: Colors.white,
          onPressed: () {
            isClosed = true;
            developer.log(
              'Cart success snackbar action pressed',
              name: 'AppSnackBars',
            );
            messenger.clearSnackBars();
            onViewCart();
          },
        ),
      ),
    );

    unawaited(controller.closed.whenComplete(() {
      isClosed = true;
    }));
    unawaited(Future<void>.delayed(duration, closeSnackBar));
  }
}
