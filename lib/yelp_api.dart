import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> yelpAPICall() async {
  final String apiKey = 'EXtRnZ2H-NJDIcoG0pjVtA2r92D2ms_Bkwl4t3VGRro5RAqGX_lC_2MhUmuYTsnjlrhwd6aeCopx6GUIQLJ-_ZRY8ujX0tF7ehBZ9ILJdc-AUALkriY05R4PFJ0jZHYx';
  final String term = 'food';
  final String location = 'San Francisco';

  final String url = 'https://api.yelp.com/v3/businesses/search?term=$term&location=$location';

   final http.Response response =
      await http.get(Uri.parse(url), headers: {'Authorization': 'Bearer EXtRnZ2H-NJDIcoG0pjVtA2r92D2ms_Bkwl4t3VGRro5RAqGX_lC_2MhUmuYTsnjlrhwd6aeCopx6GUIQLJ-_ZRY8ujX0tF7ehBZ9ILJdc-AUALkriY05R4PFJ0jZHYx'});

        if (response.statusCode == 200) {
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    final List<dynamic> businesses = jsonResponse['businesses'];
    for (var business in businesses) {
      print(business['name']);
    }
  } else {
    print('Request failed with status: ${response.statusCode}.');
  }

}