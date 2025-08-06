import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onConnectivityRequired;

  const ConnectivityWrapper({
    Key? key,
    required this.child,
    this.onConnectivityRequired,
  }) : super(key: key);

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _listenToConnectivityChanges();
  }

  Future<void> _checkInitialConnectivity() async {
    final isConnected = await _connectivityService.hasInternetConnection();
    if (mounted) {
      setState(() {
        _isConnected = isConnected;
      });
    }
  }

  void _listenToConnectivityChanges() {
    _connectivityService.connectivityStream.listen((results) async {
      final hasConnection = await _connectivityService.hasInternetConnection();
      if (mounted && hasConnection != _isConnected) {
        setState(() {
          _isConnected = hasConnection;
        });
        _connectivityService.showConnectivitySnackbar(context, hasConnection);
      }
    });
  }

  Future<bool> validateConnectivity() async {
    final isConnected = await _connectivityService.hasInternetConnection();
    if (!isConnected) {
      _connectivityService.showNoInternetDialog(context);
      widget.onConnectivityRequired?.call();
    }
    return isConnected;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_isConnected)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
