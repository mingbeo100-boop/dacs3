Future<void> manageTicketActionCloud({
  required String ticketDocId,
  required String action, // 'resolved', 'processing' hoặc 'delete'
  required BuildContext context,
  required VoidCallback onRefresh,
}) async {
  try {
    final docRef = FirebaseFirestore.instance.collection('tickets').doc(ticketDocId);

    if (action == 'delete') {
      await docRef.delete(); // Lệnh xoá sổ tài liệu khỏi mây Firestore
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🗑️ Đã xoá phiếu báo hỏng thành công!")));
    } else {
      await docRef.update({
        'status': action, // Cập nhật trạng thái mới (Ví dụ: Đã sửa xong)
        'updated_at': DateTime.now().toString().substring(0, 19),
      });
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Đã cập nhật trạng thái phiếu!"), backgroundColor: Colors.green));
    }
    onRefresh(); // Làm mới lại UI danh sách 120 FPS phản hồi siêu tốc
  } catch (e) {
    debugPrint("Lỗi thao tác phiếu sửa chữa: $e");
  }
}