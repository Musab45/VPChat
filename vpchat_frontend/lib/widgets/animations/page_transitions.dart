import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Custom page route with slide and fade transition (WhatsApp-like)
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;

  SlidePageRoute({required this.page, this.direction = SlideDirection.right})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: AppAnimations.normal,
        reverseTransitionDuration: AppAnimations.normal,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetTween = Tween<Offset>(
            begin: _getBeginOffset(direction),
            end: Offset.zero,
          );

          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: AppAnimations.defaultCurve,
          );

          return SlideTransition(
            position: offsetTween.animate(curvedAnimation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      );

  static Offset _getBeginOffset(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.right:
        return const Offset(1.0, 0.0);
      case SlideDirection.left:
        return const Offset(-1.0, 0.0);
      case SlideDirection.up:
        return const Offset(0.0, 1.0);
      case SlideDirection.down:
        return const Offset(0.0, -1.0);
    }
  }
}

enum SlideDirection { right, left, up, down }

/// Fade scale transition (Discord-like for dialogs)
class FadeScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeScalePageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: AppAnimations.normal,
        reverseTransitionDuration: AppAnimations.fast,
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: AppAnimations.snappyCurve,
            reverseCurve: Curves.easeIn,
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.9,
                end: 1.0,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      );
}

/// Hero-like shared element transition
class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SharedAxisTransitionType transitionType;

  SharedAxisPageRoute({
    required this.page,
    this.transitionType = SharedAxisTransitionType.horizontal,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: AppAnimations.slow,
         reverseTransitionDuration: AppAnimations.normal,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curvedAnimation = CurvedAnimation(
             parent: animation,
             curve: AppAnimations.smoothCurve,
           );

           switch (transitionType) {
             case SharedAxisTransitionType.horizontal:
               return _buildHorizontalTransition(curvedAnimation, child);
             case SharedAxisTransitionType.vertical:
               return _buildVerticalTransition(curvedAnimation, child);
             case SharedAxisTransitionType.scaled:
               return _buildScaledTransition(curvedAnimation, child);
           }
         },
       );

  static Widget _buildHorizontalTransition(
    Animation<double> animation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.3, 0.0),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  static Widget _buildVerticalTransition(
    Animation<double> animation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.3),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  static Widget _buildScaledTransition(
    Animation<double> animation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

enum SharedAxisTransitionType { horizontal, vertical, scaled }

/// Bottom sheet slide up transition
class BottomSheetRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final double heightFactor;

  BottomSheetRoute({required this.page, this.heightFactor = 0.9})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: AppAnimations.normal,
        reverseTransitionDuration: AppAnimations.fast,
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: AppAnimations.defaultCurve,
            reverseCurve: Curves.easeIn,
          );

          return Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      );
}

/// Navigation helper with custom transitions
class AppNavigator {
  static Future<T?> push<T>(
    BuildContext context,
    Widget page, {
    SlideDirection direction = SlideDirection.right,
  }) {
    return Navigator.of(
      context,
    ).push<T>(SlidePageRoute<T>(page: page, direction: direction));
  }

  static Future<T?> pushReplacement<T, TO>(
    BuildContext context,
    Widget page, {
    SlideDirection direction = SlideDirection.right,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      SlidePageRoute<T>(page: page, direction: direction),
    );
  }

  static Future<T?> pushFadeScale<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(FadeScalePageRoute<T>(page: page));
  }

  static Future<T?> showBottomSheet<T>(
    BuildContext context,
    Widget page, {
    double heightFactor = 0.9,
  }) {
    return Navigator.of(
      context,
    ).push<T>(BottomSheetRoute<T>(page: page, heightFactor: heightFactor));
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }
}
