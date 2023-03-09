import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class LocationService{
  final String key = 'AIzaSyCvSYXWN6tZBh7zYyMgPn7Oip7CpRb4pQ8';

  Future<String> getPlaceID(String input) async {
    final String url = 'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$input&inputtype=textquery&key=$key';

    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);
    var placeID = json['candidates'][0]['place_id'] as String;

    print(placeID);

    return placeID;
  }

  Future<Map<String, dynamic>> getPlace(String input) async {
    final placeID = await getPlaceID(input);
    final String url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeID&key=$key';
    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);
    var results = json['result'] as Map<String, dynamic>;

    print(results);
    return results;

  } 

}