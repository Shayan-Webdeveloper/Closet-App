import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/add_item_screen.dart';
// import 'screens/create_look_screen.dart';
import 'screens/create_look_screen.dart';

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
      home: const HomeShell(),
      //  AddItemScreen(),
      // CreateLookScreen(),
    );
  }
}
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [const AddItemScreen(), const CreateLookScreen()];
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.add_a_photo), label: 'Add Item'),
          NavigationDestination(icon: Icon(Icons.checkroom), label: 'Create Look'),
        ],
      ),
    );
  }
}