import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ForumPage extends StatefulWidget {
  final dynamic user;
  const ForumPage({super.key, this.user});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _posts = [];
  bool _isPageLoading = true;

  final String serverUrl = "http://10.60.56.48/dacs3";

  static const vkuBlue = Color(0xFF072C6C);
  static const vkuOrange = Color(0xFFFF8C00);
  static const sandBg = Color(0xFFF5E1C5);
  static const cardWhite = Color(0xFFFFFFFF);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    try {
      final res = await http.get(Uri.parse("$serverUrl/forum_manage.php")).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _posts = jsonDecode(res.body);
          _isPageLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isPageLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sandBg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header có nút back (Giống image_2cb256.png)
            _buildCustomHeader(),

            // 2. Thanh chuyển đổi Tab
            _buildTabSwitcher(),

            // 3. Ô "Bạn đang nghĩ gì?" đưa xuống dưới (Theo ý ông)
            _buildForumInputCard(),

            // 4. Thanh tiêu đề ngăn cách có vạch cam (Giống image_2d03f9.png)
            _buildSectionTitle(_tabController.index == 0 ? "BẢN TIN SINH VIÊN" : "DANH MỤC HÀNG HÓA"),

            // 5. Danh sách bài viết
            Expanded(
              child: _isPageLoading
                  ? const Center(child: CircularProgressIndicator(color: vkuOrange))
                  : TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildPostListView('confession'),
                  _buildPostListView('market'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 10,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: vkuBlue, size: 20),
            ),
          ),
          const Text(
            "DIỄN ĐÀN VKU",
            style: TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      margin: const EdgeInsets.fromLTRB(25, 10, 25, 10), // Tăng margin cho thoáng
      height: 50, // Cố định chiều cao để không bị bóp méo
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6), // Nền trắng mờ trên nền cát
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) => setState(() {}),
        // --- PHẦN SỬA LỖI CHÍNH ---
        indicator: BoxDecoration(
          color: vkuBlue,
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorSize: TabBarIndicatorSize.tab, // Để nó kéo dài hết một ô tab
        indicatorPadding: const EdgeInsets.all(4), // Tạo khoảng cách để không dính viền
        labelColor: Colors.white,
        unselectedLabelColor: vkuBlue,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: "Bài viết"),
          Tab(text: "Chợ cũ"),
        ],
      ),
    );
  }

  Widget _buildForumInputCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 5, 20, 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: vkuBlue.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: InkWell(
        onTap: () => _openCreatePostModal(),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: sandBg,
              backgroundImage: (widget.user['avatar_url'] != null && widget.user['avatar_url'] != "")
                  ? NetworkImage(widget.user['avatar_url']) : null,
              child: (widget.user['avatar_url'] == null || widget.user['avatar_url'] == "")
                  ? const Icon(Icons.person, color: vkuBlue, size: 20) : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                "Bạn đang nghĩ gì thế?",
                style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
            Icon(Icons.image_search_rounded, color: vkuOrange.withOpacity(0.7), size: 22),
          ],
        ),
      ),
    );
  }

  // --- WIDGET NGĂN CÁCH CÓ VẠCH CAM (GIỐNG image_2d03f9.png) ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 5, 25, 15),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 18,
            decoration: BoxDecoration(
              color: vkuOrange,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
                color: vkuBlue,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 0.5
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostListView(String type) {
    List<dynamic> filteredList = _posts.where((p) => p['type'] == type).toList();
    return RefreshIndicator(
      onRefresh: _loadPosts,
      color: vkuOrange,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 30),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredList.length,
        itemBuilder: (context, index) => _buildPostCard(filteredList[index]),
      ),
    );
  }

  Widget _buildPostCard(dynamic post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: sandBg,
              backgroundImage: (post['avatar_url'] != null && post['avatar_url'] != "")
                  ? NetworkImage(post['avatar_url']) : null,
              child: (post['avatar_url'] == null || post['avatar_url'] == "")
                  ? const Icon(Icons.person, color: vkuBlue, size: 18) : null,
            ),
            title: Text(post['fullname'] ?? "Thành viên VKU",
                style: const TextStyle(fontWeight: FontWeight.w900, color: vkuBlue, fontSize: 13)),
            subtitle: Text(post['created_at'] ?? "", style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post['type'] == 'market')
                  Text("${post['price']} VNĐ", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 5),
                Text(post['title'] ?? "", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: vkuBlue)),
                const SizedBox(height: 5),
                Text(post['content'] ?? "", style: TextStyle(color: Colors.blueGrey[800], fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          if (post['image_url'] != null && post['image_url'] != "")
            Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(post['image_url'], width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(height: 100, color: Colors.grey[100], child: const Icon(Icons.broken_image))),
              ),
            ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => _openCommentsModal(post),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: vkuBlue),
                  label: Text(
                    (post['comment_count'] != null && post['comment_count'] != "0")
                        ? "${post['comment_count']} Bình luận" : "Bình luận",
                    style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 11),
                  ),
                ),
                const Spacer(),
                IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border_rounded, size: 18, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- GIỮ NGUYÊN LOGIC CŨ CỦA ÔNG ---
  void _openCreatePostModal() {
    String currentType = _tabController.index == 0 ? 'confession' : 'market';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
          padding: EdgeInsets.fromLTRB(25, 15, 25, MediaQuery.of(context).viewInsets.bottom + 25),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text("ĐĂNG BÀI ${currentType == 'market' ? 'CHỢ CŨ' : 'TÂM SỰ'}", style: const TextStyle(fontWeight: FontWeight.w900, color: vkuBlue, fontSize: 16)),
                const SizedBox(height: 20),
                _buildTextField(_titleController, "Tiêu đề bài viết..."),
                if (currentType == 'market') ...[
                  const SizedBox(height: 12),
                  _buildTextField(_priceController, "Giá bán (VNĐ)...", isNumber: true),
                ],
                const SizedBox(height: 12),
                _buildTextField(_contentController, "Nội dung chi tiết...", maxLines: 4),
                const SizedBox(height: 20),
                if (_selectedImage != null)
                  Stack(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_selectedImage!, height: 150, width: double.infinity, fit: BoxFit.cover)),
                      Positioned(right: 5, top: 5, child: CircleAvatar(backgroundColor: Colors.black54, radius: 15, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 14), onPressed: () => setModalState(() => _selectedImage = null))))
                    ],
                  ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () async {
                    final img = await _picker.pickImage(source: ImageSource.gallery);
                    if (img != null) setModalState(() => _selectedImage = File(img.path));
                  },
                  icon: const Icon(Icons.image_rounded, color: vkuOrange),
                  label: const Text("Thêm hình ảnh", style: TextStyle(color: vkuOrange, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: vkuBlue, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                    onPressed: _isSubmitting ? null : () => _handleCreatePost(currentType),
                    child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("ĐĂNG BÀI NGAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCreatePost(String type) async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse("$serverUrl/forum_manage.php"));
      request.fields['action'] = 'add_post';
      request.fields['user_id'] = widget.user['id'].toString();
      request.fields['type'] = type;
      request.fields['title'] = _titleController.text;
      request.fields['content'] = _contentController.text;
      request.fields['price'] = _priceController.text;
      if (_selectedImage != null) request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));
      var res = await request.send();
      if (res.statusCode == 200 && mounted) {
        Navigator.pop(context); _clearForm(); _loadPosts();
      }
    } catch (e) { debugPrint(e.toString()); }
    finally { if (mounted) setState(() => _isSubmitting = false); }
  }

  void _openCommentsModal(dynamic post) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 15),
              const Text("BÌNH LUẬN", style: TextStyle(fontWeight: FontWeight.w900, color: vkuBlue)),
              const Divider(),
              Expanded(
                child: FutureBuilder<http.Response>(
                  future: http.get(Uri.parse("$serverUrl/forum_manage.php?post_id=${post['id']}")),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    List<dynamic> comments = jsonDecode(snapshot.data!.body);
                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: comments.length,
                      itemBuilder: (context, index) => Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(radius: 18, backgroundColor: sandBg, child: Icon(Icons.person, size: 20, color: vkuBlue)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(18)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(comments[index]['fullname'] ?? "Sinh viên", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: vkuBlue)),
                                    const SizedBox(height: 4),
                                    Text(comments[index]['comment_text'] ?? "", style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildCommentInput(post['id'], setModalState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentInput(dynamic postId, StateSetter setModalState) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: Row(
        children: [
          Expanded(child: _buildTextField(_commentController, "Viết bình luận...")),
          const SizedBox(width: 10),
          CircleAvatar(backgroundColor: vkuBlue, child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: () => _handleSendComment(postId, setModalState))),
        ],
      ),
    );
  }

  Future<void> _handleSendComment(dynamic postId, StateSetter setModalState) async {
    if (_commentController.text.isEmpty) return;
    try {
      final res = await http.post(Uri.parse("$serverUrl/forum_manage.php"), body: {
        "action": "add_comment", "post_id": postId.toString(), "user_id": widget.user['id'].toString(), "comment_text": _commentController.text
      });
      if (res.statusCode == 200) {
        _commentController.clear(); setModalState(() {}); _loadPosts();
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: ctrl, keyboardType: isNumber ? TextInputType.number : TextInputType.multiline, maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(hintText: hint, filled: true, fillColor: Colors.grey[100], contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)),
    );
  }

  void _clearForm() { _titleController.clear(); _contentController.clear(); _priceController.clear(); _selectedImage = null; }
}