import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fidelize_app/models/logged_user.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? selectedUserId;
  List<DocumentSnapshot> users = [];

  @override
  void initState() {
    super.initState();
    if (LoggedUser.user?.isAdmin == true) {
      FirebaseFirestore.instance.collection('users').get().then((snapshot) {
        setState(() => users = snapshot.docs);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = LoggedUser.user;
    if (user == null) return const SizedBox.shrink();

    final isAdmin = user.isAdmin;
    Query query = FirebaseFirestore.instance.collection('transactions').orderBy('date', descending: true);
    if (!isAdmin) {
      query = query.where('userId', isEqualTo: user.uid);
    } else if (selectedUserId != null && selectedUserId!.isNotEmpty) {
      query = query.where('userId', isEqualTo: selectedUserId);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Transações')),
      body: Column(
        children: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<String>(
                value: selectedUserId,
                hint: const Text('Filtrar por usuário'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ...users.map((userDoc) {
                    final data = userDoc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: userDoc.id,
                      child: Text(data['name'] ?? data['email'] ?? userDoc.id),
                    );
                  }).toList(),
                ],
                onChanged: (value) => setState(() => selectedUserId = value),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text('Nenhuma transação encontrada.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final transactionDoc = docs[index];
                    final data = transactionDoc.data() as Map<String, dynamic>;
                    final isEntrada = (data['amount'] as num) > 0;
                    final date = (data['date'] as Timestamp).toDate();
                    final formattedDate = DateFormat("d 'de' MMMM 'de' y 'às' HH:mm", 'pt_BR').format(date);
                    final points = data['amount'];

                    return ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: isEntrada ? Colors.green[50] : Colors.red[50],
                      leading: Icon(
                        isEntrada ? Icons.add_circle_outline : Icons.remove_circle_outline,
                        color: isEntrada ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        isEntrada ? 'Pontos acumulados' : 'Produto resgatado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isEntrada ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                      subtitle: Text(formattedDate),
                      trailing: Text(
                        '${isEntrada ? '+' : ''}$points',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isEntrada ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                      onTap: isAdmin ? () => _showTransactionModal(context, transactionDoc) : null,
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

  void _showTransactionModal(BuildContext context, DocumentSnapshot transactionDoc) async {
    final data = transactionDoc.data() as Map<String, dynamic>;
    final userId = data['userId'];
    final originalAmount = data['amount'] as int;

    final productsSnapshot = await FirebaseFirestore.instance.collection('products').get();
    final products = productsSnapshot.docs;

    String? selectedProductId = data['productId'];
    int editedAmount = originalAmount;

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Gerenciar Transação", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (originalAmount > 0)
                TextFormField(
                  initialValue: originalAmount.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Pontos acumulados'),
                  onChanged: (value) => editedAmount = int.tryParse(value) ?? originalAmount,
                )
              else
                DropdownButtonFormField<String>(
                  value: selectedProductId,
                  hint: const Text("Alterar produto associado"),
                  items: products.map((productDoc) {
                    final prodData = productDoc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: productDoc.id,
                      child: Text(prodData['title'] ?? 'Produto sem nome'),
                    );
                  }).toList(),
                  onChanged: (value) => selectedProductId = value,
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
                      await transactionDoc.reference.delete();
                      await userRef.update({'points': FieldValue.increment(-originalAmount)});
                    },
                    child: const Text("Cancelar Transação", style: TextStyle(color: Colors.red)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      int newAmount;

                      if (originalAmount > 0) {
                        newAmount = editedAmount;
                      } else {
                        if (selectedProductId == null) return;
                        final newProduct = products.firstWhere((p) => p.id == selectedProductId);
                        final newProductData = newProduct.data() as Map<String, dynamic>;
                        newAmount = -newProductData['points'] as int;
                      }

                      final pointDifference = newAmount - originalAmount;

                      await transactionDoc.reference.update({
                        'productId': selectedProductId,
                        'amount': newAmount,
                      });

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .update({'points': FieldValue.increment(pointDifference)});

                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text("Salvar"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
