//this is singinscreen.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'main.dart';
import 'firebase_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:google_sign_in/google_sign_in.dart';

class SigningInScreen extends HookConsumerWidget {
  const SigningInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final prefs = snapshot.data!;
          final providers = [EmailAuthProvider()];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Sign In'),
            ),
            body: MaterialApp(
              debugShowCheckedModeBanner: false,
              initialRoute: FirebaseAuth.instance.currentUser == null || FirebaseAuth.instance.currentUser!.isAnonymous ? '/sign-in' : '/profile',
              routes: {
                '/sign-in': (context) {
                  return SignInScreen(
                    showPasswordVisibilityToggle: true,
                    auth: FirebaseAuth.instance,
                    providers: providers,
                    actions: [
                      AuthStateChangeAction<SignedIn>((context, state) async {
                        final todos = ref.watch(todoListProvider).value ?? [];
                        final isFirstTime = await checkIfFirstTime();
                        if (isFirstTime) {
                          await createUserDocumentWithMerge(todos);
                        } else {
                          await loadTodosFromFirestore();
                        }
                        await prefs.setBool('isSignedInBefore', true);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.pushReplacementNamed(context, '/profile');
                        });
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
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}