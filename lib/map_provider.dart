import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;

class MapProvider extends ChangeNotifier{

  final LatLng suratLatLng = const LatLng(21.1702, 72.8311);
  final LatLng ahmedabadLatLng = const LatLng(23.0225, 72.5714);
  final CameraPosition initialCameraPosition =
      const CameraPosition(target: LatLng(21.1702, 72.8311),zoom: 14);
  Set<Marker> markers = {};
  GoogleMapController? controller;
  BitmapDescriptor? _markerIcon;

  void onMapCreated(GoogleMapController controller) {
    this.controller = controller;
  }

  //
  Future initData(BuildContext context) async{
    await _createMarkerImageFromAsset(context);
    _createMarker();
  }

  Future<void> _createMarkerImageFromAsset(BuildContext context) async {
    debugPrint('Creating marker......');
    ByteData data = await rootBundle.load('assets/car.jpg');
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: 140);
    ui.FrameInfo fi = await codec.getNextFrame();
    Uint8List  marker = (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    _markerIcon = BitmapDescriptor.fromBytes(marker);
  }


  void _createMarker() {
    Marker marker;
    if (_markerIcon != null) {
      marker = Marker(
        markerId: const MarkerId('marker_1'),
        position: suratLatLng,
        icon: _markerIcon!,
      );
    } else {
      marker = Marker(
        markerId: const MarkerId('marker_1'),
        position: suratLatLng,
      );
    }
    debugPrint('Marker set');
    markers.add(marker);
    notifyListeners();
  }
}