import 'dart:async';
import 'package:cityscope/location_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final TextEditingController _searchController = TextEditingController();

  Set<Marker> _markers = Set<Marker>();
  Set<Polygon> _polygons = Set<Polygon>();
  List<LatLng> polygonLatLngs = <LatLng>[];
  int _polygonIDCounter = 1;
  bool serviceEnabled = false;
  bool hasPermission = false;
  late LocationPermission permission;
  late Position position;
  late StreamSubscription<Position> positionStream;
  static double lat = 0;
  static double long = 0;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(40.76977, -73.98267),
    zoom: 17,
  );

  static final CameraPosition _kCurrentLocation = CameraPosition(
    target: LatLng(lat, long),
    zoom: 17,
  );

  @override
  void initState() {
    checkGps();
    super.initState();
    _setMarker(LatLng(lat, long));
  }

  void _setMarker(LatLng point) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('marker'),
          position: point,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry radius = const BorderRadius.only(
      topLeft: Radius.circular(25.0),
      topRight: Radius.circular(25.0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Map',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromRGBO(143, 217, 201, 1.0),
      ),
      body: SlidingUpPanel(
        borderRadius: radius,
        minHeight: 35,
        maxHeight: 500,
        backdropEnabled: true,
        collapsed: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: radius,
          ),
          child: const Center(
            child: Icon(
              Icons.expand_less,
              color: Colors.black,
            ),
          ),
        ),
        panel: const Center(
          child: Text('This is the info tab'),
        ),
        body: Column(
          children: [
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Search'),
                    onChanged: (value) {
                      print(value);
                    },
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    var place = await LocationService()
                        .getPlace(_searchController.text);
                    _goToPlace(place);
                  },
                  icon: const Icon(Icons.search),
                ),
                IconButton(
                  onPressed: () async {},
                  icon: const Icon(Icons.directions_outlined),
                ),
              ],
            ),
            Expanded(
              child: GoogleMap(
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapType: MapType.normal,
                markers: _markers,
                polygons: _polygons,
                initialCameraPosition: _kCurrentLocation,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToPlace(Map<String, dynamic> place) async {
    final double lat = place['geometry']['location']['lat'];
    final double lng = place['geometry']['location']['lng'];

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: 16.5,
        ),
      ),
    );

    _setMarker(LatLng(lat, lng));
  }

  checkGps() async {
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
        } else if (permission == LocationPermission.deniedForever) {
          print("'Location permissions are permanently denied");
        } else {
          hasPermission = true;
        }
      } else {
        hasPermission = true;
      }

      if (hasPermission) {
        setState(() {
          //refresh the UI
        });

        getLocation();
      }
    } else {
      print("GPS Service is not enabled, turn on GPS location");
    }

    setState(() {
      //refresh the UI
    });
  }

  getLocation() async {
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print(position.longitude); //Output: 80.24599079
    print(position.latitude); //Output: 29.6593457

    lat = position.latitude;
    long = position.longitude;

    setState(() {
      //refresh UI
    });

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high, //accuracy of the location data
      distanceFilter: 100, //minimum distance (measured in meters) a
      //device must move horizontally before an update event is generated;
    );

    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      print(position.longitude); //Output: 80.24599079
      print(position.latitude); //Output: 29.6593457

      lat = position.latitude;
      long = position.longitude;

      setState(() {
        //refresh UI on update
      });
    });
  }
} //end of class MapSampleState file
