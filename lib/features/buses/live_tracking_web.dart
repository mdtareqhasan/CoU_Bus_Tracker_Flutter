import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

String registerIframeView(String viewId, String url) {
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    final iframe = html.IFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = "geolocation"
      ..setAttribute(
        'sandbox',
        'allow-scripts allow-same-origin allow-forms allow-popups',
      );
    return iframe;
  });
  return viewId;
}

Widget buildWebView(String viewType) {
  return HtmlElementView(viewType: viewType);
}
