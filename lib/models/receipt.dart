class ReceiptItem {
  final int id;
  final String filePath;
  final String originalName;
  final String? fileType;
  final int? fileSize;
  final String? uploadedAt;

  const ReceiptItem({
    required this.id,
    required this.filePath,
    required this.originalName,
    this.fileType,
    this.fileSize,
    this.uploadedAt,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      filePath: json['file_path']?.toString() ?? '',
      originalName: json['original_name']?.toString() ?? '',
      fileType: json['file_type']?.toString(),
      fileSize: json['file_size'] is int ? json['file_size'] : int.tryParse('${json['file_size']}'),
      uploadedAt: json['uploaded_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'file_path': filePath,
    'original_name': originalName,
    'file_type': fileType,
    'file_size': fileSize,
    'uploaded_at': uploadedAt,
  };
}
