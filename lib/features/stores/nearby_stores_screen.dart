import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class NearbyStoresScreen extends StatefulWidget {
  const NearbyStoresScreen({super.key});

  @override
  State<NearbyStoresScreen> createState() => _NearbyStoresScreenState();
}

class _NearbyStoresScreenState extends State<NearbyStoresScreen> {
  Position? userPosition;
  String? errorMessage;
  List<Map<String, dynamic>> closestStores = [];

  final List<Map<String, dynamic>> mockStores = [
    {'name': 'Joias da Ana', 'lat': -29.465, 'lng': -51.960},
    {'name': 'Studio Elegance', 'lat': -29.462, 'lng': -51.966},
    {'name': 'Cristal Luxo', 'lat': -29.470, 'lng': -51.957},
    {'name': 'Brilho Fino', 'lat': -29.468, 'lng': -51.959},
    {'name': 'Aliança Dourada', 'lat': -29.460, 'lng': -51.961},
  ];

  @override
  void initState() {
    super.initState();
    _loadNearbyStores();
  }

  Future<void> _loadNearbyStores() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('GPS está desativado. Ative nas configurações e tente novamente.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _setError('Permissão de localização negada.');
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition();
      final sortedStores = mockStores.map((store) {
        final distance = _calculateDistance(
          pos.latitude, pos.longitude, store['lat'], store['lng'],
        );
        return {...store, 'distance': distance};
      }).toList()
        ..sort((a, b) => a['distance'].compareTo(b['distance']));

      setState(() {
        userPosition = pos;
        closestStores = sortedStores.take(3).toList();
      });
    } catch (e) {
      _setError('Erro ao obter localização: $e');
    }
  }

  void _setError(String message) {
    if (mounted) {
      setState(() {
        errorMessage = message;
        userPosition = null;
        closestStores = [];
      });
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lojas Próximas")),
      body: errorMessage != null
          ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
          : userPosition == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: closestStores.length,
        itemBuilder: (context, index) {
          final store = closestStores[index];
          return ListTile(
            leading: const Icon(Icons.store),
            title: Text(store['name']),
            subtitle: Text('${store['distance'].toStringAsFixed(2)} km de você'),
          );
        },
      ),
    );
  }
}
