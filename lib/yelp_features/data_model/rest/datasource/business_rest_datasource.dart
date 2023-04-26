import 'package:cityscope/core/const.dart' as Const;
import 'package:cityscope/core/network.dart';
import 'package:cityscope/yelp_features/data_model/rest/mod/business_rest_model.dart';
import 'package:cityscope/yelp_features/data_model/rest/mod/review_rest_model.dart';

class BusinessRestDataSource {
  final YelpHttpClient client;

  BusinessRestDataSource(this.client);

  Future<BusinessListRestModel> getBusinessList(String term, String location, String sortBy, int limit) {
    // TODO add try/catch
    final String url = "${Const.URL_REST}/businesses/search?term=$term&location=$location&sortBy=$sortBy&limit=$limit";
    return client.getData(url, (json) => BusinessListRestModel.fromJson(json));
  }

  Future<BusinessRestModel> getBusinessDetails(String businessId) {
    // TODO add try/catch
    String url = "${Const.URL_REST}/businesses/$businessId";
    return client.getData(url, (json) => BusinessRestModel.fromJson(json));
  }

  Future<ReviewListRestModel> getBusinessReviews(String businessId) {
    // TODO add try/catch
    String url = "${Const.URL_REST}/businesses/$businessId/reviews";
    return client.getData(url, (json) => ReviewListRestModel.fromJson(json));
  }
}