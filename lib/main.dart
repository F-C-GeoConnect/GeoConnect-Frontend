import 'package:flutter/material.dart';
import 'package:geo_connect/screens/main_screen/home_screen.dart';
import 'package:geo_connect/screens/main_screen/listings_screen.dart';
import 'package:geo_connect/screens/main_screen/map_screen.dart';
import 'package:geo_connect/screens/profile_page.dart';
import 'package:geo_connect/screens/splash_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DOOKO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const FarmerMapScreen(),
    );
  }
}
