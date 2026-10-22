import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/add_item_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ilmirqkrgpdjcwgygxiy.supabase.co',
    publishableKey: 'sb_publishable_5Kx-RpgR2YR_AhKGYNV4qQ_-Ia8cXQj',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AddItemScreen(),
    );
  }
}