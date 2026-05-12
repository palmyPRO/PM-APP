import 'package:flutter/material.dart';
import '../login/login_screen.dart';
import '../register_screen/register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/Asset 160.png',
              height: 350,
              width: 400,
              fit: BoxFit.cover,
            ),


            const SizedBox(height: 150),

            SizedBox(
              width: 300,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                ),
                child: const Text(
                  "Login",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: 300,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                ),
                child: const Text(
                  "Register",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}