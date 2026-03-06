import 'dart:async';

import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../../core/theme/app_colors.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _online = true;
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    ConnectivityService.instance.checkConnectivity().then((v) {
      if (mounted) setState(() => _online = v);
    });
    _sub = ConnectivityService.instance.onConnectivityChanged.listen((v) {
      if (mounted) setState(() => _online = v);
    });
    ConnectivityService.instance.startMonitoring();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_online) return const SizedBox.shrink();

    return SafeArea(
      child: Container(
        width: double.infinity,
        color: AppColors.error,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'لا يوجد اتصال بالإنترنت — الرجاء التحقق من الواي فاي أو بيانات الجوال',
                style: TextStyle(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () async {
                final ok = await ConnectivityService.instance.checkConnectivity();
                if (ok && mounted) setState(() => _online = true);
              },
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
