import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void productFormDialog(BuildContext context, {DocumentSnapshot? product}) {
  final isEdit = product != null;

  final titleController = TextEditingController(text: product?.get('title') ?? '');
  final descriptionController = TextEditingController(text: product?.get('description') ?? '');
  final pointsController = TextEditingController(text: product?.get('points')?.toString() ?? '');
  final imageController = TextEditingController(text: product?.get('image') ?? '');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdit ? "Editar Produto" : "Cadastrar Produto",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Título"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Descrição"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pointsController,
                decoration: const InputDecoration(labelText: "Pontos Necessários"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: "URL da Imagem"),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (isEdit)
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Excluir Produto"),
                              content: const Text("Tem certeza que deseja excluir este produto?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Cancelar"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Excluir", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await FirebaseFirestore.instance
                                .collection('products')
                                .doc(product!.id)
                                .delete();

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Produto excluído com sucesso.")),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text("Excluir"),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ),
                  if (isEdit) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final description = descriptionController.text.trim();
                        final points = int.tryParse(pointsController.text) ?? 0;
                        final image = imageController.text.trim();

                        if (title.isEmpty || description.isEmpty || points <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Preencha todos os campos corretamente.")),
                          );
                          return;
                        }

                        final data = {
                          'title': title,
                          'description': description,
                          'points': points,
                          'image': image,
                        };

                        try {
                          if (isEdit) {
                            await FirebaseFirestore.instance
                                .collection('products')
                                .doc(product!.id)
                                .update(data);
                          } else {
                            await FirebaseFirestore.instance.collection('products').add(data);
                          }

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit
                                  ? "Produto atualizado com sucesso!"
                                  : "Produto cadastrado com sucesso!"),
                            ),
                          );
                        } catch (e) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Falha ao salvar produto!")),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text("Salvar"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    },
  );
}
