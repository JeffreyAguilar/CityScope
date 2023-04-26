import 'package:cityscope/yelp_features/data_model/rest/mod/review_rest_model.dart';
import 'package:cityscope/yelp_features/domain/mod/review.dart';
import 'package:cityscope/yelp_features/domain/mod/user.dart';

extension ReviewListMapper on List<ReviewRestModel> {
  List<Review> toDomainModels() {
    return map((review) => review.toDomainModel()).toList();
  }
}

extension ReviewMapper on ReviewRestModel {
  Review toDomainModel() {
    final User user = User(
      name: this.user.name,
      photoUrl: this.user.photoUrl ?? "",
    );

    return Review(
      user: user,
      text: this.text,
      rating: this.rating,
      timeCreated: this.timeCreated.substring(0, 10),
    );
  }
}