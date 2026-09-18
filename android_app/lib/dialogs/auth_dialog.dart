import 'package:flutter/material.dart';
import '../services/biometric_auth.dart';

void showBiometricSettingsDialog(
  BuildContext context,
  BiometricAuth biometricAuth,
  VoidCallback onChanged,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Biometric Authentication'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (biometricAuth.isBiometricAvailable)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available: ${biometricAuth.biometricName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Enable Biometric Login'),
                  subtitle: Text(
                    'Use ${biometricAuth.biometricName} to access your account',
                  ),
                  value: biometricAuth.isBiometricEnabled,
                  onChanged: (value) async {
                    Navigator.pop(ctx);
                    try {
                      if (value) {
                        await biometricAuth.enableBiometric();
                      } else {
                        await biometricAuth.disableBiometric();
                      }
                      onChanged();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            )
          else
            const Text(
              'Biometric authentication is not available on this device.',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Future<bool> showBiometricAuthDialog(
  BuildContext context,
  BiometricAuth biometricAuth,
) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Authenticate'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            biometricAuth.availableBiometrics.toString().contains('face')
                ? Icons.face
                : Icons.fingerprint,
            size: 48,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          Text('Tap to use ${biometricAuth.biometricName}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final result = await biometricAuth.authenticate();
            if (context.mounted) {
              Navigator.pop(ctx, result);
            }
          },
          child: const Text('Authenticate'),
        ),
      ],
    ),
  ).then((value) => value ?? false);
}
