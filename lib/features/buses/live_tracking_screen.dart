import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  @override
  void initState() {
    super.initState();
    
    // Modify URL for Google Maps default if possible
    String finalUrl = widget.url;
    if (finalUrl.contains('userMapType=open_streets')) {
      finalUrl = finalUrl.replaceAll('userMapType=open_streets', 'userMapType=google_streets');
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'SpeedChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (mounted && message.message.isNotEmpty) {
            setState(() {
              _speed = message.message;
            });
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
    super.dispose();
  }

  void _applyCustomChanges() {
    _hideSideInfo();
    _removeCheckboxes();
    _setRefreshInterval();
    _setupSpeedTracking();
  }

  void _setupSpeedTracking() {
    const js = """
      (function() {
        function getSpeed() {
          // Check for elements containing "km/h" - searching deep
          var allElements = document.getElementsByTagName('*');
          for (var i = 0; i < allElements.length; i++) {
            var el = allElements[i];
            if (el.children.length === 0) { // Only check leaf nodes for precision
              var text = el.textContent || el.innerText;
              if (text && /\\d+\\s*km\\/h/i.test(text)) {
                 var match = text.match(/(\\d+\\s*km\\/h)/i);
                 if (match) return match[0];
              }
            }
          }
          
          // Strategy 2: Look for 'Speed' label and check its parent's siblings
          for (var i = 0; i < allElements.length; i++) {
             var el = allElements[i];
             var text = el.textContent || el.innerText;
             if (text && text.trim() === 'Speed') {
                // Try siblings or parent siblings
                var parent = el.parentElement;
                if (parent) {
                   var next = parent.querySelector('td:last-child, span:last-child, div:last-child');
                   if (next && /\\d+/.test(next.textContent)) return next.textContent.trim() + ' km/h';
                }
             }
          }
          return null;
        }

        setInterval(function() {
          var speed = getSpeed();
          if (speed && window.SpeedChannel) {
            window.SpeedChannel.postMessage(speed);
          }
        }, 1500); // More frequent checks
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
          [class*="check"], [class*="option"], .refresh-dropdown {
            display: none !important;
          }
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
                if (select.selectedIndex !== i) {
                   select.selectedIndex = i;
                   select.dispatchEvent(new Event('change'));
                }
                return true;
              }
            }
          }
          return false;
        };
        setRefresh();
        setInterval(setRefresh, 10000);
      })();
    """;
    _controller.runJavaScript(js);
  }

  void _hideSideInfo() {
    const js = """
      (function() {
        // Force immediate layout update
        window.dispatchEvent(new Event('resize'));

        var style = document.createElement('style');
        style.innerHTML = `
          /* Hiding side panels but keeping map full */
          .side-panel, .info-panel, #sidebar, .sidebar, 
          .details-panel, .control-panel, .right-section,
          .leaflet-sidebar, .leaflet-right.leaflet-bottom,
          [class*="sidebar"], [class*="side-panel"], [class*="info-panel"] {
            display: none !important;
            width: 0 !important;
          }
          
          /* Ensuring map fills the screen */
          body, html, #app, #map, .map-container, .main-content {
            width: 100% !important;
            height: 100% !important;
            position: absolute !important;
            top: 0 !important;
            left: 0 !important;
            margin: 0 !important;
            padding: 0 !important;
          }

          /* Fixing the grey area issue by forcing container height */
          .leaflet-container {
            height: 100vh !important;
          }
        `;
        document.head.appendChild(style);
        
        // Force map resize again after a delay
        setTimeout(function() {
           window.dispatchEvent(new Event('resize'));
           if (typeof map !== 'undefined' && map.invalidateSize) {
             map.invalidateSize();
           }
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
                if (await _controller.canGoBack()) {
                  _controller.goBack();
                } else {
                  if (mounted) Navigator.of(context).pop();
                }
              },
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  _buildSpeedOverlay(),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
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

  Widget _buildSpeedOverlay() {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: Colors.white24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.speed_rounded, color: Colors.white70, size: 20),
            const SizedBox(height: 4),
            Text(
              _speed.split(' ')[0],
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const Text(
              'km/h',
              style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ).animate(target: _speed == '0 km/h' ? 0 : 1).scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.busName,
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              _buildLivePulse(),
            ],
          ),
          Text('গতি: $_speed', style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: () => _controller.reload(),
        ),
      ],
      flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
    );
  }

  Widget _buildLivePulse() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red.withOpacity(0.5), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          ).animate(onPlay: (c) => c.repeat()).fade(duration: 800.ms, begin: 0.3, end: 1),
          const SizedBox(width: 4),
          const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

