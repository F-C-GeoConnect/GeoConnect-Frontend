import 'package:flutter/material.dart';
import 'package:geo_connect/screens/main_screen/cart_provider.dart';
import 'package:geo_connect/screens/main_screen/main_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://cvyhpuodwppxhzjgzfvg.supabase.co',
    anonKey: 'sb_publishable_mUHSxk9Au87fg1bwIcwA6w_9OaVA8at',
  );

  runApp(
    // We wrap the whole app in this Provider so the Cart data is accessible everywhere
    ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: const MyApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DOOKO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const MainPage(),
    );
  }
}