import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isyfit/presentation/widgets/gradient_app_bar.dart';
import 'package:isyfit/presentation/theme/app_gradients.dart';

class PlanSelectionScreen extends StatelessWidget {
  const PlanSelectionScreen({Key? key}) : super(key: key);

  /// Carica tutti i prodotti attivi
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadProducts() {
    return FirebaseFirestore.instance
        .collection('products')
        .where('active', isEqualTo: true)
        .get()
        .then((snap) => snap.docs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: 'Choose your Plan'),
      body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        future: _loadProducts(),
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snap.data!;
          if (products.isEmpty) {
            return const Center(child: Text('No plans available'));
          }

          // Adatta colonne in base all’orientamento
          return OrientationBuilder(
            builder: (ctx, orientation) {
              final crossCount = orientation == Orientation.portrait ? 1 : 3;
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3 / 2,
                ),
                itemBuilder: (ctx, i) {
                  return _PlanCard(doc: products[i]);
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Card che visualizza nome, descrizione e prezzi (nested) di un prodotto.
/// Al tap restituisce il documento selezionato.
class _PlanCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _PlanCard({required this.doc});

  /// Carica tutti i prezzi attivi per questo prodotto
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadPrices() {
    return doc.reference
        .collection('prices')
        .where('active', isEqualTo: true)
        .get()
        .then((snap) => snap.docs);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = doc.data();
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).pop(doc),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppGradients.primary(theme),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titolo
              Text(
                data['name'] ?? 'Plan',
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: theme.colorScheme.onPrimary),
              ),
              const SizedBox(height: 8),

              // Descrizione
              Expanded(
                child: Text(
                  data['description'] ?? '',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onPrimary),
                ),
              ),
              const SizedBox(height: 12),

              // Prezzi nested
              FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                future: _loadPrices(),
                builder: (ctx, snap2) {
                  if (snap2.connectionState != ConnectionState.done) {
                    return const Text('Loading price…');
                  }
                  final prices = snap2.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: prices.map((p) {
                      final pd = p.data();
                      final amount = (pd['unit_amount'] as num) / 100;
                      final rec = pd['recurring'] as Map<String, dynamic>;
                      final interval = rec['interval'] ?? 'month';
                      return Text(
                        '€${amount.toStringAsFixed(2)} / $interval',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
