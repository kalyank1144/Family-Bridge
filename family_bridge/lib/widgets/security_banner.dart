import 'package:flutter/material.dart';
import '../services/compliance/hipaa_physical.dart';

class SecurityBanner extends StatefulWidget {
  const SecurityBanner({super.key});

  @override
  State<SecurityBanner> createState() => _SecurityBannerState();
}

class _SecurityBannerState extends State<SecurityBanner> {
  Future<DeviceComplianceStatus>? _future;

  @override
  void initState() {
    super.initState();
    _future = HIPAAPhysical().deviceManager.checkDeviceCompliance('current_device');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DeviceComplianceStatus>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final s = snapshot.data!;
        if (s.isCompliant) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            border: Border(bottom: BorderSide(color: Colors.amber.shade200)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(child: Text('Device not fully compliant. Encryption: ${s.isEncrypted ? 'On' : 'Off'}, Passcode: ${s.hasPasscode ? 'On' : 'Off'}')),
            ],
          ),
        );
      },
    );
  }
}