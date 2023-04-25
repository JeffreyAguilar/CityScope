import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cityscope/models/auto_complete_model.dart';
import 'package:cityscope/providers/location_service.dart';
import 'package:cityscope/providers/search_places.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends ConsumerState<MapPage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final TextEditingController _searchController = TextEditingController();
  TextEditingController _originController = TextEditingController();
  TextEditingController _destinationController = TextEditingController();

  Timer? _debounce;

  Set<Marker> _markers = Set<Marker>();
  Set<Marker> _markersDupe = Set<Marker>();
  Set<Polyline> _polylines = Set<Polyline>();
  Set<Circle> _circles = Set<Circle>();
  List<LatLng> polygonLatLngs = <LatLng>[];
  int _markerIDCounter = 1;
  int _polylineIDCounter = 1;
  bool serviceEnabled = false;
  bool hasPermission = false;
  var radiusValue = 3000.0;
  var tappedPoint;
  late LocationPermission permission;
  late Position position;
  late StreamSubscription<Position> positionStream;
  static double lat = 0;
  static double long = 0;

  bool searchToggle = false;
  bool radiusSlider = false;
  bool cardTapped = false;
  bool pressedNear = false;
  bool getDirections = false;

  late PageController _pageController;
  int prevPage = 0;
  var tappedPlaceDetail;
  String placeImg = '';
  var photoGalleryIndex = 0;
  bool showBlankCard = false;
  bool isReviews = true;
  bool isPhotos = false;
  List allFavoritePlaces = [];
  String tokenKey = '';
  var selectedPlaceDetails;

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
    _pageController = PageController(initialPage: 1, viewportFraction: 0.85)
      ..addListener(_onScroll);
    _setMarker(LatLng(lat, long));
  }

  void _setMarker(LatLng point) {
    var counter = _markerIDCounter++;

    final Marker marker = Marker(
        markerId: MarkerId('marker_$counter'),
        position: point,
        onTap: () {},
        icon: BitmapDescriptor.defaultMarker);

    setState(() {
      _markers.add(marker);
    });
  }

  void _setPolyline(List<PointLatLng> points) {
    final String polylineIdVal = 'polyline_$_polylineIDCounter';

    _polylineIDCounter++;

    _polylines.add(Polyline(
        polylineId: PolylineId(polylineIdVal),
        width: 2,
        color: Colors.blue,
        points: points.map((e) => LatLng(e.latitude, e.longitude)).toList()));
  }

  void _setCircle(LatLng point) async {
    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: point, zoom: 12)));
    setState(() {
      _circles.add(Circle(
          circleId: const CircleId('User'),
          center: point,
          fillColor: Colors.blue.withOpacity(0.1),
          radius: radiusValue,
          strokeColor: Colors.blue,
          strokeWidth: 1));
      getDirections = false;
      searchToggle = false;
      radiusSlider = true;
    });
  }

  _setNearMarker(LatLng point, String label, List types, String status) async {
    var counter = _markerIDCounter++;

    final Uint8List markerIcon;

    if (types.contains('restaurants')) {
      markerIcon =
          await getBytesFromAsset('assets/mapicons/restaurant.png', 75);
    } else if (types.contains('food')) {
      markerIcon = await getBytesFromAsset('assets/mapicons/food.png', 75);
    } else if (types.contains('school')) {
      markerIcon = await getBytesFromAsset('assets/mapicons/school.png', 75);
    } else if (types.contains('bar')) {
      markerIcon = await getBytesFromAsset('assets/mapicons/bar.png', 75);
    } else if (types.contains('lodging')) {
      markerIcon = await getBytesFromAsset('assets/mapicons/hotel.png', 75);
    } else if (types.contains('store')) {
      markerIcon =
          await getBytesFromAsset('assets/mapicons/retail-stores.png', 75);
    } else if (types.contains('locality')) {
      markerIcon =
          await getBytesFromAsset('assets/mapicons/local-services.png', 75);
    } else {
      markerIcon = await getBytesFromAsset('assets/mapicons/places.png', 75);
    }

    final Marker marker = Marker(
        markerId: MarkerId('marker_$counter'),
        position: point,
        onTap: () {},
        icon: BitmapDescriptor.fromBytes(markerIcon));

    setState(() {
      _markers.add(marker);
    });
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);

    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  void _onScroll() {
    if (_pageController.page!.toInt() != prevPage) {
      prevPage = _pageController.page!.toInt();
      cardTapped = false;
      photoGalleryIndex = 1;
      showBlankCard = false;
      goToTappedPlace();
      fetchImage();
    }
  }

  void fetchImage() async {
    if (_pageController.page != null) {
      if (allFavoritePlaces[_pageController.page!.toInt()]['photos'] != null) {
        setState(() {
          placeImg = allFavoritePlaces[_pageController.page!.toInt()]['photos']
              [0]['photo_reference'];
        });
      } else {
        placeImg = '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry radius = const BorderRadius.only(
      topLeft: Radius.circular(25.0),
      topRight: Radius.circular(25.0),
    );

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final allSearchResults = ref.watch(placeResultsProvider);
    final searchFlag = ref.watch(searchToggleProvider);

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
        body: SingleChildScrollView(
          child: Container(
            height: screenHeight,
            width: screenWidth,
            child: Column(
              children: [
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _searchController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              hintText: 'Search',
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      searchToggle = false;

                                      _searchController.text = '';
                                      _markers = {};
                                      if (searchFlag.searchToggle) {
                                        searchFlag.toggleSearch();
                                      }
                                    });
                                  },
                                  icon: const Icon(Icons.close)),
                            ),
                            onChanged: (value) {
                              if (_debounce?.isActive ?? false) {
                                _debounce?.cancel();
                                _debounce = Timer(
                                    const Duration(
                                      milliseconds: 700,
                                    ), () async {
                                  if (value.length > 2) {
                                    if (!searchFlag.searchToggle) {
                                      searchFlag.toggleSearch();
                                      _markers = {};
                                    }
                                    List<AutoCompleteResult> searchResults =
                                        await LocationService()
                                            .searchPlaces(value);

                                    allSearchResults.setResults(searchResults);
                                  } else {
                                    List<AutoCompleteResult> emptyList = [];
                                    allSearchResults.setResults(emptyList);
                                  }
                                });
                              }
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
                          onPressed: () async {
                            setState(() {
                              getDirections = true;
                            });
                          },
                          icon: const Icon(Icons.directions_outlined),
                        ),
                      ],
                    ),
                Expanded(
                  child: Stack(
                    children: [
                      GoogleMap(
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        mapType: MapType.normal,
                        markers: _markers,
                        polylines: _polylines,
                        initialCameraPosition: _kGooglePlex,
                        onMapCreated: (GoogleMapController controller) {
                          _controller.complete(controller);
                        },
                        onTap: (point) {
                          tappedPoint = point;
                          _setCircle(point);
                        },
                      ),
                      searchFlag.searchToggle ? 
                      allSearchResults.allReturnedResults.length != 0 ?
                      Positioned(
                        top: 100.0,
                        left: 15.0,
                        child: Container(
                          height: 200.0,
                              width: screenWidth - 30.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: Colors.white.withOpacity(0.7),
                              ),
                              child: ListView(
                                children: [
                                  ...allSearchResults.allReturnedResults
                                      .map((e) => buildListItem(e, searchFlag))
                                ],
                              ),
                        ),
                      )
                      : Positioned(
                        top: 100.0,
                        left: 15.0,
                        child: Container(
                          height: 200.0,
                              width: screenWidth - 30.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: Colors.white.withOpacity(0.7),
                              ),
                              child: Center(
                                child: Column(
                                  children: <Widget>[
                                    const Text('No Results Shown',
                                    style: TextStyle(
                                      fontFamily: 'WorkSans',
                                      fontWeight: FontWeight.w400,
                                    ),
                                    ),
                                    const SizedBox(height: 5.0),
                                    Container(
                                      width: 125,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          searchFlag.toggleSearch();
                                        },
                                        child: const Text('Close Window',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'WorkSans',
                                      fontWeight: FontWeight.w300,
                                      ),),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ),
                      )
                      : Container(),
                      getDirections ? 
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15.0, 40.0, 15.0, 5),
                        child: Column(children: [
                          Container(
                            height: 50.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Colors.white,
                            ),
                            child: TextFormField(
                              controller: _originController,
                              decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 15.0),
                                  border: InputBorder.none,
                                  hintText: 'Origin'),
                            ),
                          ),
                          const SizedBox(height: 3.0),
                          Container(
                            height: 50.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Colors.white,
                            ),
                            child: TextFormField(
                              controller: _destinationController,
                              decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 15.0),
                                  border: InputBorder.none,
                                  hintText: 'Destination',
                                  suffixIcon: Container(
                                      width: 96.0,
                                      child: Row(
                                        children: [
                                          IconButton(
                                              onPressed: () async {
                                                var directions =
                                                    await LocationService()
                                                        .getDirections(
                                                            _originController
                                                                .text,
                                                            _destinationController
                                                                .text);
                                                _markers = {};
                                                _polylines = {};
                                                gotoPlace(
                                                    directions['start_location']
                                                        ['lat'],
                                                    directions['start_location']
                                                        ['lng'],
                                                    directions['end_location']
                                                        ['lat'],
                                                    directions['end_location']
                                                        ['lng'],
                                                    directions['bounds_ne'],
                                                    directions['bounds_sw']);
                                                _setPolyline(directions[
                                                    'polyline_decoded']);
                                              },
                                              icon: const Icon(Icons.search)),
                                          IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  getDirections = false;
                                                  _originController.text = '';
                                                  _destinationController.text =
                                                      '';
                                                  _markers = {};
                                                  _polylines = {};
                                                });
                                              },
                                              icon: const Icon(Icons.close))
                                        ],
                                      ))),
                            ),
                          )
                        ]),
                      )
                      : Container(),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

  gotoPlace(double lat, double lng, double endLat, double endLng,
      Map<String, dynamic> boundsNe, Map<String, dynamic> boundsSw) async {
    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
            southwest: LatLng(boundsSw['lat'], boundsSw['lng']),
            northeast: LatLng(boundsNe['lat'], boundsNe['lng'])),
        25));

    _setMarker(LatLng(lat, lng));
    _setMarker(LatLng(endLat, endLng));
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
      print(position.longitude);
      print(position.latitude);

      lat = position.latitude;
      long = position.longitude;

      setState(() {
        //refresh UI on update
      });
    });
  }

  Future<void> goToTappedPlace() async {
    final GoogleMapController controller = await _controller.future;

    _markers = {};

    var selectedPlace = allFavoritePlaces[_pageController.page!.toInt()];

    _setNearMarker(
        LatLng(selectedPlace['geometry']['location']['lat'],
            selectedPlace['geometry']['location']['lng']),
        selectedPlace['name'] ?? 'no name',
        selectedPlace['types'],
        selectedPlace['business_status'] ?? 'none');

    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(selectedPlace['geometry']['location']['lat'],
            selectedPlace['geometry']['location']['lng']),
        zoom: 14.0,
        bearing: 45.0,
        tilt: 45.0)));
  }

  Future<void> gotoSearchedPlace(double lat, double lng) async {
    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 12)));

    _setMarker(LatLng(lat, lng));
  }

  Widget buildListItem(AutoCompleteResult placeItem, searchFlag) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: GestureDetector(
        onTapDown: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onTap: () async {
          var place = await LocationService().getPlace(placeItem.placeId);
          gotoSearchedPlace(place['geometry']['location']['lat'],
              place['geometry']['location']['lng']);
          searchFlag.toggleSearch();
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, color: Colors.green, size: 25.0),
            const SizedBox(width: 4.0),
            Container(
              height: 40.0,
              width: MediaQuery.of(context).size.width - 75.0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(placeItem.description ?? ''),
              ),
            )
          ],
        ),
      ),
    );
  }


}
