import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fidelize_app/models/logged_user.dart';
import 'package:flutter/material.dart';

void redeemProductModal(BuildContext context, DocumentSnapshot product) {
  final data = product.data() as Map<String, dynamic>;
  final user = LoggedUser.user;

  if (user == null) return;

  final userPoints = user.points;
  final productPoints = data['points'] ?? 0;
  final canRedeem = userPoints >= productPoints;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return FractionallySizedBox(
        widthFactor: 1.0,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((data['image'] as String?)?.isNotEmpty ?? false)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(data['image'], height: 200, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 16),
                Text(data['title'] ?? '', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(data['description'] ?? ''),
                const SizedBox(height: 8),
                Text('${data['points']} pontos necessários',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.card_giftcard),
                    label: const Text("Resgatar"),
                    onPressed: canRedeem
                        ? () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Confirmar Resgate"),
                          content: Text("Deseja resgatar este produto por $productPoints pontos?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancelar"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Confirmar"),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      try {
                        await FirebaseFirestore.instance.collection('transactions').add({
                          'userId': user.uid,
                          'productId': product.id,
                          'amount': -productPoints,
                          'date': Timestamp.now(),
                        });

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .update({
                          'points': userPoints - productPoints,
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Produto resgatado com sucesso!")),
                        );
                      } catch (e) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Erro ao resgatar o produto.")),
                        );
                      }
                    }
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    },
  );
}
