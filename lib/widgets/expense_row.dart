import 'package:flutter/material.dart';
import '../core/responsive.dart';

class ExpenseRow extends StatelessWidget {
  const ExpenseRow({
    super.key,
    required this.index,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    required this.onItemNameChanged,
    required this.onCategoryChanged,
    required this.onQuantityChanged,
    required this.onUnitPriceChanged,
    required this.onDelete,
  });

  final int index;
  final String itemName;
  final String category;
  final double quantity;
  final double unitPrice;
  final ValueChanged<String> onItemNameChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<double> onQuantityChanged;
  final ValueChanged<double> onUnitPriceChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isWide(context);

    final categoryDropdown = DropdownButtonFormField<String>(
      initialValue: category,
      decoration: const InputDecoration(
        labelText: 'التصنيف',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: const [
        DropdownMenuItem(value: 'materials', child: Text('مواد')),
        DropdownMenuItem(value: 'labor', child: Text('عمالة')),
        DropdownMenuItem(value: 'fuel', child: Text('وقود')),
        DropdownMenuItem(value: 'equipment', child: Text('معدات')),
        DropdownMenuItem(value: 'transport', child: Text('نقل')),
        DropdownMenuItem(value: 'other', child: Text('أخرى')),
      ],
      onChanged: (v) {
        if (v != null) onCategoryChanged(v);
      },
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: isWide
            // ================= عرض الشاشات العريضة (سطر أفقي متناسق) =================
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: itemName,
                      decoration: const InputDecoration(
                        labelText: 'البند (مثال: أسمنت، وقود حافلة)',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: onItemNameChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: categoryDropdown,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: quantity == 0 ? '' : '$quantity',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'الكمية',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (v) => onQuantityChanged(double.tryParse(v) ?? 0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: unitPrice == 0 ? '' : '$unitPrice',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'سعر الوحدة',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (v) => onUnitPriceChanged(double.tryParse(v) ?? 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    tooltip: 'حذف البند',
                    onPressed: onDelete,
                  ),
                ],
              )
            // ================= عرض الهاتف =================
            : Column(
                children: [
                  TextFormField(
                    initialValue: itemName,
                    decoration: const InputDecoration(
                      labelText: 'البند',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: onItemNameChanged,
                  ),
                  const SizedBox(height: 8),
                  categoryDropdown,
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: quantity == 0 ? '' : '$quantity',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'الكمية',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => onQuantityChanged(double.tryParse(v) ?? 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: unitPrice == 0 ? '' : '$unitPrice',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'سعر الوحدة',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => onUnitPriceChanged(double.tryParse(v) ?? 0),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: onDelete,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
