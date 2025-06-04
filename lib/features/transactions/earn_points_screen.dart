import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fidelize_app/models/logged_user.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EarnPointsScreen extends StatefulWidget {
  const EarnPointsScreen({super.key});

  @override
  State<EarnPointsScreen> createState() => _EarnPointsScreenState();
}

class _EarnPointsScreenState extends State<EarnPointsScreen> {
  bool _hasScanned = false;
  final TextEditingController _codeController = TextEditingController();

  void _registerPoints() async {
    final user = LoggedUser.user;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': user.uid,
        'productId': null,
        'amount': 100,
        'date': Timestamp.now(),
      });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'points': user.points + 100,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pontos acumulados com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao acumular pontos.')),
      );
    }
  }

  void _handleManualCode() {
    if (_hasScanned) return;

    final code = _codeController.text.trim();
    if (code.isNotEmpty) {
      setState(() => _hasScanned = true);
      _registerPoints();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acumular Pontos')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (barcode) {
              if (!_hasScanned) {
                setState(() => _hasScanned = true);
                _registerPoints();
              }
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Aponte para o QR Code ou insira o código manualmente',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Digite o código',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _handleManualCode,
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
