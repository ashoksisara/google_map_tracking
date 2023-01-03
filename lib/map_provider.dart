import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_map_delivery_demo/secrets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapProvider extends ChangeNotifier{

  final LatLng suratLatLng = const LatLng(21.1702, 72.8311);
  final LatLng kamrejLatLng = const LatLng(21.2695, 72.9577);
  final CameraPosition initialCameraPosition =
      const CameraPosition(target: LatLng(21.1702, 72.8311),zoom: 14);
  Set<Marker> markers = {};
  GoogleMapController? controller;
  BitmapDescriptor? _markerIcon;
  Map<PolylineId, Polyline> polyLines = {};
  List<LatLng> latLngList = [];
  TickerProvider? tickerProvider;
  bool isCarAnimating = false;
  int i = 1;
  bool showPlayButton = false;

  void onMapCreated(GoogleMapController controller) {
    this.controller = controller;
  }


  Future initData(BuildContext context,TickerProvider tickerProvider) async{
    await _createMarkerImageFromAsset(context);
    _createMarker();
    await setPolyLine(suratLatLng,kamrejLatLng);
    this.tickerProvider = tickerProvider;
    getRelativeMapFrame(suratLatLng,kamrejLatLng);
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
    Marker startMarker;
    Marker endMarker = Marker(
      markerId: const MarkerId('endMarker'),
      position: kamrejLatLng,
      flat: true,
      anchor: const Offset(0.5, 0.5),
    );
    if (_markerIcon != null) {
      startMarker = Marker(
        markerId: const MarkerId('startMarker'),
        position: suratLatLng,
        icon: _markerIcon!,
        flat: true,
        anchor: const Offset(0.5, 0.5),
      );
    } else {
      startMarker = Marker(
        markerId: const MarkerId('startMarker'),
        position: suratLatLng,
        anchor: const Offset(0.5, 0.5),
        flat: true
      );
    }
    debugPrint('Marker set');
    markers.add(startMarker);
    markers.add(endMarker);
    notifyListeners();
  }

  Future<void> _animateCamera(LatLng latLng) async {
    double zoomLevel = await controller!.getZoomLevel();
    final p = CameraPosition(target: latLng, zoom: zoomLevel);
    await controller!.animateCamera(CameraUpdate.newCameraPosition(p));
  }

  Future<String?> _getRouteCoordinates(LatLng l1, LatLng l2) async {
    debugPrint('Get Route Coordinates');
    try{
      String url =
          "https://maps.googleapis.com/maps/api/directions/json?origin=${l1.latitude},${l1.longitude}&destination=${l2.latitude},${l2.longitude}&key=${Secrets.API_KEY}";
      log('url : $url');
      http.Response response = await http.get(Uri.parse(url));
      Map<String, dynamic> values = jsonDecode(response.body);
      showPlayButton = true;
      return values["routes"][0]["overview_polyline"]["points"];
    }catch(e){
      debugPrint('Get Route Coordinates error : $e');
      showPlayButton = false;
      return null;
    }

  }

  Future<void> setPolyLine(LatLng l1, LatLng l2) async {
    String? pointsString = await _getRouteCoordinates(l1, l2);
    if(pointsString != null){
      List points = decodePoly(pointsString);
      latLngList.clear();
      latLngList = <LatLng>[];
      for (int i = 0; i < points.length; i++) {
        if (i % 2 != 0) {
          latLngList.add(LatLng(points[i - 1], points[i]));
        }
      }
      PolylineId id = const PolylineId('polyLineId');
      debugPrint('latLngList : ${latLngList.length}');
      polyLines[id] = Polyline(
          polylineId: id,
          width: 3,
          geodesic: true,
          points: latLngList,
          color: Colors.black);
      debugPrint('Polyline set');
    }else{
      debugPrint('Polyline not set');
    }
    notifyListeners();
  }

  List decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList =  [];
    int index = 0;
    int len = poly.length;
    int c = 0;
    // repeating until all attributes are decoded
    do {
      var shift = 0;
      int result = 0;

      // for decoding value of one attribute
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      /* if value is negative then bitwise not the value */
      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

    /*adding to previous value as done in encoding */
    for (var i = 2; i < lList.length; i++) {
      lList[i] += lList[i - 2];
    }
    debugPrint('lList : ${lList.length}');
    return lList;
  }

  void startTrackingVehicle() async{
    debugPrint('Vehicle tracking started');
    isCarAnimating = false;
    i = 1;
    animateCar(latLngList[0], latLngList[1]);
  }

  void animateCar(LatLng start, LatLng end) {
    try {
      AnimationController controller = AnimationController(
        vsync: tickerProvider!,
        duration: const Duration(seconds: 1),
      );
      Animation animation;
      var tween = Tween<double>(begin: 0, end: 1);
      animation = tween.animate(controller);

      animation.addStatusListener((status) async {
        if (status == AnimationStatus.completed) {
          i++;
          if(i != latLngList.length){
            double zoomLevel = await this.controller!.getZoomLevel();
            debugPrint('zoomLevel : $zoomLevel');
            if(zoomLevel >= 14){
              _animateCamera(latLngList[i]);
            }
            animateCar(end, latLngList[i]);
          }else{
            isCarAnimating = false;
            showPlayButton = true;
          }
        } else if (status == AnimationStatus.forward) {
          isCarAnimating = true;
          showPlayButton = false;
        }
      });
      controller.forward();
      var bearing = getBearing(start, end);

      animation.addListener(() async {
        var v = animation.value;
        var lng = v * end.longitude + (1 - v) * start.longitude;
        var lat = v * end.latitude + (1 - v) * start.latitude;

        var latLng = LatLng(lat, lng);
        await updateMarker(latLng, bearing);
      });
    } catch (e) {
      debugPrint('animateCar error : $e');
    }
  }

  Future<void> updateMarker(LatLng position, double rotation) async {
    markers.removeWhere((e) => e.markerId == const MarkerId('startMarker'));
    Marker startMarker = Marker(
      markerId: const MarkerId('startMarker'),
      position: position,
      rotation: rotation,
      icon: _markerIcon!,
      anchor: const Offset(0.5, 0.5),
      flat: true
    );
    markers.add(startMarker);
    notifyListeners();
  }

  double getBearing(LatLng start, LatLng end) {
    var lat1 = start.latitude * math.pi / 180;
    var lng1 = start.longitude * math.pi / 180;
    var lat2 = end.latitude * math.pi / 180;
    var lng2 = end.longitude * math.pi / 180;

    var dLon = (lng2 - lng1);
    var y = math.sin(dLon) * math.cos(lat2);
    var x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    var bearing = math.atan2(y, x);
    bearing = (bearing * 180) / math.pi;
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  void getRelativeMapFrame(LatLng start, LatLng end){
        double startLatitude = start.latitude;
        double startLongitude = start.longitude;
        double destinationLatitude = end.latitude;
        double destinationLongitude = end.longitude;
          double miny = (startLatitude <= destinationLatitude)
          ? startLatitude
          : destinationLatitude;
      double minx = (startLongitude <= destinationLongitude)
          ? startLongitude
          : destinationLongitude;
      double maxy = (startLatitude <= destinationLatitude)
          ? destinationLatitude
          : startLatitude;
      double maxx = (startLongitude <= destinationLongitude)
          ? destinationLongitude
          : startLongitude;

      double southWestLatitude = miny;
      double southWestLongitude = minx;

      double northEastLatitude = maxy;
      double northEastLongitude = maxx;

      controller!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            northeast: LatLng(northEastLatitude, northEastLongitude),
            southwest: LatLng(southWestLatitude, southWestLongitude),
          ),
          100.0,
        ),
      );
  }

}