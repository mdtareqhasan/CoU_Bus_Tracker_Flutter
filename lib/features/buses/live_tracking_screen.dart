import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../app/theme.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String url;
  final String busName;

  const LiveTrackingScreen({
    super.key,
    required this.url,
    required this.busName,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _speed = '0 km/h';
  String _status = 'সংযুক্ত হচ্ছে...';
  String _distance = '-- km';
  Position? _userPosition;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initLocation();
    
    // Modify URL for Google Maps default if possible
    String finalUrl = widget.url;
    if (finalUrl.contains('userMapType=open_streets')) {
      finalUrl = finalUrl.replaceAll('userMapType=open_streets', 'userMapType=google_streets');
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'StatusChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (mounted) {
            _handleWebStatus(message.message);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _applyCustomChanges();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(finalUrl));
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _distance = 'GPS বন্ধ');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _distance = 'অনুমতি নেই');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _distance = 'অনুমতি ব্লক');
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _userPosition = pos);

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen((Position position) {
        if (mounted) setState(() => _userPosition = position);
      });
    } catch (e) {
      debugPrint('Location Error: $e');
    }
  }

  void _handleWebStatus(String data) {
    try {
      final parts = data.split('|');
      if (parts.length < 4) return;

      final speed = parts[0];
      final status = parts[1];
      final latVal = double.tryParse(parts[2]);
      final lngVal = double.tryParse(parts[3]);

      String translatedStatus = status;
      if (status.toLowerCase().contains('moving') || status.toLowerCase().contains('running')) {
        translatedStatus = 'চলমান';
      } else if (status.toLowerCase().contains('stopped')) {
        translatedStatus = 'থেমে আছে';
      }

      String distanceStr = '-- km';
      // Only calculate if coordinates are valid (not 0.0)
      if (_userPosition != null && latVal != null && lngVal != null && latVal != 0 && lngVal != 0) {
        double dist = Geolocator.distanceBetween(_userPosition!.latitude, _userPosition!.longitude, latVal, lngVal);
        if (dist < 1000) {
          distanceStr = '${dist.toStringAsFixed(0)} m';
        } else {
          distanceStr = '${(dist / 1000).toStringAsFixed(1)} km';
        }
      }

      setState(() {
        _speed = speed;
        _status = translatedStatus;
        _distance = distanceStr;
      });
    } catch (e) {
      debugPrint('Error parsing status: $e');
    }
  }

  void _applyCustomChanges() {
    _hideSideInfo();
    _removeCheckboxes();
    _setRefreshInterval();
    _setupStatusTracking();
  }

  void _setupStatusTracking() {
    const js = """
      (function() {
        function getRealtimeData() {
          var speed = '0 km/h';
          var status = 'Stopped';
          var lat = '0', lng = '0';

          var allElements = document.getElementsByTagName('*');
          for (var i = 0; i < allElements.length; i++) {
            var el = allElements[i];
            var text = el.innerText || el.textContent;
            
            if (text && text.includes('Status')) {
               var parts = text.split('Status');
               if (parts[1]) status = parts[1].trim().split('\\n')[0].replace(':', '').trim();
            }
            
            if (text && text.includes('Coordinates')) {
               var parts = text.split('Coordinates');
               if (parts[1]) {
                 var rawCoords = parts[1].trim().split('\\n')[0].replace(':', '').trim();
                 var coords = rawCoords.split(',');
                 if (coords.length >= 2) { lat = coords[0].trim(); lng = coords[1].trim(); }
               }
            }

            if (!speed || speed === '0 km/h') {
               var speedMatch = text.match(/(\\d+)\\s*km\\/h/i);
               if (speedMatch) speed = speedMatch[0];
            }
          }

          return speed + '|' + status + '|' + lat + '|' + lng;
        }
        setInterval(function() {
          var data = getRealtimeData();
          if (window.StatusChannel) window.StatusChannel.postMessage(data);
        }, 1500);
      })();
    """;
    _controller.runJavaScript(js);
  }

  void _removeCheckboxes() {
    const js = """
      (function() {
        var style = document.createElement('style');
        style.innerHTML = `
          input[type="checkbox"], label:has(input[type="checkbox"]),
          .leaflet-control-container .leaflet-bottom.leaflet-left,
          [class*="check"], [class*="option"], .refresh-dropdown { display: none !important; }
        `;
        document.head.appendChild(style);
      })();
    """;
    _controller.runJavaScript(js);
  }

  void _setRefreshInterval() {
    const js = """
      (function() {
        var setRefresh = function() {
          var select = document.querySelector('select');
          if (select) {
            for (var i = 0; i < select.options.length; i++) {
              if (select.options[i].value == '5' || select.options[i].innerText.includes('5')) {
                if (select.selectedIndex !== i) { select.selectedIndex = i; select.dispatchEvent(new Event('change')); }
                return true;
              }
            }
          }
          return false;
        };
        setRefresh(); setInterval(setRefresh, 10000);
      })();
    """;
    _controller.runJavaScript(js);
  }

  void _hideSideInfo() {
    const js = """
      (function() {
        window.dispatchEvent(new Event('resize'));
        var style = document.createElement('style');
        style.innerHTML = `
          .side-panel, .info-panel, #sidebar, .sidebar, 
          .details-panel, .control-panel, .right-section,
          .leaflet-sidebar, .leaflet-right.leaflet-bottom,
          [class*="sidebar"], [class*="side-panel"], [class*="info-panel"] { display: none !important; width: 0 !important; }
          body, html, #app, #map, .map-container, .main-content {
            width: 100% !important; height: 100% !important;
            position: absolute !important; top: 0 !important; left: 0 !important;
            margin: 0 !important; padding: 0 !important;
          }
          .leaflet-container { height: 100vh !important; }
        `;
        document.head.appendChild(style);
        setTimeout(function() {
           window.dispatchEvent(new Event('resize'));
           if (typeof map !== 'undefined' && map.invalidateSize) map.invalidateSize();
        }, 500);
      })();
    """;
    _controller.runJavaScript(js);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverFillRemaining(
            child: PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) return;
                if (await _controller.canGoBack()) _controller.goBack();
                else if (mounted) Navigator.of(context).pop();
              },
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  _buildStatusOverlay(),
                  if (_isLoading) const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final isMoving = _status == 'চলমান';
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(widget.busName, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            _buildStatusBadge(isMoving),
          ]),
          Text('আপডেট হচ্ছে...', style: const TextStyle(fontSize: 11, color: Colors.white60)),
        ],
      ),
      actions: [IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: () => _controller.reload())],
      flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
    );
  }

  Widget _buildStatusBadge(bool isMoving) {
    final color = isMoving ? Colors.greenAccent : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.5), width: 0.5)),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)).animate(onPlay: (c) => c.repeat()).fade(duration: 800.ms, begin: 0.4, end: 1),
        const SizedBox(width: 4),
        Text(isMoving ? 'LIVE' : 'IDLE', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildStatusOverlay() {
    final isMoving = _status == 'চলমান';
    final statusColor = isMoving ? Colors.greenAccent : Colors.orangeAccent;

    return Positioned(
      bottom: 32,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Info Panel
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2E).withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  _buildIconBox(isMoving ? Icons.directions_bus_rounded : Icons.pause_circle_rounded, statusColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.near_me_rounded, color: Colors.white54, size: 16),
                            const SizedBox(width: 8),
                            const Text('আপনার থেকে: ', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Text(_distance, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Speed Panel
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
              boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_speed.split(' ')[0], style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
                const Text('km/h', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ).animate(target: isMoving ? 1 : 0).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.elasticOut),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildIconBox(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 28),
    );
  }
}
