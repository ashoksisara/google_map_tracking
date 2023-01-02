import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_delivery_demo/map_provider.dart';
import 'package:google_map_delivery_demo/map_view.dart';
import 'package:google_map_delivery_demo/secrets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'dart:math' show asin, atan, cos, sqrt;

import 'package:vector_math/vector_math.dart' as vector;

void main() {
  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MapProvider(),)
      ],child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Maps',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const MapView(),
    );
  }
}

// class MapView extends StatefulWidget {
//   const MapView({Key? key}) : super(key: key);
//
//   @override
//   MapViewState createState() => MapViewState();
// }
//
// class MapViewState extends State<MapView> with TickerProviderStateMixin{
//   final CameraPosition _initialLocation = const CameraPosition(target: LatLng(0.0, 0.0));
//   late GoogleMapController mapController;
//
//   late Position _currentPosition;
//   String _currentAddress = '';
//
//   final startAddressController = TextEditingController();
//   final destinationAddressController = TextEditingController();
//
//   final startAddressFocusNode = FocusNode();
//   final desrinationAddressFocusNode = FocusNode();
//
//   String _startAddress = '';
//   String _destinationAddress = '';
//   String? _placeDistance;
//
//   Set<Marker> markers = {};
//    // List<Marker> _markers = [];
//
//   // Animation<double>? _animation;
//   // AnimationController? animationController;
//
//   late PolylinePoints polylinePoints;
//   Map<PolylineId, Polyline> polylines = {};
//   List<LatLng> polylineCoordinates = [];
//
//   final _scaffoldKey = GlobalKey<ScaffoldState>();
//
//   // final _mapMarkerSC = StreamController<List<Marker>>();
//
//   // StreamSink<List<Marker>> get _mapMarkerSink => _mapMarkerSC.sink;
//
//   // Stream<List<Marker>> get mapMarkerStream => _mapMarkerSC.stream;
//
//   Widget _textField({
//     required TextEditingController controller,
//     required FocusNode focusNode,
//     required String label,
//     required String hint,
//     required double width,
//     required Icon prefixIcon,
//     Widget? suffixIcon,
//     required Function(String) locationCallback,
//   }) {
//     return SizedBox(
//       width: width * 0.8,
//       child: TextField(
//         onChanged: (value) {
//           locationCallback(value);
//         },
//         controller: controller,
//         focusNode: focusNode,
//         decoration:  InputDecoration(
//           prefixIcon: prefixIcon,
//           suffixIcon: suffixIcon,
//           labelText: label,
//           filled: true,
//           fillColor: Colors.white,
//           enabledBorder: OutlineInputBorder(
//             borderRadius: const BorderRadius.all(
//               Radius.circular(10.0),
//             ),
//             borderSide: BorderSide(
//               color: Colors.grey.shade400,
//               width: 2,
//             ),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: const BorderRadius.all(
//               Radius.circular(10.0),
//             ),
//             borderSide: BorderSide(
//               color: Colors.blue.shade300,
//               width: 2,
//             ),
//           ),
//           contentPadding: const EdgeInsets.all(15),
//           hintText: hint,
//         ),
//       ),
//     );
//   }
//
//   // Method for retrieving the current location
//   _getCurrentLocation() async {
//
//     bool serviceEnabled;
//     LocationPermission permission;
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return Future.error('Location services are disabled.');
//     }
//
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return Future.error('Location permissions are denied');
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       return Future.error(
//           'Location permissions are permanently denied, we cannot request permissions.');
//     }
//
//
//     await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
//         .then((Position position) async {
//       setState(() {
//         _currentPosition = position;
//         debugPrint('CURRENT POS: $_currentPosition');
//         mapController.animateCamera(
//           CameraUpdate.newCameraPosition(
//             CameraPosition(
//               target: LatLng(position.latitude, position.longitude),
//               zoom: 18.0,
//             ),
//           ),
//         );
//       });
//       await _getAddress();
//     }).catchError((e) {
//       debugPrint(e.toString());
//     });
//   }
//
//   // Method for retrieving the address
//   _getAddress() async {
//     try {
//       List<Placemark> p = await placemarkFromCoordinates(
//           _currentPosition.latitude, _currentPosition.longitude);
//
//       Placemark place = p[0];
//
//       setState(() {
//         _currentAddress =
//             "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
//         startAddressController.text = _currentAddress;
//         _startAddress = _currentAddress;
//       });
//     } catch (e) {
//       debugPrint(e.toString());
//     }
//   }
//
//   LatLng? _previousStart;
//
//   // Method for calculating the distance between two places
//   Future<bool> _calculateDistance(LatLng startingLatLng , bool isFirst) async {
//     try {
//       // Retrieving placemarks from addresses
//       List<Location> startPlacemark = await locationFromAddress(_startAddress);
//       List<Location> destinationPlacemark =
//           await locationFromAddress(_destinationAddress);
//
//       // Use the retrieved coordinates of the current position,
//       // instead of the address if the start position is user's
//       // current position, as it results in better accuracy.
//       double startLatitude = startingLatLng.latitude;
//
//       double startLongitude = startingLatLng.longitude;
//
//       double destinationLatitude = destinationPlacemark[0].latitude;
//       double destinationLongitude = destinationPlacemark[0].longitude;
//
//       // String startCoordinatesString = '($startLatitude, $startLongitude)';
//       String destinationCoordinatesString =
//           '($destinationLatitude, $destinationLongitude)';
//
//       String  startCoordinatesString = 'startId';
//
//       // Start Location Marker
//       Marker startMarker = Marker(
//         markerId: MarkerId(startCoordinatesString),
//         position: LatLng(startLatitude, startLongitude),
//         infoWindow: InfoWindow(
//           title: 'Start $startCoordinatesString',
//           snippet: _startAddress,
//         ),
//         icon: BitmapDescriptor.defaultMarker,
//       );
//
//       // Destination Location Marker
//       Marker destinationMarker = Marker(
//         markerId: MarkerId(destinationCoordinatesString),
//         position: LatLng(destinationLatitude, destinationLongitude),
//         infoWindow: InfoWindow(
//           title: 'Destination $destinationCoordinatesString',
//           snippet: _destinationAddress,
//         ),
//         icon: BitmapDescriptor.defaultMarker,
//       );
//
//       // Adding the markers to the list
//       // debugPrint('markers: ${_markers.length}',);
//
//
//       markers.removeWhere((element) => element.markerId != MarkerId(destinationCoordinatesString));
//       markers.add(startMarker);
//       markers.add(destinationMarker);
//
//       // _markers.add(startMarker);
//       // _markers.add(destinationMarker);
//       // _mapMarkerSink.add(_markers);
//
//
//
//       // if(!isFirst){
//       //   startMarkerListener(startingLatLng, LatLng(destinationLatitude, destinationLongitude));
//       //   animationController!.forward();
//       // }
//
//       debugPrint(
//         'START COORDINATES: ($startLatitude, $startLongitude)',
//       );
//       debugPrint(
//         'DESTINATION COORDINATES: ($destinationLatitude, $destinationLongitude)',
//       );
//
//       // Calculating to check that the position relative
//       // to the frame, and pan & zoom the camera accordingly.
//       double miny = (startLatitude <= destinationLatitude)
//           ? startLatitude
//           : destinationLatitude;
//       double minx = (startLongitude <= destinationLongitude)
//           ? startLongitude
//           : destinationLongitude;
//       double maxy = (startLatitude <= destinationLatitude)
//           ? destinationLatitude
//           : startLatitude;
//       double maxx = (startLongitude <= destinationLongitude)
//           ? destinationLongitude
//           : startLongitude;
//
//       double southWestLatitude = miny;
//       double southWestLongitude = minx;
//
//       double northEastLatitude = maxy;
//       double northEastLongitude = maxx;
//
//       // Accommodate the two locations within the
//       // camera view of the map
//       mapController.animateCamera(
//         CameraUpdate.newLatLngBounds(
//           LatLngBounds(
//             northeast: LatLng(northEastLatitude, northEastLongitude),
//             southwest: LatLng(southWestLatitude, southWestLongitude),
//           ),
//           100.0,
//         ),
//       );
//
//       // Calculating the distance between the start and the end positions
//       // with a straight path, without considering any route
//       // double distanceInMeters = await Geolocator.bearingBetween(
//       //   startLatitude,
//       //   startLongitude,
//       //   destinationLatitude,
//       //   destinationLongitude,
//       // );
//       String encodePoly = await getRouteCoordinates(LatLng(startLatitude, startLongitude),LatLng(destinationLatitude, destinationLongitude));
//       _createApiPolyLines(encodePoly);
//
//       // if(isFirst){
//       //   startMarkerListener(startingLatLng, LatLng(destinationLatitude, destinationLongitude));
//       // }
//
//       // startMarkerListener(startingLatLng, _previousStart == null ? LatLng(_currentPosition.latitude, _currentPosition.longitude) : _previousStart!);
//       // animationController!.forward();
//       // _previousStart = startingLatLng;
//       // await updatePoly();
//
//       // await _createPolylines(startLatitude, startLongitude, destinationLatitude,
//       //     destinationLongitude);
//
//       double totalDistance = 0.0;
//
//       // Calculating the total distance by adding the distance
//       // between small segments
//       for (int i = 0; i < polylineCoordinates.length - 1; i++) {
//         totalDistance += _coordinateDistance(
//           polylineCoordinates[i].latitude,
//           polylineCoordinates[i].longitude,
//           polylineCoordinates[i + 1].latitude,
//           polylineCoordinates[i + 1].longitude,
//         );
//       }
//
//       setState(() {
//         _placeDistance = totalDistance.toStringAsFixed(2);
//         debugPrint('DISTANCE: $_placeDistance km');
//       });
//
//       return true;
//     } catch (e) {
//       debugPrint(e.toString());
//     }
//     return false;
//   }
//
//
//   // Formula for calculating distance between two coordinates
//   // https://stackoverflow.com/a/54138876/11910277
//   double _coordinateDistance(lat1, lon1, lat2, lon2) {
//     var p = 0.017453292519943295;
//     var c = cos;
//     var a = 0.5 -
//         c((lat2 - lat1) * p) / 2 +
//         c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
//     return 12742 * asin(sqrt(a));
//   }
//
//   // Create the polylines for showing the route between two places
//   _createPolylines(
//     double startLatitude,
//     double startLongitude,
//     double destinationLatitude,
//     double destinationLongitude,
//   ) async {
//     polylinePoints = PolylinePoints();
//     PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
//       Secrets.API_KEY, // Google Maps API Key
//       PointLatLng(startLatitude, startLongitude),
//       PointLatLng(destinationLatitude, destinationLongitude),
//       travelMode: TravelMode.transit,
//     );
//
//     if (result.points.isNotEmpty) {
//       for (var point in result.points) {
//         polylineCoordinates.add(LatLng(point.latitude, point.longitude));
//       }
//     }
//
//     PolylineId id = const PolylineId('poly');
//     Polyline polyline = Polyline(
//       polylineId: id,
//       color: Colors.red,
//       points: polylineCoordinates,
//       width: 3,
//     );
//     polylines[id] = polyline;
//   }
//
//   _createApiPolyLines(encodedPoly){
//
//     PolylineId id = const PolylineId('poly');
//
//     polylines[id] = Polyline(
//         polylineId: id,//pass any string here
//         width: 3,
//         geodesic: true,
//         points: convertToLatLng(decodePoly(encodedPoly)),
//         color: Colors.black);
//     setState(() {    });
//   }
//
//   // updatePolyLines() async {
//   //   await Future.delayed(const Duration(seconds: 10), () async {
//   //
//   //     startAddressFocusNode.unfocus();
//   //     desrinationAddressFocusNode.unfocus();
//   //     setState(() {
//   //       if (markers.isNotEmpty) markers.clear();
//   //       if (polylines.isNotEmpty) {
//   //         polylines.clear();
//   //       }
//   //       if (polylineCoordinates.isNotEmpty) {
//   //         polylineCoordinates.clear();
//   //       }
//   //       _placeDistance = null;
//   //     });
//   //
//   //     _calculateDistance().then((isCalculated) {
//   //       if (isCalculated) {
//   //         ScaffoldMessenger.of(context)
//   //             .showSnackBar(
//   //           const SnackBar(
//   //             content: Text(
//   //                 'Distance Calculated Sucessfully'),
//   //           ),
//   //         );
//   //       } else {
//   //         ScaffoldMessenger.of(context)
//   //             .showSnackBar(
//   //           const SnackBar(
//   //             content:  Text(
//   //                 'Error Calculating Distance'),
//   //           ),
//   //         );
//   //       }
//   //     });
//   //
//   //     print('after 10 sec updatePolyLines----------------------------------------------');
//   //
//   //     List<Location> destinationPlacemark =
//   //         await locationFromAddress(_destinationAddress);
//   //
//   //     double destinationLatitude = destinationPlacemark[0].latitude;
//   //     double destinationLongitude = destinationPlacemark[0].longitude;
//   //
//   //     await _createPolylines(
//   //       21.705723,
//   //       72.998199,
//   //       destinationLatitude,
//   //       destinationLongitude,
//   //     );
//   //   });
//   // }
//
//   updatePoly() async{
//     List<Location> startPlacemark = await locationFromAddress(_startAddress);
//     List<Location> destinationPlacemark = await locationFromAddress(_destinationAddress);
//     double startLatitude = _startAddress == _currentAddress
//         ? _currentPosition.latitude
//         : startPlacemark[0].latitude;
//
//     double startLongitude = _startAddress == _currentAddress
//         ? _currentPosition.longitude
//         : startPlacemark[0].longitude;
//     double destinationLatitude = destinationPlacemark[0].latitude;
//     double destinationLongitude = destinationPlacemark[0].longitude;
//     debugPrint('-->   updatePoly  >');
//
//     polylinePoints = PolylinePoints();
//     PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
//       Secrets.API_KEY, // Google Maps API Key
//       PointLatLng(startLatitude, startLongitude),
//       PointLatLng(destinationLatitude, destinationLongitude),
//       travelMode: TravelMode.driving,
//     );
//
//     if (result.points.isNotEmpty) {
//       for (var point in result.points) {
//         polylineCoordinates.add(LatLng(point.latitude, point.longitude));
//       }
//     }
//
//     debugPrint('-->polylineCoordinates length ${polylineCoordinates.length}----->');
//
//     for(int i = 0; i< polylineCoordinates.length; i++){
//       debugPrint('-->i -> $i');
//       await Future.delayed(const Duration(seconds: 5),() async{
//         debugPrint('-->updatePoly after 10s ------------------------->');
//
//         _calculateDistance(polylineCoordinates[i + 20],false);
//       });
//     }
//
//   }
//
//   _onTapShowRoute() async{
//     startAddressFocusNode.unfocus();
//     desrinationAddressFocusNode.unfocus();
//     setState(() {
//       if (markers.isNotEmpty) markers.clear();
//       if (polylines.isNotEmpty) {
//         polylines.clear();
//       }
//       if (polylineCoordinates.isNotEmpty) {
//         polylineCoordinates.clear();
//       }
//       _placeDistance = null;
//     });
//
//     _calculateDistance(LatLng(_currentPosition.latitude, _currentPosition.longitude),true).then((isCalculated) {
//       if (isCalculated) {
//         ScaffoldMessenger.of(context)
//             .showSnackBar(
//           const SnackBar(
//             content: Text(
//                 'Distance Calculated Sucessfully'),
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context)
//             .showSnackBar(
//           const SnackBar(
//             content:  Text(
//                 'Error Calculating Distance'),
//           ),
//         );
//       }
//     });
//     await Future.delayed(const Duration(seconds: 10),(){
//       updatePoly();
//     });
//
//   }
//
//   Future<String> getRouteCoordinates(LatLng l1, LatLng l2) async {
//     debugPrint('<<<<<---------getRouteCoordinates------->>>>');
//     String url =
//         "https://maps.googleapis.com/maps/api/directions/json?origin=${l1.latitude},${l1.longitude}&destination=${l2.latitude},${l2.longitude}&key=${Secrets.API_KEY}";
//     http.Response response = await http.get(Uri.parse(url));
//     Map<String,dynamic> values = jsonDecode(response.body);
//     log('Predictions----->>>>>>> ${values["routes"][0]["overview_polyline"]["points"]}');
//     // model.Model m = model.Model.fromJson(values);
//     // log('model.Model >>>>>>> ${m.routes?.first.legs?.first.steps?.length}');
//     // if(m.routes?.first.legs?.first.steps != null){
//     //   for (var element in m.routes!.first.legs!.first.steps!) {
//     //     polylineCoordinates.add(LatLng(element.endLocation?.lat ?? 0, element.endLocation?.lng ?? 0));
//     //   }
//     // }
//     return values["routes"][0]["overview_polyline"]["points"];
//   }
//
//   static List decodePoly(String poly) {
//     var list = poly.codeUnits;
//     var lList =  [];
//     int index = 0;
//     int len = poly.length;
//     int c = 0;
//     // repeating until all attributes are decoded
//     do {
//       var shift = 0;
//       int result = 0;
//
//       // for decoding value of one attribute
//       do {
//         c = list[index] - 63;
//         result |= (c & 0x1F) << (shift * 5);
//         index++;
//         shift++;
//       } while (c >= 32);
//       /* if value is negative then bitwise not the value */
//       if (result & 1 == 1) {
//         result = ~result;
//       }
//       var result1 = (result >> 1) * 0.00001;
//       lList.add(result1);
//     } while (index < len);
//
//     /*adding to previous value as done in encoding */
//     for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];
//
//     print(lList.toString());
//
//     return lList;
//   }
//
//   static List<LatLng> convertToLatLng(List points) {
//     List<LatLng> result = <LatLng>[];
//     for (int i = 0; i < points.length; i++) {
//       if (i % 2 != 0) {
//         result.add(LatLng(points[i - 1], points[i]));
//       }
//     }
//     return result;
//   }
//
//
//   // startMarkerListener(LatLng source, LatLng destination){
//   //   animationController = AnimationController(
//   //     duration: const Duration(seconds: 5),
//   //     vsync: this,
//   //   );
//   //
//   //   Tween<double> tween = Tween(begin: 0, end: 1);
//   //
//   //   _animation = tween.animate(animationController!)
//   //     ..addListener(() async {
//   //       //We are calculating new latitude and logitude for our marker
//   //       final v = _animation!.value;
//   //       double lng = v * source.longitude + (1 - v) * destination.longitude;
//   //       double lat = v * source.latitude  + (1 - v) * destination.latitude;
//   //       print('-->v -> $v');
//   //       print('-->v lng -> $lng');
//   //       print('-->v lat -> $lat');
//   //       LatLng newPos = LatLng(lat, lng);
//   //
//   //
//   //       String  startCoordinatesString = 'startId';
//   //
//   //       // Start Location Marker
//   //       Marker startMarker = Marker(
//   //         markerId: MarkerId(startCoordinatesString),
//   //         position: newPos,
//   //         infoWindow: InfoWindow(
//   //           title: 'Start $startCoordinatesString',
//   //           snippet: _startAddress,
//   //         ),
//   //         icon: BitmapDescriptor.defaultMarker,
//   //       );
//   //
//   //       //Removing old marker if present in the marker array
//   //       if (_markers.contains(startMarker)) _markers.remove(startMarker);
//   //
//   //
//   //       //Adding new marker to our list and updating the google map UI.
//   //       _markers.add(startMarker);
//   //       _mapMarkerSink.add(_markers);
//   //
//   //       //Moving the google camera to the new animated location.
//   //       // mapController.animateCamera(CameraUpdate.newCameraPosition(
//   //       //     CameraPosition(target: newPos, zoom: 15.5)));
//   //     });
//   // }
//
//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     var height = MediaQuery.of(context).size.height;
//     var width = MediaQuery.of(context).size.width;
//     return SafeArea(
//       child: SizedBox(
//         height: height,
//         width: width,
//         child: Scaffold(
//           key: _scaffoldKey,
//           body: Stack(
//             children: <Widget>[
//               // Map View
//               GoogleMap(
//                 markers: Set<Marker>.from(markers),
//                 initialCameraPosition: _initialLocation,
//                 myLocationEnabled: true,
//                 myLocationButtonEnabled: false,
//                 mapType: MapType.normal,
//                 zoomGesturesEnabled: true,
//                 zoomControlsEnabled: false,
//                 polylines: Set<Polyline>.of(polylines.values),
//                 onMapCreated: (GoogleMapController controller) {
//                   mapController = controller;
//                 },
//               ),
//               /// Show zoom buttons
//               zoomButtons(),
//               /// Show the place input fields & button for
//               /// showing the route
//               routeSearchField(width),
//               /// Show current location button
//               currentLocationButton(),
//             ],
//           ),
//         ),
//       ),
//     );
//
//   }
//
//   currentLocationButton(){
//     return SafeArea(
//       child: Align(
//         alignment: Alignment.bottomRight,
//         child: Padding(
//           padding: const EdgeInsets.only(right: 10.0, bottom: 10.0),
//           child: ClipOval(
//             child: Material(
//               color: Colors.orange.shade100, // button color
//               child: InkWell(
//                 splashColor: Colors.orange, // inkwell color
//                 child: const SizedBox(
//                   width: 56,
//                   height: 56,
//                   child: Icon(Icons.my_location),
//                 ),
//                 onTap: () {
//                   mapController.animateCamera(
//                     CameraUpdate.newCameraPosition(
//                       CameraPosition(
//                         target: LatLng(
//                           _currentPosition.latitude,
//                           _currentPosition.longitude,
//                         ),
//                         zoom: 18.0,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   routeSearchField(width){
//     return SafeArea(
//       child: Align(
//         alignment: Alignment.topCenter,
//         child: Padding(
//           padding: const EdgeInsets.only(top: 10.0),
//           child: Container(
//             decoration: const BoxDecoration(
//               color: Colors.white70,
//               borderRadius: BorderRadius.all(
//                 Radius.circular(20.0),
//               ),
//             ),
//             width: width * 0.9,
//             child: Padding(
//               padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: <Widget>[
//                   const Text(
//                     'Places',
//                     style: TextStyle(fontSize: 20.0),
//                   ),
//                   const SizedBox(height: 10),
//                   _textField(
//                       label: 'Start',
//                       hint: 'Choose starting point',
//                       prefixIcon: const Icon(Icons.looks_one),
//                       suffixIcon: IconButton(
//                         icon: const Icon(Icons.my_location),
//                         onPressed: () {
//                           startAddressController.text = _currentAddress;
//                           _startAddress = _currentAddress;
//                         },
//                       ),
//                       controller: startAddressController,
//                       focusNode: startAddressFocusNode,
//                       width: width,
//                       locationCallback: (String value) {
//                         setState(() {
//                           _startAddress = value;
//                         });
//                       }),
//                   const SizedBox(height: 10),
//                   _textField(
//                       label: 'Destination',
//                       hint: 'Choose destination',
//                       prefixIcon: const Icon(Icons.looks_two),
//                       controller: destinationAddressController,
//                       focusNode: desrinationAddressFocusNode,
//                       width: width,
//                       locationCallback: (String value) {
//                         setState(() {
//                           _destinationAddress = value;
//                         });
//                       }),
//                   const SizedBox(height: 10),
//                   Visibility(
//                     visible: _placeDistance == null ? false : true,
//                     child: Text(
//                       'DISTANCE: $_placeDistance km',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 5),
//                   ElevatedButton(
//                     onPressed: (_startAddress != '' &&
//                         _destinationAddress != '')
//                         ? () async {
//                       _onTapShowRoute();
//
//                       // updatePolyLines();
//
//                     } : null,
//                     style: ElevatedButton.styleFrom(
//                       primary: Colors.red,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20.0),
//                       ),
//                     ),
//                     child: Padding(
//                       padding: const  EdgeInsets.all(8.0),
//                       child: Text(
//                         'Show Route'.toUpperCase(),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 20.0,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   zoomButtons(){
//     return SafeArea(
//       child: Padding(
//         padding: const EdgeInsets.only(left: 10.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             ClipOval(
//               child: Material(
//                 color: Colors.blue.shade100, // button color
//                 child: InkWell(
//                   splashColor: Colors.blue, // inkwell color
//                   child: const SizedBox(
//                     width: 50,
//                     height: 50,
//                     child: Icon(Icons.add),
//                   ),
//                   onTap: () {
//                     mapController.animateCamera(
//                       CameraUpdate.zoomIn(),
//                     );
//                   },
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ClipOval(
//               child: Material(
//                 color: Colors.blue.shade100, // button color
//                 child: InkWell(
//                   splashColor: Colors.blue, // inkwell color
//                   child: const SizedBox(
//                     width: 50,
//                     height: 50,
//                     child: Icon(Icons.remove),
//                   ),
//                   onTap: () {
//                     mapController.animateCamera(
//                       CameraUpdate.zoomOut(),
//                     );
//                   },
//                 ),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//
//
// }
