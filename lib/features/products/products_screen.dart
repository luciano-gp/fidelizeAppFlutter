import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/logged_user.dart';
import '../../widgets/product_form_dialog.dart';
import '../../widgets/product_redeem_modal.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String filter = '';

  @override
  Widget build(BuildContext context) {
    final isAdmin = LoggedUser.user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => productFormDialog(context),
            )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => setState(() => filter = value.trim()),
              decoration: const InputDecoration(
                hintText: 'Filtrar por nome',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .orderBy('points')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredProducts = snapshot.data!.docs.where((doc) {
                  final title = doc['title'].toString().toLowerCase();
                  return title.contains(filter.toLowerCase());
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(child: Text('Nenhum produto encontrado.'));
                }

                return ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final doc = filteredProducts[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: data['image'] != null && data['image'].toString().isNotEmpty
                            ? Image.network(data['image'], width: 64, height: 64, fit: BoxFit.cover)
                            : const Icon(Icons.image, size: 48),
                        title: Text(data['title'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('${data['points']} pontos', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        onTap: () {
                          if (isAdmin) {
                            productFormDialog(context, product: doc);
                          } else {
                            redeemProductModal(context, doc);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
