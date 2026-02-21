import 'package:flutter/material.dart';
import 'package:geo_connect/screens/main_screen/main_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // While waiting for the auth state, show a loading indicator.
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;
        if (session != null) {
          // If there is a valid session, the user is logged in.
          return const MainPage();
        } else {
          // If there is no session, the user is not logged in.
          return const LoginScreen();
        }
      },
    );
  }
}
