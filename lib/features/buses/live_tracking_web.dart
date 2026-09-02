import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
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

/// Creates a Leaflet map with a bus marker at the given coordinates.
/// The Obhai URL is never exposed to the user.
Widget buildLeafletMap(String viewId, double lat, double lng, String busName) {
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    final div = html.DivElement()
      ..id = 'leaflet-map-$viewId'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0';

    // Inject Leaflet CSS & JS after the element is in DOM
    scheduleMicrotask(() {
      _injectLeaflet(div, lat, lng, busName);
    });

    return div;
  });

  return HtmlElementView(viewType: viewId);
}

void _injectLeaflet(
  html.Element container,
  double lat,
  double lng,
  String busName,
) {
  // Avoid double-injecting
  if (container.querySelector('.leaflet-container') != null) return;

  // Load Leaflet CSS
  final cssLink = html.LinkElement()
    ..rel = 'stylesheet'
    ..href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
  html.document.head!.append(cssLink);

  // Load Leaflet JS
  final script = html.ScriptElement()
    ..src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
  html.document.head!.append(script);

  script.onLoad.listen((_) {
    final mapId = container.id;
    final mapDiv = html.DivElement()
      ..id = mapId
      ..style.width = '100%'
      ..style.height = '100%';
    container.append(mapDiv);

    final safeBusName = busName.replaceAll('"', '\\"');
    js.context.callMethod('eval', [
      '''
      (function() {
        var map = L.map("$mapId", { zoomControl: false }).setView([$lat, $lng], 16);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '&copy; OpenStreetMap'
        }).addTo(map);
        L.control.zoom({ position: 'topright' }).addTo(map);
        var busIcon = L.divIcon({
          className: 'bus-marker',
          html: '<div style="background:#1a73e8;color:white;border-radius:50%;width:36px;height:36px;display:flex;align-items:center;justify-content:center;font-size:18px;border:3px solid white;box-shadow:0 2px 8px rgba(0,0,0,0.3);">🚌</div>',
          iconSize: [36, 36],
          iconAnchor: [18, 18]
        });
        L.marker([$lat, $lng], {icon: busIcon}).addTo(map)
          .bindPopup("$safeBusName")
          .openPopup();
        setTimeout(function() { map.invalidateSize(); }, 200);
      })();
    ''',
    ]);
  });
}
