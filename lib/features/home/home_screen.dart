import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fidelize_app/features/products/products_screen.dart';
import 'package:fidelize_app/features/transactions/history_screen.dart';
import 'package:fidelize_app/features/transactions/earn_points_screen.dart';
import 'package:fidelize_app/models/logged_user.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../stores/nearby_stores_screen.dart';
import '../stores/nearby_stores_map.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = FirebaseFirestore.instance.collection('users').doc(LoggedUser.user?.uid).get();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userFuture = FirebaseFirestore.instance.collection('users').doc(LoggedUser.user?.uid).get();
  }

  Future<Map<String, dynamic>> _getUserAndProductNames(List<QueryDocumentSnapshot> docs) async {
    final userIds = docs.map((d) => d['userId'] as String?).whereType<String>().toSet();
    final productIds = docs.map((d) => d['productId'] as String?).whereType<String>().toSet();

    final userDocs = await Future.wait(userIds.map((id) => FirebaseFirestore.instance.collection('users').doc(id).get()));
    final productDocs = await Future.wait(productIds.map((id) => FirebaseFirestore.instance.collection('products').doc(id).get()));

    final userMap = {for (var doc in userDocs) doc.id: (doc.data()?['name'] ?? 'Desconhecido')};
    final productMap = {for (var doc in productDocs) doc.id: (doc.data()?['title'] ?? 'Desconhecido')};

    return {'users': userMap, 'products': productMap};
  }

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
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Histórico'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text('Acumular Pontos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EarnPointsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Lojas Próximas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyStoresScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Mapa de Lojas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyStoresMap()));
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
      floatingActionButton: user?.isAdmin == false
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const EarnPointsScreen()));
        },
        child: const Icon(Icons.qr_code),
      )
          : null,
      body: FutureBuilder<DocumentSnapshot>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final userPoints = userData['points'] ?? 0;

          if (user?.isAdmin == true) {
            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('transactions').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                return FutureBuilder<Map<String, dynamic>>(
                  future: _getUserAndProductNames(docs),
                  builder: (context, namesSnapshot) {
                    if (!namesSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final users = Map<String, String>.from(namesSnapshot.data!['users'] as Map);
                    final products = Map<String, String>.from(namesSnapshot.data!['products'] as Map);

                    final totals = <String, int>{};
                    for (var doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final productId = data['productId'];
                      if (productId != null) {
                        totals[products[productId] ?? 'Desconhecido'] = (totals[products[productId] ?? 'Desconhecido'] ?? 0) + 1;
                      }
                    }

                    final sortedEntries = totals.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dashboard do Administrador', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 16),
                          Text('Produtos mais resgatados', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          Expanded(
                            child: PieChart(
                              PieChartData(
                                sections: sortedEntries.map((entry) {
                                  return PieChartSectionData(
                                    title: entry.key,
                                    value: entry.value.toDouble(),
                                    radius: 60,
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Últimas transações', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: docs.length.clamp(0, 5),
                              itemBuilder: (context, index) {
                                final data = docs[index].data() as Map<String, dynamic>;
                                final amount = (data['amount'] as num).toInt();
                                final isPositive = amount > 0;
                                final name = users[data['userId']] ?? 'Desconhecido';

                                return ListTile(
                                  leading: Icon(
                                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: isPositive ? Colors.green : Colors.red,
                                  ),
                                  title: Text(
                                    '$name: ${isPositive ? '+' : ''}$amount pontos',
                                    style: TextStyle(
                                      color: isPositive ? Colors.green[700] : Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bem-vindo, ${user?.name ?? "usuário"}!', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                Text('Seus pontos acumulados:', style: Theme.of(context).textTheme.titleMedium),
                Text('$userPoints pontos', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                const SizedBox(height: 32),
                Text('Próximo resgate sugerido:', style: Theme.of(context).textTheme.titleMedium),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('products').orderBy('points').get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text('Nenhum produto disponível.');

                    final products = snapshot.data!.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
                    final nextProduct = products.firstWhere(
                          (doc) {
                        final data = doc.data();
                        final requiredPoints = data['points'] ?? 0;
                        return requiredPoints > userPoints;
                      },
                      orElse: () => products.last,
                    );

                    final productData = nextProduct.data();
                    final productTitle = productData['title'] ?? 'Produto';
                    final productPoints = productData['points'] ?? 0;
                    final progress = (userPoints / productPoints).clamp(0.0, 1.0);

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(top: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(productTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Necessário: $productPoints pontos'),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.grey[300],
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(height: 4),
                            Text('${(progress * 100).toStringAsFixed(1)}% alcançado'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
