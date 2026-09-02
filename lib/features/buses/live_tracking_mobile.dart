import 'package:flutter/material.dart';

String registerIframeView(String viewId, String url) {
  // No-op on mobile — WebView is used instead.
  return viewId;
}

Widget buildWebView(String viewType) {
  // Should never be called on mobile.
  return const SizedBox.shrink();
}
