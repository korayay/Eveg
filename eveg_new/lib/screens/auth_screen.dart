import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import 'main_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Üst Logo ve Başlık
                _buildTopHeader(),
                const SizedBox(height: 60),
                
                // Ana Kart
                _buildMainCard(),
                const SizedBox(height: 24),
                
                // Alt Bilgi
                _buildBottomInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.directions_run,
            color: AppColors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        
        // Başlık
        Text(
          _isLogin ? 'Hoş Geldiniz' : 'Hesap Oluştur',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 8),
        
        Text(
          _isLogin 
            ? 'Hesabınıza giriş yapın ve koşmaya başlayın'
            : 'Yeni bir hesap oluşturun ve topluluğa katılın',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMainCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkGrey.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // Form Alanları
          if (!_isLogin) _buildUsernameField(),
          if (!_isLogin) const SizedBox(height: 16),
          
          _buildEmailField(),
          const SizedBox(height: 16),
          
          _buildPasswordField(),
          const SizedBox(height: 24),
          
          // Giriş/Kayıt Butonu
          _buildSubmitButton(),
          const SizedBox(height: 16),
          
          // Geçiş Butonu
          _buildToggleButton(),
        ],
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Column(
      children: [
                  // Test Kullanıcı Girişi
          _buildTestLoginButton(),
          const SizedBox(height: 16),
          
          // Anonim Giriş
          _buildAnonymousButton(),
          const SizedBox(height: 24),
          
          // Sosyal Giriş
          _buildSocialButtons(),
      ],
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      style: const TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        labelText: 'Kullanıcı Adı',
        labelStyle: const TextStyle(color: AppColors.grey),
        prefixIcon: const Icon(Icons.person, color: AppColors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: AppColors.darkGrey,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Kullanıcı adı gerekli';
        }
        if (value.length < 3) {
          return 'Kullanıcı adı en az 3 karakter olmalı';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      style: const TextStyle(color: AppColors.white),
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'E-posta',
        labelStyle: const TextStyle(color: AppColors.grey),
        prefixIcon: const Icon(Icons.email, color: AppColors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: AppColors.darkGrey,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'E-posta gerekli';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Geçerli bir e-posta adresi girin';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      style: const TextStyle(color: AppColors.white),
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Şifre',
        labelStyle: const TextStyle(color: AppColors.grey),
        prefixIcon: const Icon(Icons.lock, color: AppColors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: AppColors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: AppColors.darkGrey,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Şifre gerekli';
        }
        if (value.length < 6) {
          return 'Şifre en az 6 karakter olmalı';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            )
          : Text(
              _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
              style: const TextStyle(
                fontSize: 16,
              fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildToggleButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _isLogin = !_isLogin;
        });
      },
      child: Text(
        _isLogin 
          ? 'Hesabınız yok mu? Kayıt olun'
          : 'Zaten hesabınız var mı? Giriş yapın',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTestLoginButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleTestLogin,
      icon: const Icon(Icons.person, size: 20),
      label: const Text(
        'Test Kullanıcısı ile Giriş',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildAnonymousButton() {
    return OutlinedButton(
      onPressed: _isLoading ? null : _handleAnonymousSignIn,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.darkGrey),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Anonim Olarak Devam Et',
        style: TextStyle(
          color: AppColors.grey,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        const Text(
          'veya',
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                icon: const Icon(Icons.g_mobiledata, color: AppColors.error),
                label: const Text('Google'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.darkGrey),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleAppleSignIn,
                icon: const Icon(Icons.apple, color: AppColors.white),
                label: const Text('Apple'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.darkGrey),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // AuthProvider'ı kullanarak giriş/kayıt işlemi yap
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success = false;

      if (_isLogin) {
        // Giriş işlemi
        success = await authProvider.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        // Kayıt işlemi
        success = await authProvider.signUpWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
          _usernameController.text,
        );
      }

      if (success) {
        // Başarılı giriş/kayıt - ana sayfaya git
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        // Hata durumu
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
            content: Text(_isLogin ? 'Giriş başarısız!' : 'Kayıt başarısız!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hata durumu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
    setState(() {
      _isLoading = false;
    });
    }
  }

  Future<void> _handleTestLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Test kullanıcısıyla giriş
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithEmailAndPassword(
        'test@example.com',
        'test123456',
      );

      if (success) {
        // Başarılı giriş - ana sayfaya git
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        // Hata durumu
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test kullanıcısı girişi başarısız!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hata durumu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test giriş hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAnonymousSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // AuthProvider ile anonim giriş
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInAnonymously();

      if (success) {
        // Başarılı anonim giriş - ana sayfaya git
    Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        // Hata durumu
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anonim giriş başarısız!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hata durumu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    // Google Sign-In implementasyonu
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Sign-In yakında eklenecek'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  Future<void> _handleAppleSignIn() async {
    // Apple Sign-In implementasyonu
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Apple Sign-In yakında eklenecek'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }
} 