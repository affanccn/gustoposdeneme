import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/pos_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/table.dart';
import '../../models/product.dart';
import '../../models/order.dart';
import '../../widgets/glass_card.dart';
import 'checkout_dialog.dart';
import 'transfer_table_dialog.dart';

class PosOrderScreen extends StatefulWidget {
  final PosTable table;

  const PosOrderScreen({super.key, required this.table});

  @override
  State<PosOrderScreen> createState() => _PosOrderScreenState();
}

class _PosOrderScreenState extends State<PosOrderScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Modifier Seçim Dialogu
  void _showModifierDialog(Product product) {
    if (product.modifiers.isEmpty) {
      context.read<PosProvider>().addToCart(product);
      return;
    }

    final selectedMods = <Modifier>[];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '₺${product.price.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'İsteğe Bağlı Seçenekler',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const Divider(color: AppColors.cardBorder, height: 24),
                  ...product.modifiers.map((mod) {
                    final isChecked = selectedMods.contains(mod);
                    return CheckboxListTile(
                      value: isChecked,
                      onChanged: (val) {
                        setSheetState(() {
                          if (val == true) {
                            selectedMods.add(mod);
                          } else {
                            selectedMods.remove(mod);
                          }
                        });
                      },
                      title: Text(
                        mod.name,
                        style: GoogleFonts.inter(color: AppColors.textPrimary),
                      ),
                      subtitle: mod.price > 0
                          ? Text('+₺${mod.price.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(color: AppColors.primary))
                          : const Text('Ücretsiz', style: TextStyle(color: AppColors.textMuted)),
                      activeColor: AppColors.primary,
                      checkColor: Colors.black,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<PosProvider>().addToCart(product, modifiers: selectedMods);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Sepete Ekle',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
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

  // Sipariş Notu Giriş Dialogu
  void _showOrderNoteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Sipariş Notu', style: GoogleFonts.inter(color: AppColors.textPrimary)),
        content: TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Örn: Masaya acil servis, az pişmiş...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // Mutfak Siparişini Gönder
  void _submitOrder() async {
    final pos = context.read<PosProvider>();
    final auth = context.read<AuthProvider>();

    final success = await pos.submitOrder(
      auth.currentUser.id,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (mounted) {
      if (success) {
        _noteController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sipariş başarıyla onaylandı ve mutfağa iletildi!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pos.errorMessage ?? 'Sipariş iletilemedi.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final currentTable = pos.selectedTable ?? widget.table;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentTable.name,
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              '${currentTable.area} • ${currentTable.durationString.isNotEmpty ? currentTable.durationString : 'Yeni'}',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          // Masa Taşıma Butonu
          IconButton(
            tooltip: 'Masa Taşı / Birleştir',
            icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.textSecondary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => TransferTableDialog(sourceTable: currentTable),
              );
            },
          ),
          // Hesap Al Butonu
          if (!currentTable.isEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12.0, left: 4.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => CheckoutDialog(table: currentTable),
                  );
                },
                icon: const Icon(Icons.payments_rounded, size: 16, color: Colors.black),
                label: const Text('Ödeme Al', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 700;

          if (isTablet) {
            // Tablet Görünümü: Yan Yana (Sol: Menü, Sağ: Adisyon Sepeti)
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildMenuSection(pos),
                ),
                Container(width: 1, color: AppColors.cardBorder),
                Expanded(
                  flex: 2,
                  child: _buildOrderTray(pos, currentTable),
                ),
              ],
            );
          } else {
            // Telefon Görünümü: Dikey Sekmeli veya Alt Sepet Panelli
            return Column(
              children: [
                Expanded(child: _buildMenuSection(pos)),
                _buildMobileCartBar(pos, currentTable),
              ],
            );
          }
        },
      ),
    );
  }

  // Menü ve Kategori Bölümü
  Widget _buildMenuSection(PosProvider pos) {
    return Column(
      children: [
        // Kategori Çubuğu
        Container(
          height: 48,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: pos.categories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = pos.selectedCategoryId == null || pos.selectedCategoryId == 'ALL';
                return ChoiceChip(
                  label: const Text('Tüm Menü'),
                  selected: isSelected,
                  onSelected: (_) => pos.setCategory('ALL'),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  labelStyle: GoogleFonts.inter(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.black : AppColors.textSecondary,
                  ),
                );
              }
              final cat = pos.categories[index - 1];
              final isSelected = pos.selectedCategoryId == cat.id;
              return ChoiceChip(
                label: Text(cat.name),
                selected: isSelected,
                onSelected: (_) => pos.setCategory(cat.id),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                labelStyle: GoogleFonts.inter(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black : AppColors.textSecondary,
                ),
              );
            },
          ),
        ),

        // Ürünler Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.15,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: pos.filteredProducts.length,
            itemBuilder: (context, index) {
              final product = pos.filteredProducts[index];
              return _buildProductCard(product);
            },
          ),
        ),
      ],
    );
  }

  // Ürün Kartı
  Widget _buildProductCard(Product product) {
    return GlassCard(
      borderRadius: 14,
      padding: const EdgeInsets.all(12),
      onTap: () => _showModifierDialog(product),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (product.isFavorite)
                const Icon(Icons.star_rounded, color: AppColors.primary, size: 18)
              else
                const SizedBox.shrink(),
              if (product.modifiers.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+Opsiyon',
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.primaryLight),
                  ),
                ),
            ],
          ),
          Text(
            product.name,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '₺${product.price.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Adisyon ve Sepet Bölümü (Tablet Panel)
  Widget _buildOrderTray(PosProvider pos, PosTable currentTable) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Adisyon Detayı',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  tooltip: 'Sipariş Notu',
                  icon: const Icon(Icons.note_add_outlined, color: AppColors.primary),
                  onPressed: _showOrderNoteDialog,
                ),
              ],
            ),
          ),

          // Liste
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Mevcut Onaylı Siparişler (Mutfakta Olanlar)
                if (pos.activeOrder != null && pos.activeOrder!.items.isNotEmpty) ...[
                  Text(
                    'ONAYLANMIŞ SİPARİŞLER',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...pos.activeOrder!.items.map((item) => _buildExistingOrderItem(item)),
                  const Divider(color: AppColors.cardBorder, height: 24),
                ],

                // Yeni Eklenecek Sepet Kalemleri
                if (pos.cartItems.isNotEmpty) ...[
                  Text(
                    'YENİ EKLENENLER (MUTFAĞA İLETİLECEK)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...pos.cartItems.asMap().entries.map((entry) {
                    return _buildCartItemRow(pos, entry.key, entry.value);
                  }),
                ] else if (pos.activeOrder == null || pos.activeOrder!.items.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        'Adisyonda ürün bulunmuyor.\nMenüden ürün ekleyin.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Alt Toplam ve Gönder Butonu
          _buildTrayFooter(pos, currentTable),
        ],
      ),
    );
  }

  // Onaylanmış Ürün Satırı
  Widget _buildExistingOrderItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.quantity.toInt()}x ${item.productName}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.selectedModifiers.isNotEmpty)
                  Text(
                    item.selectedModifiers.map((m) => m['name']).join(', '),
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          Text(
            '₺${item.totalPrice.toStringAsFixed(2)}',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Sepetteki Ürün Satırı (+ / - Butonlu)
  Widget _buildCartItemRow(PosProvider pos, int index, OrderItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                if (item.selectedModifiers.isNotEmpty)
                  Text(
                    item.selectedModifiers.map((m) => m['name']).join(', '),
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.primaryLight),
                  ),
                Text(
                  '₺${item.totalPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.danger),
                onPressed: () => pos.updateCartQuantity(index, -1),
              ),
              Text(
                '${item.quantity.toInt()}',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                onPressed: () => pos.updateCartQuantity(index, 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Sepet Alt Bilgi ve Gönderim
  Widget _buildTrayFooter(PosProvider pos, PosTable currentTable) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Toplam Tutar:', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
              Text(
                '₺${pos.tableProjectedTotal.toStringAsFixed(2)}',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pos.cartItems.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _submitOrder,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  'Mutfağa Gönder (${pos.cartItems.length} ürün)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Mobil Cihazlar İçin Alt Sepet Çubuğu
  Widget _buildMobileCartBar(PosProvider pos, PosTable currentTable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Toplam (${pos.cartItems.length} yeni)',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                ),
                Text(
                  '₺${pos.tableProjectedTotal.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.list_alt_rounded, color: AppColors.textSecondary),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.surface,
                  builder: (_) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: _buildOrderTray(pos, currentTable),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: pos.cartItems.isEmpty ? null : _submitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Siparişi Gönder', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
