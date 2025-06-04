import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NearbyStoresMap extends StatefulWidget {
  const NearbyStoresMap({super.key});

  @override
  State<NearbyStoresMap> createState() => _NearbyStoresMapState();
}

class _NearbyStoresMapState extends State<NearbyStoresMap> {
  final Completer<GoogleMapController> _controller = Completer();
  Position? _userPosition;

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
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _userPosition = pos;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userPosition == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userLatLng = LatLng(_userPosition!.latitude, _userPosition!.longitude);

    final markers = <Marker>{
      ...mockStores.map((store) {
        return Marker(
          markerId: MarkerId(store['name']),
          position: LatLng(store['lat'], store['lng']),
          infoWindow: InfoWindow(title: store['name']),
        );
      }),
    };

    return Scaffold(
      appBar: AppBar(title: const Text("Mapa de Lojas")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: userLatLng, zoom: 14),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: markers,
        onMapCreated: (controller) => _controller.complete(controller),
      ),
    );
  }
}
