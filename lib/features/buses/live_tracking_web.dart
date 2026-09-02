import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

void registerIframeView(String viewId, String url) {
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    final iframe = html.IFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'geolocation'
      // Try to reduce blocks by setting no-referrer
      ..referrerPolicy = 'no-referrer'
      // Mobile-friendly scale for web views
      ..style.transform = 'scale(1.0)'
      ..style.transformOrigin = 'top left';
    return iframe;
  });
}

Widget buildWebView(String viewType) {
  return HtmlElementView(viewType: viewType);
}

/// Creates a Leaflet map with a bus marker at the given coordinates.
Widget buildLeafletMap(String viewId, double lat, double lng, String busName) {
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    final container = html.DivElement()
      ..id = viewId
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = '#f0f0f0';

    // Inject Leaflet once
    _injectLeafletScripts();

    // Map initialization logic
    _initMap(viewId, lat, lng, busName);

    return container;
  });

  return HtmlElementView(viewType: viewId);
}

bool _leafetInjected = false;

void _injectLeafletScripts() {
  if (_leafetInjected) return;
  
  final head = html.document.head!;
  
  if (head.querySelector('link[href*="leaflet.css"]') == null) {
    head.append(html.LinkElement()
      ..rel = 'stylesheet'
      ..href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css');
  }

  if (head.querySelector('script[src*="leaflet.js"]') == null) {
    head.append(html.ScriptElement()
      ..src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js');
  }
  
  _leafetInjected = true;
}

void _initMap(String mapId, double lat, double lng, String busName) {
  // We need to wait for both the element to be in DOM and the script to be loaded
  Timer.periodic(const Duration(milliseconds: 200), (timer) {
    final container = html.document.getElementById(mapId);
    final hasL = js.context.hasProperty('L');
    
    if (container != null && hasL) {
      timer.cancel();
      
      final safeBusName = busName.replaceAll('"', '\\"');
      js.context.callMethod('eval', [
        '''
        (function() {
          var container = document.getElementById("$mapId");
          if (!container) return;
          
          // Clear previous map if exists
          if (container._leaflet_id) {
            container._leaflet_id = null;
          }
          container.innerHTML = "";

          var map = L.map("$mapId", { 
            zoomControl: false,
            attributionControl: false 
          }).setView([$lat, $lng], 16);
          
          L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);
          
          var busIcon = L.divIcon({
            className: 'bus-marker',
            html: '<div style="background:#3886D8;color:white;border-radius:50%;width:36px;height:36px;display:flex;align-items:center;justify-content:center;font-size:18px;border:3px solid white;box-shadow:0 2px 10px rgba(0,0,0,0.4);">🚌</div>',
            iconSize: [36, 36],
            iconAnchor: [18, 18]
          });

          L.marker([$lat, $lng], {icon: busIcon}).addTo(map)
            .bindPopup("<b>$safeBusName</b><br>Live Tracking", { closeButton: false })
            .openPopup();

          L.control.zoom({ position: 'topright' }).addTo(map);

          // Force resize
          setTimeout(function() { 
            map.invalidateSize(); 
          }, 500);
        })();
        ''',
      ]);
    }
    
    if (timer.tick > 50) { // Timeout after 10 seconds
      timer.cancel();
    }
  });
}
