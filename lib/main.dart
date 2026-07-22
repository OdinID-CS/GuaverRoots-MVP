import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:camera/camera.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'models/scan_result.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  Hive.registerAdapter(ScanResultAdapter());
  await StorageService.init();
  
  // Initialize cameras
  final cameras = await availableCameras();
  
  runApp(GuaverRootsApp(cameras: cameras));
}

class GuaverRootsApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const GuaverRootsApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiService()),
        Provider.value(value: cameras),
      ],
      child: MaterialApp(
        title: 'GuaverRoots',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
