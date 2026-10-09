import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/main_screen.dart';
import 'constants/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/run_provider.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Debug ayarları - Logları aktif tut
  if (kDebugMode) {
    debugPrintRebuildDirtyWidgets = false;
    // debugPrint'i kapatma - hataları görmek için açık bırak
    print('🚀 DEBUG MODE AKTIF - Loglar gösterilecek');
  }
  
  // Firebase'i platform spesifik başlat
  try {
    print('Firebase başlatılıyor... Platform: ${Platform.operatingSystem}');
    
    if (Platform.isIOS) {
      // iOS için manuel konfigürasyon
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyAJTD4XBi8r6yiLTVkc0MeI1z-04ohgoeQ',
          appId: '1:452241482354:ios:5e464628b1238be20918eb',
          messagingSenderId: '452241482354',
          projectId: 'eveg-8c122',
          storageBucket: 'eveg-8c122.firebasestorage.app',
        ),
      );
    } else {
      // Android ve diğer platformlar
      await Firebase.initializeApp();
    }
    
    print('✅ Firebase başarıyla başlatıldı');
  } catch (e) {
    print('❌ Firebase başlatma hatası: $e');
    // Firebase başlatılamazsa bile uygulamayı çalıştır
    // Bu durumda mock servisler kullanılacak
  }
  
  runApp(const EvegApp());
}

class EvegApp extends StatelessWidget {
  const EvegApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RunProvider()),
      ],
      child: MaterialApp(
        title: 'Eveg',
        theme: AppTheme.darkTheme,
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
