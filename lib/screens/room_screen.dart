import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../models/room.dart';
import '../widgets/shared_widgets.dart';
import '../services/api.dart';

class RoomScreen extends StatefulWidget {
  final Room room;

  const RoomScreen({super.key, required this.room});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen>
    with SingleTickerProviderStateMixin {
  late Room _room;
  late final AnimationController _fabAnim;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  void _copyRoomCode() {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: _room.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Room code copied!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // FIX: was a stub that only showed "File picker not available in demo".
  // Now opens the real system file picker, uploads the chosen file to the
  // server via multipart POST, and adds it to the local file list on success.
  Future<void> _handleUpload() async {
    HapticFeedback.mediumImpact();

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return; // user cancelled

    final picked = result.files.first;

    if (picked.bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read file bytes.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final response = await uploadFile(
      roomCode: _room.code,
      fileName: picked.name,
      fileBytes: picked.bytes!,
    );

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (response['success'] == true) {
      final ext = picked.name.contains('.')
          ? picked.name.split('.').last
          : 'file';

      final newFile = SharedFile(
        id: response['file_id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: picked.name.contains('.')
            ? picked.name.substring(0, picked.name.lastIndexOf('.'))
            : picked.name,
        extension: ext,
        sizeBytes: picked.size,
        uploadedAt: DateTime.now(),
        uploadedBy: 'You',
      );

      setState(() {
        _room = _room.copyWith(files: [newFile, ..._room.files]);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${picked.name} uploaded!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Upload failed: ${response['error'] ?? 'Unknown error'}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _RoomAppBar(
              room: _room,
              onBack: () => Navigator.of(context).pop(),
              onCopyCode: _copyRoomCode,
            ),
            Expanded(
              child: _room.files.isEmpty
                  ? _EmptyState(onUpload: _handleUpload)
                  : _FileList(files: _room.files),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut),
        child: _UploadFAB(
          onTap: _handleUpload,
          isUploading: _isUploading,
        ),
      ),
    );
  }
}

// ── App Bar ────────────────────────────────────────────────

class _RoomAppBar extends StatelessWidget {
  final Room room;
  final VoidCallback onBack;
  final VoidCallback onCopyCode;

  const _RoomAppBar({
    required this.room,
    required this.onBack,
    required this.onCopyCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceBorder.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  room.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              if (room.isOwner)
                const AppBadge(
                  label: 'Owner',
                  color: AppColors.primarySurface,
                  textColor: AppColors.primaryLight,
                )
              else
                const AppBadge(
                  label: 'Guest',
                  color: AppColors.accentSurface,
                  textColor: AppColors.accentLight,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _CodePill(code: room.code, onCopy: onCopyCode),
              const Spacer(),
              _MemberStack(members: room.members),
            ],
          ),
        ],
      ),
    );
  }
}

class _CodePill extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;

  const _CodePill({required this.code, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCopy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.copy_rounded,
                color: AppColors.textTertiary, size: 13),
          ],
        ),
      ),
    );
  }
}

class _MemberStack extends StatelessWidget {
  final List<RoomMember> members;

  const _MemberStack({required this.members});

  static const _avatarColors = [
    AppColors.primarySurface,
    AppColors.accentSurface,
  ];

  @override
  Widget build(BuildContext context) {
    final shown = members.take(3).toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: shown.length * 28.0 + 12,
          height: 34,
          child: Stack(
            children: [
              for (int i = 0; i < shown.length; i++)
                Positioned(
                  left: i * 22.0,
                  child: MemberAvatar(
                    initials: shown[i].initials,
                    isOnline: shown[i].isOnline,
                    size: 32,
                    color: _avatarColors[i % _avatarColors.length],
                  ),
                ),
            ],
          ),
        ),
        Text(
          '${members.length} member${members.length == 1 ? '' : 's'}',
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── File List ──────────────────────────────────────────────

class _FileList extends StatelessWidget {
  final List<SharedFile> files;

  const _FileList({required this.files});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Shared files',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        ...files.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FileCard(file: f),
            )),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _FileCard extends StatelessWidget {
  final SharedFile file;

  const _FileCard({required this.file});

  static const _extColors = {
    'pdf': (AppColors.error, AppColors.errorSurface),
    'png': (Color(0xFF3ECFCF), AppColors.accentSurface),
    'jpg': (Color(0xFF3ECFCF), AppColors.accentSurface),
    'jpeg': (Color(0xFF3ECFCF), AppColors.accentSurface),
    'xlsx': (AppColors.success, Color(0xFF0F2A18)),
    'xls': (AppColors.success, Color(0xFF0F2A18)),
    'csv': (AppColors.success, Color(0xFF0F2A18)),
    'doc': (AppColors.primary, AppColors.primarySurface),
    'docx': (AppColors.primary, AppColors.primarySurface),
    'zip': (Color(0xFFFFB347), Color(0xFF2A1E0A)),
  };

  @override
  Widget build(BuildContext context) {
    final colors = _extColors[file.extension.toLowerCase()] ??
        (AppColors.textSecondary, AppColors.surface);
    final iconColor = colors.$1;
    final iconBg = colors.$2;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => HapticFeedback.selectionClick(),
        borderRadius: BorderRadius.circular(16),
        child: AppCard(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: iconColor.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    file.fileIcon,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${file.name}.${file.extension}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${file.formattedSize} · by ${file.uploadedBy} · ${_relativeTime(file.uploadedAt)}',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.download_rounded,
                    color: AppColors.textTertiary, size: 20),
                onPressed: () => HapticFeedback.lightImpact(),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Empty State ────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onUpload;

  const _EmptyState({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: const Icon(Icons.upload_file_rounded,
                  color: AppColors.textTertiary, size: 30),
            ),
            const SizedBox(height: 20),
            const Text(
              'No files yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload the first file to this room\nand share it with everyone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Upload a file',
              onTap: onUpload,
              width: 180,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Upload FAB ─────────────────────────────────────────────

class _UploadFAB extends StatelessWidget {
  final VoidCallback onTap;
  final bool isUploading;

  const _UploadFAB({required this.onTap, required this.isUploading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.accent],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: isUploading
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}