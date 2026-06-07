// --- HÀM XÓA SẢN PHẨM TRỰC TIẾP TRÊN FIRESTORE (THAY THẾ FILE PHP) ---
Future<void> deleteMarketplaceProduct(String docId, BuildContext context, VoidCallback onRefresh) async {
  try {
    // Gọi lệnh xóa document trực tiếp dựa trên ID của món đồ trên mây
    await FirebaseFirestore.instance.collection('marketplace').doc(docId).delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Đã xóa sản phẩm thành công khỏi hệ thống mây!"),
          backgroundColor: Color(0xFF072C6C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      onRefresh(); // Gọi lại hàm tải danh sách chợ để cập nhật lại UI 120 FPS
    }
  } catch (e) {
    debugPrint("Lỗi xóa sản phẩm mây: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Không thể xóa: ${e.toString()}"), backgroundColor: Colors.redAccent),
      );
    }
  }
}