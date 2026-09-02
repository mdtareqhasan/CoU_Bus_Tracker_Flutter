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
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0'
      ..allow = 'geolocation';
    return iframe;
  });
  return viewId;
}

Widget buildWebView(String viewType) {
  return HtmlElementView(viewType: viewType);
}
