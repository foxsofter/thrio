// The MIT License (MIT)
//
// Copyright (c) 2019 Hellobike Group
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

import 'package:flutter/material.dart';

import '../module/module_context.dart';
import 'navigator_route_settings.dart';
import 'navigator_types.dart';
import 'thrio_navigator_implement.dart';

enum NavigatorRouteAction {
  push,
  pop,
  popTo,
  remove,
}

/// A route managed by the `ThrioNavigatorImplement`.
///
class NavigatorPageRoute<TCallbackParams> extends MaterialPageRoute<bool> {
  NavigatorPageRoute({
    @required NavigatorPageBuilder builder,
    @required RouteSettings settings,
    ModuleContext moduleContext,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
            builder: (_) => builder(settings, moduleContext),
            settings: settings,
            maintainState: maintainState,
            fullscreenDialog: fullscreenDialog);

  NavigatorRouteAction routeAction;

  NavigatorParamsCallback poppedResultCallback;

  final _popDisableds = <String, bool>{};

  final _popDisabledFutures = <String, Future>{};

  @override
  void addScopedWillPopCallback(WillPopCallback callback) {
    _setPopDisabled(true);
    super.addScopedWillPopCallback(callback);
  }

  @override
  void removeScopedWillPopCallback(WillPopCallback callback) {
    _setPopDisabled(false);
    super.removeScopedWillPopCallback(callback);
  }

  void _setPopDisabled(bool disabled) {
    _popDisableds[settings.name] = disabled;

    // 延迟300ms执行，避免因为WillPopScope依赖变更导致发送过多的Channel消息
    _popDisabledFutures[settings.name] ??=
        Future.delayed(const Duration(milliseconds: 300), () {
      _popDisabledFutures.remove(settings.name); // ignore: unawaited_futures
      final disabled = _popDisableds.remove(settings.name);
      ThrioNavigatorImplement.shared().setPopDisabled(
        url: settings.url,
        index: settings.index,
        disabled: disabled,
      );
    });
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (settings.isNested) {
      final urlPatterns =
          ThrioNavigatorImplement.shared().routeTransitionsBuilders.keys;
      for (final urlPattern in urlPatterns) {
        if (urlPattern.hasMatch(settings.url)) {
          final builder = ThrioNavigatorImplement.shared()
              .routeTransitionsBuilders[urlPattern];
          return builder(context, animation, secondaryAnimation, child);
        }
      }
      return super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    return child;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
