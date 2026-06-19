import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Sử dụng duy nhất Firestore để dò bảng dữ liệu
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // BẮT BUỘC: Giải mã chuỗi Base64 avatar động của cư dân KTX
import 'package:firebase_storage/firebase_storage.dart';

class ForumPage extends StatefulWidget {
  final dynamic user;
  const ForumPage({super.key, this.user});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _priceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sandBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(),
            _buildTabSwitcher(),
            _buildForumInputCard(),
            _buildSectionTitle(_tabController.index == 0 ? "BẢN TIN SINH VIÊN" : "DANH MỤC HÀNG HÓA"),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildPostStreamView('confession'),
                  _buildPostStreamView('market'),
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
      margin: const EdgeInsets.fromLTRB(25, 10, 25, 10),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) => setState(() {}),
        indicator: BoxDecoration(
          color: vkuBlue,
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
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
    String currentMssv = (widget.user['username'] ?? "").toString().trim();
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
            // DÒ PROFILE O(1): Tự động bốc avatar Base64 của chính mình tại ô đăng bài
            StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('profiles').doc(currentMssv).snapshots(),
                builder: (context, snapshot) {
                  ImageProvider? myAvatar;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    String raw = (snapshot.data!.data() as Map<String, dynamic>)['avatar_url'] ?? "";
                    myAvatar = _parseBase64Avatar(raw);
                  }
                  return CircleAvatar(
                    radius: 18,
                    backgroundColor: sandBg,
                    backgroundImage: myAvatar,
                    child: myAvatar == null ? const Icon(Icons.person, color: vkuBlue, size: 20) : null,
                  );
                }
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 5, 25, 15),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 18,
            decoration: BoxDecoration(color: vkuOrange, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildPostStreamView(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('type', isEqualTo: type)
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("Đang đồng bộ chỉ mục mây hoặc lỗi: ${snapshot.error}", style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: vkuOrange));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Chưa có bài đăng nào ở danh mục này.", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)));
        }

        var docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 30),
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> postData = docs[index].data() as Map<String, dynamic>;
            postData['id'] = docs[index].id;
            return _buildPostCard(postData);
          },
        );
      },
    );
  }

  Widget _buildPostCard(dynamic post) {
    String authorMssv = (post['username'] ?? "").toString().trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DÒ PROFILE LIVE O(1): Tìm avatar và họ tên mới nhất của tác giả bài viết
          StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('profiles').doc(authorMssv).snapshots(),
              builder: (context, profSnapshot) {
                String authorName = post['fullname'] ?? "Thành viên VKU";
                ImageProvider? authorAvatar;

                if (profSnapshot.hasData && profSnapshot.data!.exists) {
                  var pData = profSnapshot.data!.data() as Map<String, dynamic>;
                  authorName = pData['fullname'] ?? authorName;
                  authorAvatar = _parseBase64Avatar(pData['avatar_url'] ?? "");
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: sandBg,
                    backgroundImage: authorAvatar,
                    child: authorAvatar == null ? const Icon(Icons.person, color: vkuBlue, size: 18) : null,
                  ),
                  title: Text(authorName, style: const TextStyle(fontWeight: FontWeight.w900, color: vkuBlue, fontSize: 13)),
                  subtitle: Text(post['created_at'] ?? "", style: const TextStyle(fontSize: 9, color: Colors.grey)),
                );
              }
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
                    (post['comment_count'] != null && post['comment_count'] != 0)
                        ? "${post['comment_count']} Bình luận" : "Bình luận",
                    style: const TextStyle(color: vkuBlue, fontWeight: FontWeight.w900, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
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
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      String imageUrl = "";

      if (_selectedImage != null) {
        String fileName = "forum_${DateTime.now().millisecondsSinceEpoch}.jpg";
        Reference storageRef = FirebaseStorage.instance.ref().child("forum/$fileName");
        UploadTask uploadTask = storageRef.putFile(_selectedImage!);
        TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('posts').add({
        'username': widget.user['username'].toString().trim(),
        'fullname': widget.user['fullname'] ?? "Thành viên VKU",
        'type': type,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'price': type == 'market' ? _priceController.text.trim() : "",
        'image_url': imageUrl,
        'comment_count': 0,
        'created_at': DateTime.now().toString().substring(0, 19),
      });

      if (mounted) {
        Navigator.pop(context);
        _clearForm();
      }
    } catch (e) {
      debugPrint("Lỗi đăng bài viết: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(post['id'])
                      .collection('comments')
                      .orderBy('created_at', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    var commentDocs = snapshot.data!.docs;
                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: commentDocs.length,
                      itemBuilder: (context, index) {
                        var commentData = commentDocs[index].data() as Map<String, dynamic>;
                        String commenterMssv = (commentData['username'] ?? "").toString().trim();

                        // DÒ PROFILE BÌNH LUẬN O(1): Kéo tên và avatar động của sinh viên comment
                        return StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance.collection('profiles').doc(commenterMssv).snapshots(),
                            builder: (context, profSnapshot) {
                              String cName = commentData['fullname'] ?? "Sinh viên";
                              ImageProvider? cAvatar;

                              if (profSnapshot.hasData && profSnapshot.data!.exists) {
                                var pData = profSnapshot.data!.data() as Map<String, dynamic>;
                                cName = pData['fullname'] ?? cName;
                                cAvatar = _parseBase64Avatar(pData['avatar_url'] ?? "");
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: sandBg,
                                      backgroundImage: cAvatar,
                                      child: cAvatar == null ? const Icon(Icons.person, size: 20, color: vkuBlue) : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(18)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(cName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: vkuBlue)),
                                            const SizedBox(height: 4),
                                            Text(commentData['comment_text'] ?? "", style: const TextStyle(fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                        );
                      },
                    );
                  },
                ),
              ),
              _buildCommentInput(post, setModalState),
            ],
          ),
        ),
      ),
    );
  }

  // --- LUỒNG AVATAR ĐỘNG VÀO Ô NHẬP BÌNH LUẬN CỦA CHÍNH BẠN ---
  Widget _buildCommentInput(dynamic post, StateSetter setModalState) {
    String myMssv = (widget.user['username'] ?? "").toString().trim();

    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: Row(
        children: [
          // DÒ PROFILE LIVE O(1): Hiển thị Avatar Base64 của bạn kế bên ô nhập text bình luận công phá
          StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('profiles').doc(myMssv).snapshots(),
              builder: (context, snapshot) {
                ImageProvider? inputAvatar;
                if (snapshot.hasData && snapshot.data!.exists) {
                  var pData = snapshot.data!.data() as Map<String, dynamic>;
                  inputAvatar = _parseBase64Avatar(pData['avatar_url'] ?? "");
                }

                return CircleAvatar(
                  radius: 18,
                  backgroundColor: sandBg,
                  backgroundImage: inputAvatar,
                  child: inputAvatar == null ? const Icon(Icons.person, size: 18, color: vkuBlue) : null,
                );
              }
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildTextField(_commentController, "Viết bình luận...")),
          const SizedBox(width: 10),
          CircleAvatar(backgroundColor: vkuBlue, child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: () => _handleSendComment(post, setModalState))),
        ],
      ),
    );
  }

  Future<void> _handleSendComment(dynamic post, StateSetter setModalState) async {
    if (_commentController.text.trim().isEmpty) return;
    try {
      final String commentText = _commentController.text.trim();
      final DocumentReference postRef = FirebaseFirestore.instance.collection('posts').doc(post['id']);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) return;

        DocumentReference newCommentRef = postRef.collection('comments').doc();
        transaction.set(newCommentRef, {
          "username": widget.user['username'].toString().trim(),
          "fullname": widget.user['fullname'] ?? "Sinh viên",
          "comment_text": commentText,
          "created_at": DateTime.now().toString().substring(0, 19),
        });

        int currentCount = 0;
        if (postSnapshot.data() != null) {
          var data = postSnapshot.data() as Map<String, dynamic>;
          currentCount = data['comment_count'] ?? 0;
        }
        transaction.update(postRef, {'comment_count': currentCount + 1});
      });

      _commentController.clear();
      setModalState(() {});
    } catch (e) {
      debugPrint("Lỗi gửi bình luận: $e");
    }
  }

  // --- CƠ CHẾ GIẢI MÃ CHẤP MỌI LOẠI ĐỊNH DẠNG BASE64 CHỐNG LỖI ẨN ẢNH ---
  ImageProvider? _parseBase64Avatar(String rawBase64) {
    if (rawBase64.trim().isEmpty) return null;
    try {
      // 1. Làm sạch chuỗi hoàn toàn khỏi các ký tự xuống dòng rác do Firestore tự sinh
      String cleanStr = rawBase64.replaceAll('\n', '').replaceAll('\r', '').trim();

      // 2. Nếu chuỗi có chứa dấu phẩy (Cấu trúc header data:image/jpeg;base64,xxxx)
      if (cleanStr.contains(',')) {
        cleanStr = cleanStr.split(',')[1];
      }

      // 3. Tiến hành giải mã mảng byte trực tiếp trên RAM O(1)
      return MemoryImage(base64Decode(cleanStr));
    } catch (e) {
      debugPrint("Lỗi phân rã chuỗi mã hóa tại diễn đàn: $e");
      return null;
    }
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