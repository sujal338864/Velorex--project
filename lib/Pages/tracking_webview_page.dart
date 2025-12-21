import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class TrackingWebViewPage extends StatefulWidget {
  final String url;
  final String title;
  const TrackingWebViewPage({Key? key, required this.url, required this.title})
      : super(key: key);

  @override
  State<TrackingWebViewPage> createState() => _TrackingWebViewPageState();
}

class _TrackingWebViewPageState extends State<TrackingWebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // ✅ Choose correct platform implementation
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = const PlatformWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) => NavigationDecision.navigate,
      ))
     ..loadRequest(
  Uri.parse(
    widget.url.startsWith('http')
        ? widget.url
        : 'https://${widget.url}'
  ),
);


    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
