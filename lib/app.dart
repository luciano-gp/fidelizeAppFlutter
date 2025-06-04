import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fidelize_app/models/logged_user.dart';
import 'package:fidelize_app/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'core/theme.dart';

class FidelizeApp extends StatelessWidget {
  const FidelizeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fidelize',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = authSnapshot.data;
          if (user == null) {
            return const LoginScreen();
          }

          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final data = userSnapshot.data?.data();
              if (data != null) {
                final userModel = UserModel.fromMap(user.uid, data);
                LoggedUser.setUser(userModel);
              }

              return const HomeScreen();
            },
          );
        },
      ),
    );
  }
}
