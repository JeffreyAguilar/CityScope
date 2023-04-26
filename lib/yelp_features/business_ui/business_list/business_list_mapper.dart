import 'package:collection/collection.dart';
import 'package:cityscope/yelp_features/domain/mod/business.dart';
import 'package:cityscope/yelp_features/business_ui/business_list/business_list_ui_model.dart';
import 'package:cityscope/yelp_features/business_ui/helper/business_helper.dart' as BusinessHelper;

extension BusinessListUiMapper on List<Business> {
  List<BusinessListUiModel> toUiModels() {
    return mapIndexed(
      (index, business) => BusinessListUiModel(
        id: business.id,
        name: "${index + 1}. ${business.name.toUpperCase()}",
        photoUrl: business.photoUrl,
        ratingImage: BusinessHelper.getRatingImage(business.rating),
        reviewCount: "${business.reviewCount} reviews", // TODO i18n
        address: business.address,
        priceAndCategories: BusinessHelper.formatPriceAndCategories(business.price, business.categories),
      ),
    ).toList();
  }
}