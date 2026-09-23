import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/pos_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/product.dart';
import '../../widgets/glass_card.dart';

class MenuManagementView extends StatefulWidget {
  const MenuManagementView({super.key});

  @override
  State<MenuManagementView> createState() => _MenuManagementViewState();
}

class _MenuManagementViewState extends State<MenuManagementView> {
  String? _selectedCategory;

  void _showAddProductDialog() {
    final pos = context.read<PosProvider>();
    final admin = context.read<AdminProvider>();

    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String catId = pos.categories.isNotEmpty ? pos.categories.first.id : 'cat-1';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Yeni Ürün Ekle',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Ürün Adı', hintText: 'Örn: Filtre Kahve'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Fiyat (₺)', hintText: 'Örn: 90.00'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: catId,
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: pos.categories.map((c) {
                  return DropdownMenuItem(value: c.id, child: Text(c.name));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => catId = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Vazgeç', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                if (name.isNotEmpty && price > 0) {
                  final newProd = Product(
                    id: 'p-${DateTime.now().millisecondsSinceEpoch}',
                    categoryId: catId,
                    name: name,
                    price: price,
                  );
                  await admin.saveProduct(newProd);
                  await pos.loadInitialData();
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    return Column(
      children: [
        // Kategori Seçici ve Yeni Ürün Ekle Butonu
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: pos.categories.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSel = _selectedCategory == null;
                        return ChoiceChip(
                          label: const Text('Tümü'),
                          selected: isSel,
                          onSelected: (_) => setState(() => _selectedCategory = null),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                        );
                      }
                      final cat = pos.categories[index - 1];
                      final isSel = _selectedCategory == cat.id;
                      return ChoiceChip(
                        label: Text(cat.name),
                        selected: isSel,
                        onSelected: (_) => setState(() => _selectedCategory = cat.id),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.add, color: Colors.black),
                style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                tooltip: 'Yeni Ürün Ekle',
                onPressed: _showAddProductDialog,
              ),
            ],
          ),
        ),

        // Ürün Listesi
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pos.products.where((p) {
              if (_selectedCategory == null) return true;
              return p.categoryId == _selectedCategory;
            }).length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final prods = pos.products.where((p) {
                if (_selectedCategory == null) return true;
                return p.categoryId == _selectedCategory;
              }).toList();
              final product = prods[index];

              return GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                borderRadius: 12,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          if (product.modifiers.isNotEmpty)
                            Text(
                              '${product.modifiers.length} alt opsiyon',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '₺${product.price.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                      onPressed: () {
                        // Hızlı Fiyat Düzenleme
                        _showEditPriceDialog(product);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEditPriceDialog(Product product) {
    final controller = TextEditingController(text: product.price.toStringAsFixed(2));
    final admin = context.read<AdminProvider>();
    final pos = context.read<PosProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('${product.name} Fiyatı'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Yeni Fiyat (₺)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final newP = double.tryParse(controller.text.trim()) ?? product.price;
              final updated = Product(
                id: product.id,
                categoryId: product.categoryId,
                name: product.name,
                price: newP,
                modifiers: product.modifiers,
                isFavorite: product.isFavorite,
              );
              await admin.saveProduct(updated);
              await pos.loadInitialData();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }
}
