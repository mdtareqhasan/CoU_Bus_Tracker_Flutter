import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
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
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasNetworkError = false;
  String _speed = '0 km/h';
  String _status = 'সংযুক্ত হচ্ছে...';
  String _distance = '-- km';
  Position? _userPosition;
  StreamSubscription<Position>? _positionStream;
  late final String _viewId;
  Timer? _webUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initLocation();

    // Force HTTPS for production (Vercel) to avoid Mixed Content issues
    String finalUrl = widget.url;
    if (finalUrl.startsWith('http://')) {
      finalUrl = finalUrl.replaceFirst('http://', 'https://');
    }

    if (finalUrl.contains('userMapType=open_streets')) {
      finalUrl = finalUrl.replaceAll(
          'userMapType=open_streets', 'userMapType=google_streets');
    }

    if (kIsWeb) {
      _viewId = 'iframe-view-${widget.url.hashCode}';
      ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
        final iframe = html.IFrameElement()
          ..src = finalUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = "geolocation" // Explicitly allow GPS in web
          ..setAttribute('sandbox', 'allow-scripts allow-same-origin allow-forms allow-popups'); 
        return iframe;
      });
      _isLoading = false;
      _startWebStatusUpdates();
    } else {
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
              if (error.isForMainFrame == true &&
                  error.description.contains('ERR_INTERNET_DISCONNECTED')) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _hasNetworkError = true;
                  });
                }
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(finalUrl));
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _webUpdateTimer?.cancel();
    super.dispose();
  }

  void _startWebStatusUpdates() {
    _webUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      _updateWebData();
    });
  }

  void _updateWebData() {
    try {
      // Try to estimate status based on distance change or static Running if loaded
      final uri = Uri.parse(widget.url);
      final lat = double.tryParse(uri.queryParameters['lat'] ?? '');
      final lng = double.tryParse(uri.queryParameters['lng'] ?? '');

      if (_userPosition != null && lat != null && lng != null) {
        double dist = Geolocator.distanceBetween(
            _userPosition!.latitude, _userPosition!.longitude, lat, lng);
        setState(() {
          _status = 'Running';
          if (dist < 1000) {
            _distance = '${dist.toStringAsFixed(0)} m';
          } else {
            _distance = '${(dist / 1000).toStringAsFixed(1)} km';
          }
        });
      } else {
        // Just keep checking position
        _initLocation();
      }
    } catch (_) {}
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
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 10),
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
      if (status.toLowerCase().contains('moving') ||
          status.toLowerCase().contains('running')) {
        translatedStatus = 'Running';
      } else if (status.toLowerCase().contains('stopped')) {
        translatedStatus = 'Stopped';
      }

      String distanceStr = '-- km';
      if (_userPosition != null &&
          latVal != null &&
          lngVal != null &&
          latVal != 0 &&
          lngVal != 0) {
        double dist = Geolocator.distanceBetween(
            _userPosition!.latitude, _userPosition!.longitude, latVal, lngVal);
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
    if (kIsWeb) return; 
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
    _controller?.runJavaScript(js);
  }

  void _removeCheckboxes() {
    const js = """
      (function() {
        var style = document.createElement('style');
        style.innerHTML = `
          input[type="checkbox"], label:has(input[type="checkbox"]),
          .leaflet-control-container .leaflet-bottom.leaflet-left,
          [class*="check"], [class*="option"] { display: none !important; }
        `;
        document.head.appendChild(style);
      })();
    """;
    _controller?.runJavaScript(js);
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
    _controller?.runJavaScript(js);
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
    _controller?.runJavaScript(js);
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
                if (!kIsWeb && _controller != null && await _controller!.canGoBack()) {
                  _controller!.goBack();
                } else if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom,
                      ),
                      child: _hasNetworkError
                          ? _buildNoInternetOverlay()
                          : kIsWeb
                              ? _buildWebMapContainer()
                              : WebViewWidget(controller: _controller!),
                    ),
                  ),
                  if (!_hasNetworkError)
                    PointerInterceptor(child: _buildStatusOverlay()),
                  if (_isLoading && !_hasNetworkError)
                    const Center(
                        child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryBlue))),
                  // Manual Timer Selection for Web
                  if (kIsWeb)
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: PointerInterceptor(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.primaryBlue, width: 2),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                          ),
                          child: const Text('Refresh: 5s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebMapContainer() {
    // Advanced Centering Logic:
    // Sidebar on the source website is roughly 300px on desktop, but adjusts on mobile.
    // We expand the iframe to hide the sidebar and offset it to center the map portion.
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    // On mobile, the sidebar takes up a huge chunk. We expand by 150% to hide it properly.
    final expansionFactor = isMobile ? 1.6 : 1.35;
    final sidebarEstimatedWidth = screenWidth * (expansionFactor - 1.0);

    return ClipRect(
      child: OverflowBox(
        maxWidth: double.infinity,
        alignment: Alignment.topLeft,
        child: Transform.translate(
          // Offset to the left to push the sidebar out of view and center the bus
          offset: Offset(-(sidebarEstimatedWidth / 2), 0),
          child: SizedBox(
            width: screenWidth * expansionFactor,
            height: double.infinity,
            child: HtmlElementView(viewType: _viewId),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final isMoving = _status == 'Running';
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      expandedHeight: 110,
      leading: PointerInterceptor(
        child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => Navigator.of(context).pop()),
      ),
      title: PointerInterceptor(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(widget.busName,
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              _buildStatusBadge(isMoving),
            ]),
          ],
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: PointerInterceptor(
          child: Container(
            decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
            padding: const EdgeInsets.fromLTRB(16, 85, 16, 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tips_and_updates_rounded,
                      color: Colors.white, size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'দ্রুত আপডেট পেতে নিচের বাম পাশের ড্রপডাউন থেকে ৫ সেঃ সিলেক্ট করুন',
                      style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.2),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        PointerInterceptor(
          child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: () => kIsWeb ? null : _controller?.reload()),
        )
      ],
    );
  }

  Widget _buildStatusBadge(bool isMoving) {
    final color = isMoving ? Colors.greenAccent : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5), width: 0.5)),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
            .animate(onPlay: (c) => c.repeat())
            .fade(duration: 800.ms, begin: 0.4, end: 1),
        const SizedBox(width: 6),
        Text(isMoving ? 'RUNNING' : 'STOPPED',
            style: const TextStyle(
                color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildStatusOverlay() {
    final isMoving = _status == 'Running';
    final statusColor = isMoving ? Colors.greenAccent : Colors.orangeAccent;

    return Stack(
      children: [
        // Top Left Info Card
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            width: 190,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2E).withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                        isMoving
                            ? Icons.directions_bus_rounded
                            : Icons.pause_circle_rounded,
                        color: statusColor,
                        size: 22),
                    const SizedBox(width: 10),
                    Text(_status.toUpperCase(),
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.near_me_rounded,
                        color: Colors.white54, size: 14),
                    const SizedBox(width: 6),
                    const Text('Distance: ',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(_distance,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
        ),

        // Bottom Right Speedometer
        Positioned(
          bottom: 32 + MediaQuery.of(context).padding.bottom,
          right: 16,
          child: Container(
            width: 95,
            height: 95,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.2), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _speed.replaceAll(RegExp(r'[^0-9]'), ''),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const Text(
                  'km/h',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ).animate(target: isMoving ? 1 : 0).scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
              curve: Curves.elasticOut),
        ),
      ],
    );
  }

  Widget _buildNoInternetOverlay() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, color: AppTheme.error, size: 72),
              const SizedBox(height: 24),
              const Text(
                'ইন্টারনেট সংযোগ নেই',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1F2E),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'বাসের লোকেশন দেখতে ইন্টারনেট সংযোগ চালু করে\nআবার চেষ্টা করুন।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasNetworkError = false;
                    _isLoading = true;
                  });
                  _controller?.reload();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('আবার চেষ্টা করুন',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(220, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
