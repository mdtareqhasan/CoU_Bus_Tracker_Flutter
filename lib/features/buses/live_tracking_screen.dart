import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'dart:async';
import 'live_tracking_conditional.dart';
import '../../app/theme.dart';
import '../../l10n/l10n.dart';

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
  String _status = L10n.current.trackingConnecting;
  String _distance = '-- km';
  double? _busLatitude;
  double? _busLongitude;

  // Distance (CSS px) from the WebView bottom to the top of the site's
  // refresh-interval timer (.countdown-select, bottom-left of the map).
  // 92 is the site's known layout; injected JS corrects it once loaded.
  double _timerClearance = 92;

  // True while the site's interval dropdown is open (it expands upward and
  // would otherwise be covered by our status card).
  bool _timerDropdownOpen = false;
  Position? _userPosition;
  StreamSubscription<Position>? _positionStream;
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _initLocation();

    // Ensure HTTPS and Google Maps default
    String finalUrl = widget.url;
    if (finalUrl.startsWith('http://')) {
      finalUrl = finalUrl.replaceFirst('http://', 'https://');
    }
    if (finalUrl.contains('userMapType=open_streets')) {
      finalUrl = finalUrl.replaceAll(
        'userMapType=open_streets',
        'userMapType=google_streets',
      );
    }

    if (kIsWeb) {
      _viewId = 'iframe-map-${widget.url.hashCode}';
      registerIframeView(_viewId, finalUrl);
      _isLoading = false;
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
              if (error.isForMainFrame == true) {
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
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _distance = L10n.current.trackingGpsOff);
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _distance = L10n.current.trackingPermissionDenied);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _distance = L10n.current.trackingPermissionBlocked);
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _userPosition = pos);

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen((Position position) {
            if (!mounted) return;
            final distance = _formatDistance(
              _busLatitude,
              _busLongitude,
              position,
            );
            setState(() {
              _userPosition = position;
              if (distance != null) _distance = distance;
            });
          });
    } catch (e) {
      debugPrint('Location Error: $e');
    }
  }

  void _handleWebStatus(String data) {
    // Lightweight signal from the injected dropdown watcher.
    if (data.startsWith('DD:')) {
      final open = data == 'DD:1';
      if (open != _timerDropdownOpen && mounted) {
        setState(() => _timerDropdownOpen = open);
      }
      return;
    }

    try {
      final parts = data.split('|');
      if (parts.length < 4) return;

      final speed = parts[0];
      final status = parts[1];
      final latVal = double.tryParse(parts[2]);
      final lngVal = double.tryParse(parts[3]);

      var nextTimerClearance = _timerClearance;
      if (parts.length >= 5) {
        final clearance = double.tryParse(parts[4]);
        if (clearance != null && clearance >= 0) {
          nextTimerClearance = clearance;
        }
      }

      String translatedStatus = status;
      if (status.toLowerCase().contains('moving') ||
          status.toLowerCase().contains('running')) {
        translatedStatus = 'Running';
      } else if (status.toLowerCase().contains('stopped')) {
        translatedStatus = 'Stopped';
      }

      final hasCoordinates =
          latVal != null && lngVal != null && latVal != 0 && lngVal != 0;
      final distanceStr = hasCoordinates
          ? (_formatDistance(latVal, lngVal) ?? _distance)
          : _distance;

      // WebView callbacks can arrive frequently. Avoid rebuilding the full
      // platform-view stack unless a value visible in Flutter actually changed.
      if (speed == _speed &&
          translatedStatus == _status &&
          distanceStr == _distance &&
          nextTimerClearance == _timerClearance) {
        return;
      }

      setState(() {
        _speed = speed;
        _status = translatedStatus;
        _distance = distanceStr;
        _timerClearance = nextTimerClearance;
        if (hasCoordinates) {
          _busLatitude = latVal;
          _busLongitude = lngVal;
        }
      });
    } catch (e) {
      debugPrint('Error parsing status: $e');
    }
  }

  String? _formatDistance(
    double? latitude,
    double? longitude, [
    Position? position,
  ]) {
    final userPosition = position ?? _userPosition;
    if (userPosition == null || latitude == null || longitude == null) {
      return null;
    }
    final meters = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      latitude,
      longitude,
    );
    return meters < 1000
        ? '${meters.toStringAsFixed(0)} m'
        : '${(meters / 1000).toStringAsFixed(1)} km';
  }

  void _applyCustomChanges() {
    if (kIsWeb) return;
    _hideSideInfo();
    _removeCheckboxes();
    _setRefreshInterval();
    _setupStatusTracking();
    _watchTimerDropdown();
    _preserveZoomOnRefresh();
  }

  /// The site's refresh-interval dropdown (.el-select-dropdown) expands
  /// upward from the timer and would sit behind our Flutter status card.
  /// Report open/closed changes so the card can step out of the way.
  void _watchTimerDropdown() {
    const js = """
      (function() {
        if (window.__timerDropdownWatch) return;
        window.__timerDropdownWatch = true;
        var last = null;
        setInterval(function() {
          var open = false;
          var dropdowns = document.querySelectorAll('.el-select-dropdown');
          for (var i = 0; i < dropdowns.length; i++) {
            var cs = getComputedStyle(dropdowns[i]);
            if (cs.display !== 'none' && dropdowns[i].getBoundingClientRect().height > 0) {
              open = true;
              break;
            }
          }
          if (open !== last) {
            last = open;
            if (window.StatusChannel) window.StatusChannel.postMessage('DD:' + (open ? '1' : '0'));
          }
        }, 1000);
      })();
    """;
    _controller?.runJavaScript(js);
  }

  /// The site's auto-refresh (~every 30s) calls `map.setView(busPos, 18)`,
  /// snapping the map back to its default zoom and throwing away whatever
  /// zoom the user chose. Remember the zoom picked through real user gestures
  /// (wheel, pinch, double-tap, +/- keys, zoom buttons) and restore it on
  /// programmatic changes; until the user zooms once, the site is left alone
  /// so its initial framing still works.
  ///
  /// Two Leaflet quirks this has to work around: pinch zoom bypasses
  /// setZoom/setView entirely (only 'zoomend' sees it), and getZoom() still
  /// returns the old value while an animated zoom is in flight.
  void _preserveZoomOnRefresh() {
    const js = """
      (function() {
        if (window.__zoomKeeperInstalled) return;
        window.__zoomKeeperInstalled = true;

        var lastZoomGestureAt = 0;
        var userZoom = null;
        var restoring = false;
        var watchedMap = null;

        function markZoomGesture() { lastZoomGestureAt = Date.now(); }
        function inZoomGesture() { return Date.now() - lastZoomGestureAt < 800; }

        document.addEventListener('wheel', markZoomGesture, { capture: true, passive: true });
        document.addEventListener('dblclick', markZoomGesture, { capture: true, passive: true });
        document.addEventListener('keydown', function(e) {
          if (e.key === '+' || e.key === '-' || e.key === '=' || e.key === '_') {
            markZoomGesture();
          }
        }, { capture: true, passive: true });
        document.addEventListener('touchmove', function(e) {
          if (e.touches && e.touches.length > 1) markZoomGesture(); // pinch zoom
        }, { capture: true, passive: true });
        document.addEventListener('click', function(e) {
          if (e.target && e.target.closest && e.target.closest('.leaflet-control-zoom')) {
            markZoomGesture();
          }
        }, { capture: true, passive: true });

        // Pinch zoom (and every animated zoom) only settles on 'zoomend',
        // where getZoom() is finally accurate. Record there when the zoom
        // followed a user gesture; programmatic changes never do.
        function watch(map) {
          if (!map || map === watchedMap || typeof map.on !== 'function') return;
          watchedMap = map;
          map.on('zoomend', function() {
            if (!inZoomGesture()) return;
            var z = map.getZoom();
            if (typeof z === 'number') userZoom = z;
          });
        }

        function install() {
          if (!window.L || !window.L.Map || window.L.Map.__zoomKeeper) return false;
          window.L.Map.__zoomKeeper = true;
          var proto = window.L.Map.prototype;

          ['setView', 'setZoom', 'flyTo'].forEach(function(name) {
            var orig = proto[name];
            if (typeof orig !== 'function') return;
            proto[name] = function() {
              watch(this);
              if (restoring) return orig.apply(this, arguments);

              var requested = (name === 'setZoom') ? arguments[0] : arguments[1];

              if (inZoomGesture()) {
                // Real user zoom: let it through and remember the level. Take
                // it from the arguments — getZoom() may still be stale here.
                if (typeof requested === 'number') userZoom = requested;
                return orig.apply(this, arguments);
              }

              // Programmatic change (auto-refresh, initial framing, ...):
              // untouched until the user has chosen a zoom level themselves.
              if (userZoom === null) return orig.apply(this, arguments);
              if (typeof requested !== 'number' || requested === userZoom) {
                return orig.apply(this, arguments);
              }

              // Keep the user's zoom; the site still recenters on the bus.
              restoring = true;
              try {
                if (name === 'setZoom') return orig.call(this, userZoom, arguments[1]);
                return orig.call(this, arguments[0], userZoom, arguments[2]);
              } finally {
                restoring = false;
              }
            };
          });
          return true;
        }

        // Leaflet may be bundled in a chunk that loads after this injection.
        if (!install()) {
          var tries = 0;
          var timer = setInterval(function() {
            if (install() || ++tries >= 240) clearInterval(timer);
          }, 500);
        }
      })();
    """;
    _controller?.runJavaScript(js);
  }

  void _setupStatusTracking() {
    const js = """
      (function() {
        if (window.__statusTrackingInstalled) return;
        window.__statusTrackingInstalled = true;

        var lastPayload = null;
        var lastReadAt = 0;
        var pending = false;
        var selectors = [
          '.side-panel', '.info-panel', '#sidebar', '.sidebar',
          '.details-panel', '.control-panel', '.right-section',
          '[class*="tracking"]', '[class*="vehicle"]'
        ];

        function textFromTrackingPanel() {
          var parts = [];
          for (var i = 0; i < selectors.length; i++) {
            var elements = document.querySelectorAll(selectors[i]);
            for (var j = 0; j < elements.length; j++) {
              var value = elements[j].innerText || elements[j].textContent || '';
              if (value) parts.push(value);
            }
          }
          // The provider can change its CSS class names. This fallback is used
          // only at the reduced sampling rate below, never in a tight DOM loop.
          return parts.length ? parts.join('\\n') : (document.body.innerText || document.body.textContent || '');
        }

        function getRealtimeData() {
          var speed = '0 km/h';
          var status = 'Stopped';
          var lat = '0', lng = '0';
          var text = textFromTrackingPanel();

          var statusMatch = text.match(/Status\\s*:?\\s*([^\\n\\r|]+)/i);
          if (statusMatch && statusMatch[1]) status = statusMatch[1].trim();

          var coordinateMatch = text.match(/Coordinates\\s*:?\\s*(-?\\d+(?:\\.\\d+)?)\\s*,\\s*(-?\\d+(?:\\.\\d+)?)/i);
          if (coordinateMatch) {
            lat = coordinateMatch[1];
            lng = coordinateMatch[2];
          }

          var speedMatch = text.match(/(\\d+(?:\\.\\d+)?)\\s*km\\/h/i);
          if (speedMatch) speed = speedMatch[0];

          var timerEl = document.querySelector('.countdown-select');
          var timerTop = timerEl ? Math.round(innerHeight - timerEl.getBoundingClientRect().top) : 0;

          return speed + '|' + status + '|' + lat + '|' + lng + '|' + timerTop;
        }
        function report() {
          pending = false;
          lastReadAt = Date.now();
          var data = getRealtimeData();
          if (data !== lastPayload && window.StatusChannel) {
            lastPayload = data;
            window.StatusChannel.postMessage(data);
          }
        }

        function scheduleReport() {
          if (pending) return;
          var wait = Math.max(0, 5000 - (Date.now() - lastReadAt));
          pending = true;
          setTimeout(report, wait);
        }

        // Observe actual tracker-page updates and debounce them. The 5-second
        // fallback handles providers that update without changing text nodes.
        var observer = new MutationObserver(scheduleReport);
        observer.observe(document.documentElement, {
          childList: true, subtree: true, characterData: true
        });
        report();
        setInterval(scheduleReport, 5000);
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
        if (setRefresh()) return;
        var attempts = 0;
        var timer = setInterval(function() {
          if (setRefresh() || ++attempts >= 12) clearInterval(timer);
        }, 1000);
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
                if (!kIsWeb &&
                    _controller != null &&
                    await _controller!.canGoBack()) {
                  _controller!.goBack();
                } else if (context.mounted) {
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
                          ? _buildWebMapCenteringContainer()
                          : WebViewWidget(controller: _controller!),
                    ),
                  ),
                  if (!_hasNetworkError)
                    PointerInterceptor(child: _buildStatusOverlay()),
                  if (_isLoading && !_hasNetworkError)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryBlue,
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

  Widget _buildWebMapCenteringContainer() {
    // Strategic Clipping to hide sidebar and center the map view
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // We expand the iframe to push the sidebar out of the clipped area
    final expansionFactor = isMobile ? 1.6 : 1.35;
    final sidebarWidth = screenWidth * (expansionFactor - 1.0);

    return ClipRect(
      child: OverflowBox(
        maxWidth: double.infinity,
        alignment: Alignment.topLeft,
        child: Transform.translate(
          // Push sidebar to the left (out of view)
          offset: Offset(-(sidebarWidth / (isMobile ? 1.1 : 1.5)), 0),
          child: SizedBox(
            width: screenWidth * expansionFactor,
            height: double.infinity,
            child: buildWebView(_viewId),
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
      expandedHeight: 120,
      leading: PointerInterceptor(
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.busName,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(isMoving),
            ],
          ),
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradientFor(context),
          ),
          padding: const EdgeInsets.fromLTRB(16, 82, 16, 8),
          child: Center(
            child: PointerInterceptor(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.tips_and_updates_rounded,
                      color: Colors.yellowAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.trackingFastUpdateHint,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        PointerInterceptor(
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => kIsWeb ? null : _controller?.reload(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isMoving) {
    final color = isMoving ? Colors.greenAccent : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
              .animate(onPlay: (c) => c.repeat())
              .fade(duration: 800.ms, begin: 0.4, end: 1),
          const SizedBox(width: 6),
          Text(
            isMoving ? 'RUNNING' : 'STOPPED',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOverlay() {
    final isMoving = _status == 'Running';
    final statusColor = isMoving ? Colors.greenAccent : Colors.orangeAccent;

    return Stack(
      children: [
        // Status card, stacked above the site's refresh timer (bottom-left).
        // It fades out while the timer's interval dropdown is open, since
        // that dropdown expands upward and would otherwise be covered.
        Positioned(
          left: 16,
          bottom: _timerClearance + 12 + MediaQuery.of(context).padding.bottom,
          child: IgnorePointer(
            ignoring: _timerDropdownOpen,
            child: AnimatedOpacity(
              opacity: _timerDropdownOpen ? 0 : 1,
              duration: const Duration(milliseconds: 180),
              child: Container(
                width: 190,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F2E).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
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
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          color: Colors.white54,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Distance: ',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          _distance,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
            ),
          ),
        ),

        // Bottom Right Speedometer
        Positioned(
          bottom: 32 + MediaQuery.of(context).padding.bottom,
          right: 16,
          child:
              Container(
                    width: 95,
                    height: 95,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradientFor(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
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
                  )
                  .animate(target: isMoving ? 1 : 0)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    curve: Curves.elasticOut,
                  ),
        ),

        // Refresh selector for web (re-implemented since we can't show it from iframe)
        if (kIsWeb)
          Positioned(
            bottom: 20,
            left: 20,
            child: PointerInterceptor(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryBlue, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: const Text(
                  'Refresh: 5s',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
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
              Text(
                context.l10n.noInternetTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1F2E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.trackingNoInternetBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
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
                label: Text(
                  context.l10n.commonRetry,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(220, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
