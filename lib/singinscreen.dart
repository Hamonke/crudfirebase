
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
//import 'package:google_sign_in/google_sign_in.dart';



class SigningInScreen extends StatefulWidget {
  const SigningInScreen({super.key});

  @override
  State<SigningInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SigningInScreen>  {
   
  @override
  Widget build(BuildContext context) {
     final providers = [EmailAuthProvider()];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: MaterialApp(
        initialRoute: FirebaseAuth.instance.currentUser == null ? '/sign-in' : '/profile',
        routes: {
          '/sign-in': (context) {
            return SignInScreen(
              auth: FirebaseAuth.instance,
              providers: providers,
              actions: [
                AuthStateChangeAction<SignedIn>((context, state) {
                  Navigator.pushReplacementNamed(context, '/profile');
                }),
              ],
            );
          },
          '/profile': (context) {
            return ProfileScreen(
              auth: FirebaseAuth.instance,
              providers: providers,
              actions: [
                SignedOutAction((context) {
                  Navigator.pushReplacementNamed(context, '/sign-in');
                }),
              ],
            );
          },
        },
      ),
    );
  }
}
