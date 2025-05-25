import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:armada_app/pages/navbar_page.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  AnimationController? _fadeController;
  AnimationController? _slideController;
  AnimationController? _scaleController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _scaleAnimation;

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  static const String API_BASE_URL = "http://192.168.100.62:3000/api";
  static const Duration TIMEOUT_DURATION = Duration(seconds: 10);
  static const Duration ANIMATION_DELAY = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadSavedCredentials();
    checkLoginStatus();
    _startAnimations();
  }

  void _initAnimations() {
    try {
      _fadeController = AnimationController(
        duration: Duration(milliseconds: 1500),
        vsync: this,
      );
      _slideController = AnimationController(
        duration: Duration(milliseconds: 1200),
        vsync: this,
      );
      _scaleController = AnimationController(
        duration: Duration(milliseconds: 800),
        vsync: this,
      );

      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController!, curve: Curves.easeInOut),
      );
      _slideAnimation = Tween<Offset>(
        begin: Offset(0.0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _slideController!, curve: Curves.elasticOut));
      _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _scaleController!, curve: Curves.bounceOut),
      );
    } catch (e) {
      debugPrint('Error initializing animations: $e');
      _fadeController = AnimationController(
        duration: Duration(milliseconds: 500),
        vsync: this,
      );
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController!);
    }
  }

  void _startAnimations() {
    if (_fadeController != null && _slideController != null && _scaleController != null) {
      Future.delayed(ANIMATION_DELAY, () {
        if (mounted) _fadeController!.forward();
      });
      Future.delayed(Duration(milliseconds: 600), () {
        if (mounted) _slideController!.forward();
      });
      Future.delayed(Duration(milliseconds: 900), () {
        if (mounted) _scaleController!.forward();
      });
    }
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool rememberMe = prefs.getBool('remember_me') ?? false;
      
      if (rememberMe) {
        String? savedEmail = prefs.getString('saved_email');
        if (savedEmail != null) {
          setState(() {
            emailController.text = savedEmail;
            _rememberMe = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    _slideController?.dispose();
    _scaleController?.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> checkLoginStatus() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? idArmada = prefs.getString('id_armada');

      if (idArmada != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NavbarPage(idArmada: idArmada)),
        );
      }
    } catch (e) {
      debugPrint('Error checking login status: $e');
    }
  }

Future<void> sendTracking(String idArmada) async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final response = await http.post(
      Uri.parse("http://192.168.100.62:3000/api/tracking"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_armada": idArmada,
        "latitude": position.latitude,
        "longitude": position.longitude,
      }),
    );

    if (response.statusCode == 200) {
      print("Tracking terkirim!");
    } else {
      print("Gagal kirim tracking");
    }
  } catch (e) {
    print("Error kirim tracking: $e");
  }
}


  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Format email tidak valid';
    }
    
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    
    if (value.length < 0) {
      return 'Password minimal 6 karakter';
    }
    
    return null;
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    final String apiUrl = "$API_BASE_URL/auth/mobile/login";

    setState(() {
      isLoading = true;
    });

    HapticFeedback.lightImpact();

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text.trim(),
          "password": passwordController.text,
        }),
      ).timeout(TIMEOUT_DURATION);

      final responseData = jsonDecode(response.body);
      debugPrint("Response dari server: $responseData");

      if (response.statusCode == 200 && responseData["success"] == true) {
        String idArmada = responseData["user"]["id_armada"].toString();
        String statusArmada = responseData["user"]["status_armada"].toString();

        await saveUserSession(idArmada, statusArmada);
        await sendTracking(idArmada); // ← kirim lokasi otomatis
        HapticFeedback.mediumImpact();
        
        _showAlert("Login Berhasil", "Selamat datang kembali!", isError: false);
        
        await Future.delayed(Duration(milliseconds: 1500));
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => NavbarPage(idArmada: idArmada)),
          );
        }
      } else {
        HapticFeedback.heavyImpact();
        String errorMessage = responseData["message"] ?? "Email atau password salah";
        _showAlert("Login Gagal", errorMessage, isError: true);
      }
    } on http.ClientException {
      HapticFeedback.heavyImpact();
      _showAlert("Error", "Tidak dapat terhubung ke server", isError: true);
    } catch (e) {
      HapticFeedback.heavyImpact();
      debugPrint('Login error: $e');
      _showAlert("Error", "Gagal menghubungi server. Cek koneksi internet Anda.", isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> saveUserSession(String idArmada, String statusArmada) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('id_armada', idArmada);
      await prefs.setString('status_armada', statusArmada);
      await prefs.setString('login_time', DateTime.now().toIso8601String());
      
      await prefs.setBool('remember_me', _rememberMe);
      if (_rememberMe) {
        await prefs.setString('saved_email', emailController.text.trim());
      } else {
        await prefs.remove('saved_email');
      }
    } catch (e) {
      debugPrint('Error saving user session: $e');
    }
  }

  void _showAlert(String title, String message, {required bool isError}) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 20,
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isError ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: isError ? Colors.red : Colors.green,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isError ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isError ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  "OK",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleForgotPassword() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController resetEmailController = TextEditingController();
        
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Reset Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Masukkan email Anda untuk reset password"),
              SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showAlert("Info", "Link reset password telah dikirim ke email Anda", isError: false);
              },
              child: Text("Kirim"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_fadeAnimation == null || _slideAnimation == null || _scaleAnimation == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a472a),
              Color(0xFF2d5a3d),
              Color(0xFF006D3C),
              Color(0xFF00A855),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Header Section
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight * 0.35,
                          ),
                          child: FadeTransition(
                            opacity: _fadeAnimation!,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ScaleTransition(
                                  scale: _scaleAnimation!,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.all(20),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'images/logo armada.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.account_circle,
                                            size: 60,
                                            color: Color(0xFF006D3C),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 24),
                                SlideTransition(
                                  position: _slideAnimation!,
                                  child: Column(
                                    children: [
                                      Text(
                                        "Welcome Back",
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          "DRIVER ECODRIVE",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 2.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Form Section
                        Expanded(
                          child: SlideTransition(
                            position: _slideAnimation!,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(40),
                                  topRight: Radius.circular(40),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: Offset(0, -5),
                                  )
                                ],
                              ),
                              child: SingleChildScrollView(
                                padding: EdgeInsets.all(24),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 60,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade300,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                            SizedBox(height: 24),
                                            Text(
                                              "Sign In",
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF006D3C),
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              "Masuk ke akun Anda untuk melanjutkan",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 24),
                                      
                                      // Email Field
                                      _buildTextField(
                                        controller: emailController,
                                        label: "Email Address",
                                        hint: "Masukkan email Anda",
                                        icon: Icons.email_outlined,
                                        focusNode: _emailFocus,
                                        keyboardType: TextInputType.emailAddress,
                                        enabled: !isLoading,
                                        validator: _validateEmail,
                                      ),
                                      SizedBox(height: 16),
                                      
                                      // Password Field
                                      _buildTextField(
                                        controller: passwordController,
                                        label: "Password",
                                        hint: "Masukkan password Anda",
                                        icon: Icons.lock_outlined,
                                        focusNode: _passwordFocus,
                                        isPassword: true,
                                        enabled: !isLoading,
                                        validator: _validatePassword,
                                      ),
                                      SizedBox(height: 12),
                                      
                                      // Remember Me & Forgot Password
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Transform.scale(
                                                scale: 0.9,
                                                child: Checkbox(
                                                  value: _rememberMe,
                                                  onChanged: isLoading ? null : (value) {
                                                    setState(() {
                                                      _rememberMe = value ?? false;
                                                    });
                                                    HapticFeedback.selectionClick();
                                                  },
                                                  activeColor: Color(0xFF006D3C),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                "Remember me",
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          TextButton(
                                            onPressed: isLoading ? null : _handleForgotPassword,
                                            child: Text(
                                              "Forgot Password?",
                                              style: TextStyle(
                                                color: Color(0xFF006D3C),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 24),
                                      
                                      // Login Button
                                      Container(
                                        width: double.infinity,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          gradient: LinearGradient(
                                            colors: [Color(0xFF006D3C), Color(0xFF00A855)],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xFF006D3C).withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: isLoading ? null : login,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: isLoading
                                              ? Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text(
                                                      "Signing In...",
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.login_rounded,
                                                      color: Colors.white,
                                                      size: 24,
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text(
                                                      "Sign In",
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      
                                      // Footer
                                      Center(
                                        child: Text(
                                          "© 2024 EcoDrive. All rights reserved.",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required FocusNode focusNode,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF006D3C),
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.grey.shade50 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: focusNode.hasFocus ? Color(0xFF006D3C) : Colors.grey.shade300,
              width: focusNode.hasFocus ? 2 : 1,
            ),
            boxShadow: focusNode.hasFocus
                ? [
                    BoxShadow(
                      color: Color(0xFF006D3C).withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPassword ? _obscurePassword : false,
            keyboardType: keyboardType,
            enabled: enabled,
            validator: validator,
            style: TextStyle(
              fontSize: 16,
              color: enabled ? Colors.grey.shade800 : Colors.grey.shade500,
            ),
            onTap: () {
              if (enabled) HapticFeedback.selectionClick();
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
              prefixIcon: Container(
                margin: EdgeInsets.all(12),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF006D3C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Color(0xFF006D3C),
                  size: 20,
                ),
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: enabled ? () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                        HapticFeedback.selectionClick();
                      } : null,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              errorStyle: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}