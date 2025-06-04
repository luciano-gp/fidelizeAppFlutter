import 'package:fidelize_app/features/products/products_screen.dart';
import 'package:fidelize_app/features/transactions/history_screen.dart';
import 'package:fidelize_app/features/transactions/earn_points_screen.dart';
import 'package:fidelize_app/models/logged_user.dart';
import 'package:fidelize_app/widgets/product_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../stores/nearby_stores_screen.dart';
import '../stores/nearby_stores_map.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = LoggedUser.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Fidelize')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepPurple),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person, color: Colors.white, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? 'Usuário',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('Produtos'),
              onTap: () {
                Navigator.pop(context); // fecha o menu
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Histórico'),
              onTap: () {
                Navigator.pop(context); // fecha o menu
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text('Acumular Pontos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EarnPointsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Lojas Próximas'),
              onTap: () {
                Navigator.pop(context); // fecha o menu
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NearbyStoresScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Mapa de Lojas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NearbyStoresMap()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
      body: Center(
          child: Text(
            'Bem-vindo, ${user?.name ?? "usuário"}!',
            style: Theme.of(context).textTheme.headlineSmall,
          )
      ),
    );
  }
}
