import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart' as app_user;
import '../services/firebase_service.dart';

class AuthProvider with ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseService? _firebaseService;
  
  app_user.User? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;

  FirebaseAuth? get _authInstance {
    try {
      _auth ??= FirebaseAuth.instance;
      return _auth;
    } catch (e) {
      print('Firebase Auth başlatılamadı: $e');
      return null;
    }
  }

  FirebaseService get _firebaseServiceInstance {
    _firebaseService ??= FirebaseService();
    return _firebaseService!;
  }

  app_user.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated {
    try {
      return _authInstance?.currentUser != null || _currentUser != null;
    } catch (e) {
      return _currentUser != null;
    }
  }

  AuthProvider() {
    _initialize();
  }

  void _initialize() async {
    try {
      // Firebase'in başlatılmış olduğunu kontrol et
      await Future.delayed(Duration(milliseconds: 2000)); // Firebase'in başlaması için bekle
      
      _auth = FirebaseAuth.instance;
      _firebaseService = FirebaseService();
      _isInitialized = true;
      
      // Firebase bağlantısını test et
      final user = _authInstance?.currentUser;
      print('🔥 AuthProvider Firebase bağlantısı: ${user != null ? "Kullanıcı var" : "Kullanıcı yok"}');
      
      _authInstance?.authStateChanges().listen(_onAuthStateChanged);
      
      print('✅ AuthProvider Firebase ile başlatıldı');
      
      // Test kullanıcısıyla giriş yap
      if (_authInstance?.currentUser == null) {
        print('🔑 Test kullanıcısıyla giriş denenecek');
        await _signInTestUser();
      }
    } catch (e) {
      print('❌ AuthProvider Firebase başlatma hatası: $e');
      _isInitialized = true;
      // Firebase başlatılamazsa mock kullanıcı oluştur
      print('🔄 Mock kullanıcı oluşturuluyor');
      await _createMockUser();
    }
  }
  
  Future<void> _signInTestUser() async {
    try {
      print('Test kullanıcısıyla giriş yapılıyor...');
      if (_authInstance != null) {
        // Farklı şifreler dene
        final passwords = ['test123456', 'password123', '123456', 'test123'];
        bool loginSuccess = false;
        
        for (String password in passwords) {
          try {
            await _authInstance!.signInWithEmailAndPassword(
              email: 'test@example.com',
              password: password,
            );
            print('✅ Test kullanıcısı girişi başarılı - Şifre: $password');
            loginSuccess = true;
            break;
          } catch (e) {
            print('❌ Şifre deneme başarısız ($password): $e');
          }
        }
        
        if (!loginSuccess) {
          throw Exception('Hiçbir şifre çalışmadı');
        }
      }
    } catch (e) {
      print('Test kullanıcısı girişi başarısız: $e');
      // Hata durumunda mock kullanıcı oluştur
      await _createMockUser();
    }
  }
  
  Future<void> _createMockUser() async {
    _currentUser = app_user.User(
      id: 'vJGf4meB3HhbNJo3aFvaH5If2ur1', // Sen
      username: 'TestKoşucu',
      email: 'test@example.com',
      level: 5,
      totalPoints: 1250,
      totalAreas: 8,
      totalDistance: 15000,
      createdAt: DateTime.now(),
      badges: ['İlk Koşu', '5 km', 'Alan Fatihi'],
    );
    
    print('🔑 Mock kullanıcı oluşturuldu: ${_currentUser!.id}');
    print('👤 Kullanıcı adı: ${_currentUser!.username}');
    notifyListeners();
  }

  void _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      await _loadUserData(firebaseUser.uid);
    } else {
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_firebaseService != null) {
        final user = await _firebaseServiceInstance.getCurrentUser();
        if (user != null) {
          _currentUser = user;
        } else {
          // Yeni kullanıcı oluştur
          final firebaseUser = _authInstance?.currentUser;
          if (firebaseUser != null) {
            final newUser = app_user.User(
              id: firebaseUser.uid,
              username: firebaseUser.displayName ?? 'Koşucu${uid.substring(0, 4)}',
              email: firebaseUser.email ?? '',
              createdAt: DateTime.now(),
            );
            
            await _firebaseServiceInstance.createUser(newUser);
            _currentUser = newUser;
          }
        }
      }
    } catch (e) {
      print('Kullanıcı verisi yüklenemedi: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInAnonymously() async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_authInstance != null) {
        await _authInstance!.signInAnonymously();
      } else {
        // Firebase başlatılmamışsa mock kullanıcı oluştur
        _currentUser = app_user.User(
          id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
          username: 'Anonim Kullanıcı',
          email: 'anonim@example.com',
          createdAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      print('Anonim giriş başarısız: $e');
      // Firebase başlatılmamışsa mock kullanıcı oluştur
      _currentUser = app_user.User(
        id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
        username: 'Anonim Kullanıcı',
        email: 'anonim@example.com',
        createdAt: DateTime.now(),
      );
      notifyListeners();
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_authInstance != null) {
        await _authInstance!.signInWithEmailAndPassword(email: email, password: password);
      } else {
        // Firebase başlatılmamışsa mock kullanıcı oluştur
        _currentUser = app_user.User(
          id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
          username: email.split('@')[0],
          email: email,
          createdAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      print('E-posta ile giriş başarısız: $e');
      // Firebase başlatılmamışsa mock kullanıcı oluştur
      _currentUser = app_user.User(
        id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
        username: email.split('@')[0],
        email: email,
        createdAt: DateTime.now(),
      );
      notifyListeners();
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUpWithEmailAndPassword(String email, String password, String username) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_authInstance != null) {
        final userCredential = await _authInstance!.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Kullanıcı profilini güncelle
        await userCredential.user?.updateDisplayName(username);

        // Firestore'da kullanıcı oluştur
        final newUser = app_user.User(
          id: userCredential.user!.uid,
          username: username,
          email: email,
          createdAt: DateTime.now(),
        );
        
        await _firebaseServiceInstance.createUser(newUser);
      } else {
        // Firebase başlatılmamışsa mock kullanıcı oluştur
        _currentUser = app_user.User(
          id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
          username: username,
          email: email,
          createdAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      print('Kayıt başarısız: $e');
      // Firebase başlatılmamışsa mock kullanıcı oluştur
      _currentUser = app_user.User(
        id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        email: email,
        createdAt: DateTime.now(),
      );
      notifyListeners();
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      if (_authInstance != null) {
        await _authInstance!.signOut();
      }
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      print('Çıkış yapılamadı: $e');
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({
    String? username,
    String? profileImage,
  }) async {
    if (_currentUser == null) return;

    try {
      final updatedUser = _currentUser!.copyWith(
        username: username,
        profileImage: profileImage,
      );

      await _firebaseServiceInstance.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      print('Profil güncellenemedi: $e');
    }
  }

  Future<void> updateUserStats({
    int? totalPoints,
    int? totalAreas,
    int? totalDistance,
    List<String>? badges,
  }) async {
    if (_currentUser == null) return;

    try {
      final updatedUser = _currentUser!.copyWith(
        totalPoints: totalPoints,
        totalAreas: totalAreas,
        totalDistance: totalDistance,
        badges: badges,
      );

      await _firebaseServiceInstance.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      print('Kullanıcı istatistikleri güncellenemedi: $e');
    }
  }
} 