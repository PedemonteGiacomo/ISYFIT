import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isyfit/presentation/widgets/gradient_app_bar.dart';
import 'package:isyfit/presentation/theme/app_gradients.dart';

class PlanSelectionScreen extends StatelessWidget {
  const PlanSelectionScreen({Key? key}) : super(key: key);

  // ────────────────────────────────────────────────────────────────────
  // Carica tutti i prodotti attivi
  // ────────────────────────────────────────────────────────────────────
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

          // ── ORDINA: start → growth → pro ────────────────────────────
          const order = ['start', 'growth', 'pro'];
          products.sort((a, b) {
            final ap = (a.data()['metadata']?['plan'] ?? '').toString().toLowerCase();
            final bp = (b.data()['metadata']?['plan'] ?? '').toString().toLowerCase();
            return order.indexOf(ap).compareTo(order.indexOf(bp));
          });

          // ── Layout responsivo ───────────────────────────────────────
          return OrientationBuilder(
            builder: (ctx, orientation) {
              final isPortrait = orientation == Orientation.portrait;
              final crossCount = isPortrait ? 1 : 3;
              final aspect     = isPortrait ? 3 / 2 : 4 / 3; // un po’ più alto in landscape

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: aspect,
                ),
                itemBuilder: (ctx, i) => _PlanCard(doc: products[i]),
              );
            },
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Card che visualizza nome, descrizione e prezzi di un prodotto
// ──────────────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _PlanCard({required this.doc});

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
    final data  = doc.data();

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

              // Descrizione (max 2 righe per evitare overflow)
              Expanded(
                child: Text(
                  data['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onPrimary),
                ),
              ),
              const SizedBox(height: 12),

              // Prezzi
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
                      final pd       = p.data();
                      final amount   = (pd['unit_amount'] as num) / 100;
                      final interval = (pd['recurring']?['interval'] ?? 'month').toString();
                      return Text(
                        '€${amount.toStringAsFixed(2)} / $interval',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(color: theme.colorScheme.onPrimary),
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
