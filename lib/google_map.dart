import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cityscope/models/auto_complete_model.dart';
import 'package:cityscope/providers/location_service.dart';
import 'package:cityscope/providers/search_places.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_rating_stars/flutter_rating_stars.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends ConsumerState<MapPage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

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
  var radiusValue = 500.0;
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

  final key = 'AIzaSyCvSYXWN6tZBh7zYyMgPn7Oip7CpRb4pQ8';

  /* _kGooglePlex's coordinates are the coordinates for NYIT's Manhattan Campus. */

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(40.76977, -73.98267),
    zoom: 17,
  );

  /* Due to unknown errors/bugs, current location tracking does not work after multiple attempts. */

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
      _setMarker(const LatLng(40.76977, -73.98267));
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
                        onTap: () {
                          setState(() {
                            searchToggle = true;
                          });
                        },
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
                                    await LocationService().searchPlaces(value);

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
                        circles: _circles,
                        initialCameraPosition: _kGooglePlex,
                        onMapCreated: (GoogleMapController controller) {
                          _controller.complete(controller);
                        },
                        onTap: (point) {
                          tappedPoint = point;
                          _setCircle(point);
                        },
                      ),
                      searchFlag.searchToggle
                          ? allSearchResults.allReturnedResults.isNotEmpty
                              ? Positioned(
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
                                            .map((e) =>
                                                buildListItem(e, searchFlag))
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
                                          const Text(
                                            'No Results Shown',
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
                                              child: const Text(
                                                'Close Window',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'WorkSans',
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                          : Container(),
                      getDirections
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  15.0, 40.0, 15.0, 5),
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
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 20.0,
                                                vertical: 15.0),
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
                                                          directions[
                                                                  'start_location']
                                                              ['lat'],
                                                          directions[
                                                                  'start_location']
                                                              ['lng'],
                                                          directions[
                                                                  'end_location']
                                                              ['lat'],
                                                          directions[
                                                                  'end_location']
                                                              ['lng'],
                                                          directions[
                                                              'bounds_ne'],
                                                          directions[
                                                              'bounds_sw']);
                                                      _setPolyline(directions[
                                                          'polyline_decoded']);
                                                    },
                                                    icon: const Icon(
                                                        Icons.search)),
                                                IconButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        getDirections = false;
                                                        _originController.text =
                                                            '';
                                                        _destinationController
                                                            .text = '';
                                                        _markers = {};
                                                        _polylines = {};
                                                      });
                                                    },
                                                    icon:
                                                        const Icon(Icons.close))
                                              ],
                                            ))),
                                  ),
                                )
                              ]),
                            )
                          : Container(),
                      radiusSlider
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  15.0, 30.0, 15.0, 0.0),
                              child: Container(
                                height: 50.0,
                                color: Colors.black.withOpacity(0.2),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: Slider(
                                            max: 1000.0,
                                            min: 100.0,
                                            value: radiusValue,
                                            onChanged: (newVal) {
                                              radiusValue = newVal;
                                              pressedNear = false;
                                              _setCircle(tappedPoint);
                                            })),
                                    !pressedNear
                                        ? IconButton(
                                            onPressed: () {
                                              if (_debounce?.isActive ??
                                                  false) {
                                                _debounce?.cancel();
                                              }
                                              _debounce = Timer(
                                                  const Duration(seconds: 2),
                                                  () async {
                                                var placesResult =
                                                    await LocationService()
                                                        .getPlaceDetails(
                                                            tappedPoint,
                                                            radiusValue
                                                                .toInt());

                                                List<dynamic> placesWithin =
                                                    placesResult['results']
                                                        as List;

                                                allFavoritePlaces =
                                                    placesWithin;

                                                tokenKey = placesResult[
                                                        'next_page_token'] ??
                                                    'none';
                                                _markers = {};
                                                placesWithin.forEach((element) {
                                                  _setNearMarker(
                                                    LatLng(
                                                        element['geometry']
                                                            ['location']['lat'],
                                                        element['geometry']
                                                                ['location']
                                                            ['lng']),
                                                    element['name'],
                                                    element['types'],
                                                    element['business_status'] ??
                                                        'not available',
                                                  );
                                                });
                                                _markersDupe = _markers;
                                                pressedNear = true;
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.search,
                                              color: Colors.blue,
                                            ))
                                        : IconButton(
                                            onPressed: () {
                                              if (_debounce?.isActive ??
                                                  false) {
                                                _debounce?.cancel();
                                              }
                                              _debounce = Timer(
                                                  const Duration(seconds: 2),
                                                  () async {
                                                if (tokenKey != 'none') {
                                                  var placesResult =
                                                      await LocationService()
                                                          .getMorePlaceDetails(
                                                              tokenKey);

                                                  List<dynamic> placesWithin =
                                                      placesResult['results']
                                                          as List;

                                                  allFavoritePlaces
                                                      .addAll(placesWithin);

                                                  tokenKey = placesResult[
                                                          'next_page_token'] ??
                                                      'none';

                                                  placesWithin
                                                      .forEach((element) {
                                                    _setNearMarker(
                                                      LatLng(
                                                          element['geometry']
                                                                  ['location']
                                                              ['lat'],
                                                          element['geometry']
                                                                  ['location']
                                                              ['lng']),
                                                      element['name'],
                                                      element['types'],
                                                      element['business_status'] ??
                                                          'not available',
                                                    );
                                                  });
                                                } else {
                                                  print('Showing results');
                                                }
                                              });
                                            },
                                            icon: const Icon(Icons.refresh,
                                                color: Colors.blue)),
                                    IconButton(
                                        onPressed: () {
                                          setState(() {
                                            radiusSlider = false;
                                            pressedNear = false;
                                            cardTapped = false;
                                            radiusValue = 500.0;
                                            _circles = {};
                                            _markers = {};
                                            allFavoritePlaces = [];
                                          });
                                        },
                                        icon: const Icon(Icons.close,
                                            color: Colors.red))
                                  ],
                                ),
                              ),
                            )
                          : Container(),
                      pressedNear
                          ? Positioned(
                              top: 400.0,
                              child: Container(
                                height: 200.0,
                                width: MediaQuery.of(context).size.width,
                                child: PageView.builder(
                                    controller: _pageController,
                                    itemCount: allFavoritePlaces.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      return _nearbyPlacesList(index);
                                    }),
                              ))
                          : Container(),
                          cardTapped
                          ? Positioned(
                            top: 100.0,
                            left: 7.0,
                            child: FlipCard(
                              front: Container(
                              height: 225.0,
                              width: 175.0,
                             decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 150.0,
                                        width: 175.0,
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            topRight: Radius.circular(8),
                                          ),
                                          image: DecorationImage(
                                            image: NetworkImage(
                                              placeImg != '' ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$placeImg&key=$key'
                                              : 'https://pic.onlinewebfonts.com/svg/img_546302.png'),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(7.0),
                                          width: 175.0,
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                        'Address: ',
                                        style: TextStyle(
                                            fontFamily: 'WorkSans',
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Container(
                                          width: 105.0,
                                          child: Text(
                                            tappedPlaceDetail[
                                                    'formatted_address'] ??
                                                'none given',
                                            style: const TextStyle(
                                                fontFamily: 'WorkSans',
                                                fontSize: 11.0,
                                                fontWeight: FontWeight.w400),
                                          ),
                                          ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.fromLTRB(7.0, 0.0, 7.0, 0.0),
                                          width: 175.0,
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                        'Contact: ',
                                        style: TextStyle(
                                            fontFamily: 'WorkSans',
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Container(
                                          width: 105.0,
                                          child: Text(
                                            tappedPlaceDetail[
                                                    'formatted_phone_number'] ??
                                                'none given',
                                            style: const TextStyle(
                                                fontFamily: 'WorkSans',
                                                fontSize: 11.0,
                                                fontWeight: FontWeight.w400),
                                          ))
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              back: Container(
                                height: 300.0,
                                width: 225.0,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                            isReviews = true;
                                            isPhotos = false;
                                          });
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 700),
                                              curve: Curves.easeIn,
                                              padding: const EdgeInsets.fromLTRB(7.0, 4.0, 7.0, 4.0),
                                              decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(11.0),
                                              color: isReviews
                                                  ? Colors.green.shade300
                                                  : Colors.white),
                                              child: Text(
                                                'Reviews',
                                                style: TextStyle(
                                                  color: isReviews
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontFamily: 'WorkSans',
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.w500
                                                ),
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                            isReviews = false;
                                            isPhotos = true;
                                          });
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 700),
                                              curve: Curves.easeIn,
                                              padding: const EdgeInsets.fromLTRB(7.0, 4.0, 7.0, 4.0),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                  BorderRadius.circular(11.0),
                                              color: isPhotos
                                                  ? Colors.green.shade300
                                                  : Colors.white
                                              ),
                                              child: Text(
                                                'Photos',
                                                style: TextStyle(
                                                  color: isPhotos
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontFamily: 'WorkSans',
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.w500
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      height: 250.0,
                                      child: isReviews ? ListView(
                                        children: [
                                          if (isReviews &&
                                                tappedPlaceDetail['reviews'] !=
                                                    null)
                                              ...tappedPlaceDetail['reviews']!
                                                  .map((e) {
                                                return _buildReviewItem(e);
                                              })
                                        ],
                                      ) : _buildPhotoGallery(tappedPlaceDetail['photos'] ?? []),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
          var place = await LocationService().getNearByPlace(placeItem.placeId);
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

  Future<void> moveCameraSlightly() async {
    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(
            allFavoritePlaces[_pageController.page!.toInt()]['geometry']
                    ['location']['lat'] +
                0.0125,
            allFavoritePlaces[_pageController.page!.toInt()]['geometry']
                    ['location']['lng'] +
                0.005),
        zoom: 14.0,
        bearing: 45.0,
        tilt: 45.0)));
  }

   _nearbyPlacesList(index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (BuildContext context, Widget? widget) {
        double value = 1;
        if (_pageController.position.haveDimensions) {
          value = (_pageController.page! - index);
          value = (1 - (value.abs() * 0.3) + 0.06).clamp(0.0, 1.0);
        }
        return Center(
          child: SizedBox(
            height: Curves.easeInOut.transform(value) * 125.0,
            width: Curves.easeInOut.transform(value) * 350.0,
            child: widget,
          ),
        );
      },
      child: InkWell(
        onTap: () async {
          cardTapped = !cardTapped;
          if (cardTapped) {
            tappedPlaceDetail = await LocationService()
                .getNearByPlace(allFavoritePlaces[index]['place_id']);
            setState(() {});
          }
          moveCameraSlightly();
        },
        child: Stack(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 20.0,
                ),
                height: 125.0,
                width: 275.0,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black54,
                          offset: Offset(0.0, 4.0),
                          blurRadius: 10.0)
                    ]),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Colors.white),
                  child: Row(
                    children: [
                      _pageController.position.haveDimensions
                          ? _pageController.page!.toInt() == index
                              ? Container(
                                  height: 90.0,
                                  width: 90.0,
                                  decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(10.0),
                                        topLeft: Radius.circular(10.0),
                                      ),
                                      image: DecorationImage(
                                          image: NetworkImage(placeImg != ''
                                              ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$placeImg&key=$key'
                                              : 'https://pic.onlinewebfonts.com/svg/img_546302.png'),
                                          fit: BoxFit.cover)),
                                )
                              : Container(
                                  height: 90.0,
                                  width: 20.0,
                                  decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(10.0),
                                        topLeft: Radius.circular(10.0),
                                      ),
                                      color: Colors.blue),
                                )
                          : Container(),
                      SizedBox(width: 5.0),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 170.0,
                            child: Text(allFavoritePlaces[index]['name'],
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    fontFamily: 'WorkSans',
                                    fontWeight: FontWeight.bold)),
                          ),
                          RatingStars(
                            value: allFavoritePlaces[index]['rating']
                                        .runtimeType ==
                                    int
                                ? allFavoritePlaces[index]['rating'] * 1.0
                                : allFavoritePlaces[index]['rating'] ?? 0.0,
                            starCount: 5,
                            starSize: 10,
                            valueLabelColor: const Color(0xff9b9b9b),
                            valueLabelTextStyle: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'WorkSans',
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                fontSize: 12.0),
                            valueLabelRadius: 10,
                            maxValue: 5,
                            starSpacing: 2,
                            maxValueVisibility: false,
                            valueLabelVisibility: true,
                            animationDuration: const Duration(milliseconds: 1000),
                            valueLabelPadding: const EdgeInsets.symmetric(
                                vertical: 1, horizontal: 8),
                            valueLabelMargin: const EdgeInsets.only(right: 8),
                            starOffColor: const Color(0xffe7e8ea),
                            starColor: Colors.yellow,
                          ),
                          Container(
                            width: 170.0,
                            child: Text(
                              allFavoritePlaces[index]['business_status'] ??
                                  'none',
                              style: TextStyle(
                                  color: allFavoritePlaces[index]
                                              ['business_status'] ==
                                          'OPERATIONAL'
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  _buildReviewItem(review) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
          child: Row(
            children: [
              Container(
                height: 35.0,
                width: 35.0,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                        image: NetworkImage(review['profile_photo_url']),
                        fit: BoxFit.cover)),
              ),
             const SizedBox(width: 4.0),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 160.0,
                  child: Text(
                    review['author_name'],
                    style: const TextStyle(
                        fontFamily: 'WorkSans',
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 3.0),
                RatingStars(
                  value: review['rating'] * 1.0,
                  starCount: 5,
                  starSize: 7,
                  valueLabelColor: const Color(0xff9b9b9b),
                  valueLabelTextStyle: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'WorkSans',
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.normal,
                      fontSize: 9.0),
                  valueLabelRadius: 7,
                  maxValue: 5,
                  starSpacing: 2,
                  maxValueVisibility: false,
                  valueLabelVisibility: true,
                  animationDuration: const Duration(milliseconds: 1000),
                  valueLabelPadding:
                      const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                  valueLabelMargin: const EdgeInsets.only(right: 4),
                  starOffColor: const Color(0xffe7e8ea),
                  starColor: Colors.yellow,
                )
              ])
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            child: Text(
              review['text'],
              style: const TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 11.0,
                  fontWeight: FontWeight.w400),
            ),
          ),
        ),
        Divider(color: Colors.grey.shade600, height: 1.0)
      ],
    );
  }

  _buildPhotoGallery(photoElement) {
    if (photoElement == null || photoElement.length == 0) {
      showBlankCard = true;
      return Container(
        child: const Center(
          child: Text(
            'No Photos',
            style: TextStyle(
                fontFamily: 'WorkSans',
                fontSize: 12.0,
                fontWeight: FontWeight.w500),
          ),
        ),
      );
    } else {
      var placeImg = photoElement[photoGalleryIndex]['photo_reference'];
      var maxWidth = photoElement[photoGalleryIndex]['width'];
      var maxHeight = photoElement[photoGalleryIndex]['height'];
      var tempDisplayIndex = photoGalleryIndex + 1;

      return Column(
        children: [
          const SizedBox(height: 10.0),
          Container(
              height: 200.0,
              width: 200.0,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  image: DecorationImage(
                      image: NetworkImage(
                          'https://maps.googleapis.com/maps/api/place/photo?maxwidth=$maxWidth&maxheight=$maxHeight&photo_reference=$placeImg&key=$key'),
                      fit: BoxFit.cover))),
          const SizedBox(height: 10.0),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  if (photoGalleryIndex != 0) {
                    photoGalleryIndex = photoGalleryIndex - 1;
                  } else {
                    photoGalleryIndex = 0;
                  }
                });
              },
              child: Container(
                width: 40.0,
                height: 20.0,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9.0),
                    color: photoGalleryIndex != 0
                        ? Colors.green.shade500
                        : Colors.grey.shade500),
                child: const Center(
                  child: Text(
                    'Prev',
                    style: TextStyle(
                        fontFamily: 'WorkSans',
                        color: Colors.white,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            Text(
              '$tempDisplayIndex/${photoElement.length}',
              style: const TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (photoGalleryIndex != photoElement.length - 1) {
                    photoGalleryIndex = photoGalleryIndex + 1;
                  } else {
                    photoGalleryIndex = photoElement.length - 1;
                  }
                });
              },
              child: Container(
                width: 40.0,
                height: 20.0,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9.0),
                    color: photoGalleryIndex != photoElement.length - 1
                        ? Colors.green.shade500
                        : Colors.grey.shade500),
                child: const Center(
                  child: Text(
                    'Next',
                    style: TextStyle(
                        fontFamily: 'WorkSans',
                        color: Colors.white,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ])
        ],
      );
    }
  }
}