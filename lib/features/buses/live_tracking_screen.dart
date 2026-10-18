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
import '../../shared/widgets/glass_card.dart';

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
          'userMapType=open_streets', 'userMapType=google_streets');
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
            setState(
              () => _distance = L10n.current.trackingPermissionDenied,
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(
            () => _distance = L10n.current.trackingPermissionBlocked,
          );
        }
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
                              ? _buildWebMapCenteringContainer()
                              : WebViewWidget(controller: _controller!),
                    ),
                  ),
                  if (!_hasNetworkError)
                    PointerInterceptor(child: _buildStatusOverlay()),
                  if (_isLoading && !_hasNetworkError)
                    Positioned.fill(
                      child: ColoredBox(
                        color: AppTheme.bgLight.withValues(alpha: 0.92),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.blueVivid,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppTheme.space16),
                                Text(
                                  context.l10n.trackingConnecting,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
      backgroundColor: AppTheme.blueVivid,
      expandedHeight: 132,
      leading: PointerInterceptor(
        child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => Navigator.of(context).pop()),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              widget.busName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusBadge(isMoving),
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppTheme.auroraHeaderGradient),
            ),
            Positioned(
              top: -40,
              right: -30,
              child: IgnorePointer(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppTheme.cyanBright.withValues(alpha: 0.30),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppTheme.glassOverlay),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 92, 16, 8),
              child: Center(
                child: PointerInterceptor(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space12,
                      vertical: AppTheme.space8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusPill,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
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
                        const SizedBox(width: AppTheme.space8),
                        Flexible(
                          child: Text(
                            context.l10n.trackingFastUpdateHint,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
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
          ],
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
    final color = isMoving ? AppTheme.success : AppTheme.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOverlay() {
    final isMoving = _status == 'Running';
    final statusColor = isMoving ? AppTheme.success : AppTheme.warning;

    return Stack(
      children: [
        // Top Left Info Card — frosted dark glass matching the new chrome
        Positioned(
          top: 16,
          left: 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1220).withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 1,
                ),
                boxShadow: AppTheme.shadowMD,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.18),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSM),
                        ),
                        child: Icon(
                          isMoving
                              ? Icons.directions_bus_rounded
                              : Icons.pause_circle_rounded,
                          color: statusColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: Text(
                          _status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.6,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space12),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  const SizedBox(height: AppTheme.space12),
                  Row(
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        color: Colors.white60,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Distance',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _distance,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
        ),

        // Bottom Right Speedometer — aurora glow disc
        Positioned(
          bottom: 32 + MediaQuery.of(context).padding.bottom,
          right: 16,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  AppTheme.indigoDeep,
                  AppTheme.blueVivid,
                  AppTheme.cyanBright,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.blueVivid.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: AppTheme.cyanBright.withValues(alpha: 0.30),
                  blurRadius: 32,
                  offset: const Offset(0, 4),
                  spreadRadius: 2,
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
                    letterSpacing: -0.5,
                  ),
                ),
                const Text(
                  'km/h',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          )
              .animate(target: isMoving ? 1 : 0)
              .scale(
                begin: const Offset(0.92, 0.92),
                end: const Offset(1, 1),
                duration: 600.ms,
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
                  horizontal: AppTheme.space12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(
                    color: AppTheme.blueVivid.withValues(alpha: 0.30),
                    width: 1.2,
                  ),
                  boxShadow: AppTheme.shadowSM,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: AppTheme.bluePrimary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Refresh · 5s',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNoInternetOverlay() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.auroraHeaderGradient),
      child: Stack(
        children: [
          // Ambient glow blobs to match the rest of the chrome
          Positioned(
            top: -60,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: AppTheme.cyanBright.withValues(alpha: 0.30),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: AppTheme.indigoDeep.withValues(alpha: 0.50),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppTheme.glassOverlay),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: GlassCard(
                padding: const EdgeInsets.all(AppTheme.space24),
                backgroundColor: Colors.white.withValues(alpha: 0.96),
                elevation: GlassCardElevation.large,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.error.withValues(alpha: 0.30),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        color: AppTheme.error,
                        size: 40,
                      ),
                    )
                        .animate(
                          onPlay: (c) => c.repeat(reverse: true),
                        )
                        .scale(
                          duration: 1400.ms,
                          begin: const Offset(1, 1),
                          end: const Offset(1.06, 1.06),
                        ),
                    const SizedBox(height: AppTheme.space20),
                    Text(
                      context.l10n.noInternetTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      context.l10n.trackingNoInternetBody,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _hasNetworkError = false;
                            _isLoading = true;
                          });
                          _controller?.reload();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: Text(
                          context.l10n.commonRetry,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 0.4,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.blueVivid,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(220, 52),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMD),
                          ),
                          shadowColor: AppTheme.blueVivid,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
