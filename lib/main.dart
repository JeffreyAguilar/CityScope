import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cityscope/core/injection.dart' as Injection;
import 'package:cityscope/yelp_features/business_ui/business_list/business_list_bloc.dart';
import 'package:cityscope/yelp_features/business_ui/business_list/business_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Injection.setup();
  return runApp(CityScope());
}

class CityScope extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = ThemeData.dark();
    return MaterialApp(
      theme: theme.copyWith(
        appBarTheme: AppBarTheme(color: Colors.red[700]),
      ),
      home: BlocProvider(
        create: (context) => Injection.getIt<BusinessListBloc>(),
        child: BusinessListScreen(),
      ),
    );
  }
}