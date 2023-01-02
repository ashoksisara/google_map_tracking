import 'package:flutter/material.dart';
import 'package:google_map_delivery_demo/map_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        final provider = Provider.of<MapProvider>(context, listen: false);
        provider.initData(context);
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, provider, child) {
        return GoogleMap(
          markers: provider.markers,
          initialCameraPosition: provider.initialCameraPosition,
          onMapCreated: provider.onMapCreated,
        );
      },
    );
  }
}
