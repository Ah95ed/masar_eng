class ExpenseItem {
  final int? id;
  final String itemName;
  final String category;
  final double quantity;
  final double unitPrice;
  final double? total;
  final String? notes;

  const ExpenseItem({
    this.id,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    this.total,
    this.notes,
  });

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] is num)
        ? (json['quantity'] as num).toDouble()
        : double.tryParse('${json['quantity']}') ?? 0.0;
    final price = (json['unit_price'] is num)
        ? (json['unit_price'] as num).toDouble()
        : double.tryParse('${json['unit_price']}') ?? 0.0;
    final tot = (json['total'] is num)
        ? (json['total'] as num).toDouble()
        : (qty * price);

    return ExpenseItem(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}'),
      itemName: json['item_name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'materials',
      quantity: qty,
      unitPrice: price,
      total: tot,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'item_name': itemName,
    'category': category,
    'quantity': quantity,
    'unit_price': unitPrice,
    if (total != null) 'total': total,
    'notes': notes ?? '',
  };
}
