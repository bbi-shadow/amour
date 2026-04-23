import 'dart:io';
import 'package:flutter/foundation.dart'; // ✅ Thêm để dùng kIsWeb
import 'package:flutter/material.dart';
import '../services/database_helper.dart';

/// Widget tự động:
/// 1. Kiểm tra cache local SQLite
/// 2. Nếu có → dùng File local (nhanh, offline)
/// 3. Nếu chưa có → tải về, lưu cache, hiện lên
/// 4. Nếu thất bại → fallback placeholder
class CachedPhotoWidget extends StatefulWidget {
  final String uid;
  final String? photoUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final double? width;
  final double? height;

  const CachedPhotoWidget({
    super.key,
    required this.uid,
    required this.photoUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.width,
    this.height,
  });

  @override
  State<CachedPhotoWidget> createState() => _CachedPhotoWidgetState();
}

class _CachedPhotoWidgetState extends State<CachedPhotoWidget> {
  String? _localPath;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(CachedPhotoWidget old) {
    super.didUpdateWidget(old);
    if (old.photoUrl != widget.photoUrl || old.uid != widget.uid) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    if (!mounted) return;
    
    // ✅ Trên Web không dùng cache SQLite local file
    if (kIsWeb) {
      setState(() { _loading = false; });
      return;
    }

    setState(() { _loading = true; _failed = false; });

    // Bước 1: kiểm tra cache local để hiện ảnh ngay lập tức (không cần mạng)
    final cached = await DatabaseHelper.getCachedPhotoPath(widget.uid);
    if (cached != null && mounted) {
      setState(() { _localPath = cached; _loading = false; });
      return;
    }

    // Bước 2: tải về từ Cloudinary nếu chưa có trong máy
    if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty) {
      final downloaded = await DatabaseHelper.downloadAndCachePhoto(
          widget.uid, widget.photoUrl!);
      if (mounted) {
        setState(() {
          _localPath = downloaded;
          _loading = false;
          _failed = downloaded == null;
        });
      }
      return;
    }

    if (mounted) setState(() { _loading = false; _failed = true; });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Xử lý hiển thị trên Web
    if (kIsWeb) {
      if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty) {
        return Image.network(
          widget.photoUrl!,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
      return _placeholder();
    }

    if (_loading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.placeholder ??
            Container(color: const Color(0xFFFFE8ED),
                child: const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFFF4B6E), strokeWidth: 2))),
      );
    }

    if (!_failed && _localPath != null) {
      return Image.file(
        File(_localPath!),
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    // Fallback: thử Image.network nếu cache lỗi
    if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty) {
      return Image.network(
        widget.photoUrl!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _placeholder(loading: true);
        },
      );
    }

    return _placeholder();
  }

  Widget _placeholder({bool loading = false}) {
    return widget.placeholder ??
        Container(
          width: widget.width,
          height: widget.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF8E9B), Color(0xFFFF4B6E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: loading
              ? const Center(child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2))
              : const Center(
              child: Icon(Icons.person_rounded,
                  size: 60, color: Colors.white54)),
        );
  }
}
