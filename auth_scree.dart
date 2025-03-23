import 'dart:math';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/menu_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _captchaController = TextEditingController();
  final AuthService _authService = AuthService();

  late String captchaCode;
  String passwordStrength = "Weak";

  @override
  void initState() {
    super.initState();
    _generateNewCaptcha();
  }

  void _generateNewCaptcha() {
    setState(() {
      captchaCode = _generateRandomCaptcha(6);
    });
  }

  String _generateRandomCaptcha(int length) {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    return String.fromCharCodes(
      List.generate(length, (index) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  String? _validatePassword(String password) {
    bool hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowerCase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChar = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    bool hasMinLength = password.length >= 8;

    int strengthPoints = [
      hasUpperCase,
      hasLowerCase,
      hasDigits,
      hasSpecialChar,
      hasMinLength
    ].where((e) => e).length;

    setState(() {
      if (strengthPoints <= 2) {
        passwordStrength = "Weak";
      } else if (strengthPoints == 3 || strengthPoints == 4) {
        passwordStrength = "Moderate";
      } else {
        passwordStrength = "Strong";
      }
    });

    if (!hasMinLength) return "Password must be at least 8 characters.";
    if (!hasUpperCase) return "Password must contain an uppercase letter.";
    if (!hasLowerCase) return "Password must contain a lowercase letter.";
    if (!hasDigits) return "Password must contain a number.";
    if (!hasSpecialChar) return "Password must contain a special character.";

    return null;
  }

  void _authenticate(bool isLogin) async {
    if (_captchaController.text.trim() != captchaCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect CAPTCHA. Try again!")),
      );
      _generateNewCaptcha();
      return;
    }

    String passwordError = _validatePassword(_passwordController.text.trim()) ?? "";
    if (passwordError.isNotEmpty && !isLogin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passwordError)),
      );
      return;
    }

    String? userId = isLogin
        ? await _authService.login(_emailController.text.trim(), _passwordController.text.trim())
        : await _authService.register(_emailController.text.trim(), _passwordController.text.trim());

    if (userId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isLogin ? "Login Successful!" : "Registration Successful!")),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MenuScreen(userEmail: _emailController.text.trim()),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication Failed!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/images/background.png", fit: BoxFit.cover),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Welcome!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildTextField(_emailController, "Email"),
                    _buildTextField(_passwordController, "Password", isPassword: true, onChanged: (value) {
                      _validatePassword(value);
                    }),
                    Text("Password Strength: $passwordStrength", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: passwordStrength == "Weak" ? Colors.red : passwordStrength == "Moderate" ? Colors.orange : Colors.green)),
                    const SizedBox(height: 10),
                    Text('Enter CAPTCHA: "$captchaCode"', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    _buildTextField(_captchaController, "Enter CAPTCHA"),
                    const SizedBox(height: 10),
                    _buildButton("Login", () => _authenticate(true), Colors.blue),
                    _buildButton("Register", () => _authenticate(false), Colors.green),
                    const SizedBox(height: 10),
                    _buildButton("Login as Admin", () => Navigator.pushNamed(context, '/admin'), Colors.orange),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isPassword = false, ValueChanged<String>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          fillColor: Colors.white,
          filled: true,
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }
}
