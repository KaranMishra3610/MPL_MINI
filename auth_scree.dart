import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'menu_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void handleAuth(Function authMethod) async {
    String userEmail = emailController.text.trim();
    bool success = await authMethod(userEmail, passwordController.text);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MenuScreen(userEmail: userEmail)), // ✅ Pass email here
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Authentication Failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login / Register")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () => handleAuth(_authService.register), child: Text("Register")),
            ElevatedButton(onPressed: () => handleAuth(_authService.login), child: Text("Login")),
          ],
        ),
      ),
    );
  }
}
