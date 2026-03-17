import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import './../models/room.dart';
import '../widgets/shared_widgets.dart';
import '../services/api.dart';
import 'room_screen.dart';

class HomeScreen extends StatefulWidget {
  // FIX: added userId — login.dart now passes the authenticated user's id so
  // that room creation can send the correct owner_id to the backend.
  final int userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // ── Animation ─────────────────────────────────────────────
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // ── State ─────────────────────────────────────────────────
  _PanelMode _activePanel = _PanelMode.none;
  Room? _createdRoom;
  bool _isCreating = false; // FIX: tracks in-flight createRoom API call

  // Create panel
  final _roomNameController = TextEditingController(text: 'My Room');

  // Join panel
  final _joinCodeController = TextEditingController();
  final _joinFocusNode = FocusNode();
  String _joinError = '';
  bool _isJoining = false;

  // ── Lifecycle ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _roomNameController.dispose();
    _joinCodeController.dispose();
    _joinFocusNode.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────
  void _handleCreateTap() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_activePanel == _PanelMode.create) {
        _activePanel = _PanelMode.none;
      } else {
        _activePanel = _PanelMode.create;
        _createdRoom = null;
      }
    });
  }

  void _handleJoinTap() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_activePanel == _PanelMode.join) {
        _activePanel = _PanelMode.none;
      } else {
        _activePanel = _PanelMode.join;
        _joinCodeController.clear();
        _joinError = '';
      }
    });
    // Auto-focus the input after the expansion animation
    if (_activePanel == _PanelMode.join) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _joinFocusNode.requestFocus();
      });
    }
  }

  // FIX: was synchronous and created a Room with a locally-generated code that
  // was never persisted to the backend. Now calls createRoom() so the code is
  // registered server-side and other users can actually join it.
  Future<void> _generateRoom() async {
    HapticFeedback.mediumImpact();
    final name = _roomNameController.text.trim().isEmpty
        ? 'My Room'
        : _roomNameController.text.trim();

    setState(() => _isCreating = true);

    final data = await createRoom(name, widget.userId);

    if (!mounted) return;
    setState(() => _isCreating = false);

    if (data['success'] == true) {
      setState(() {
        _createdRoom = Room(
          code: data['code'] as String,
          name: name,
          isOwner: true,
          createdAt: DateTime.now(),
          members: [
            const RoomMember(
              id: 'me',
              name: 'You',
              initials: 'ME',
              isOnline: true,
              isOwner: true,
            ),
          ],
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${data['error'] ?? 'Failed to create room'}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _copyCode() {
    if (_createdRoom == null) return;
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: _createdRoom!.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              '${_createdRoom!.code} copied to clipboard',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openCreatedRoom() {
    if (_createdRoom == null) return;
    _navigateToRoom(_createdRoom!);
  }

  // FIX: was using a hardcoded Future.delayed and creating a fake Room object —
  // the backend was never consulted, so invalid codes always "succeeded" and
  // the room name was always the generic "Room XXXXXX".
  // Now calls joinFile() and maps the server response to a proper Room model.
  Future<void> _joinRoom() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.length != 6) {
      HapticFeedback.heavyImpact();
      setState(() => _joinError = 'Please enter a valid 6-character code');
      return;
    }

    setState(() {
      _joinError  = '';
      _isJoining  = true;
    });

    final data = await joinFile(code);

    if (!mounted) return;
    setState(() => _isJoining = false);

    if (data['success'] == true) {
      final room = Room(
        code: code,
        // Use the room title stored on the server if available
        name: (data['title'] as String?)?.isNotEmpty == true
            ? data['title'] as String
            : 'Room $code',
        isOwner: false,
        createdAt: DateTime.now(),
        members: [
          const RoomMember(
            id: 'host',
            name: 'Host',
            initials: 'HO',
            isOnline: true,
            isOwner: true,
          ),
          const RoomMember(
            id: 'me',
            name: 'You',
            initials: 'ME',
            isOnline: true,
          ),
        ],
      );
      _navigateToRoom(room);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _joinError = data['error'] as String? ??
            'Room not found — check the code and try again';
      });
    }
  }

  void _navigateToRoom(Room room) {
    _joinFocusNode.unfocus();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => RoomScreen(room: room),
        transitionsBuilder: (_, anim, __, child) {
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 56),
                    _AppLogo(),
                    const SizedBox(height: 36),
                    _HeroText(),
                    const SizedBox(height: 48),
                    _CreatePanel(
                      isExpanded: _activePanel == _PanelMode.create,
                      createdRoom: _createdRoom,
                      roomNameController: _roomNameController,
                      onToggle: _handleCreateTap,
                      onGenerate: _generateRoom,
                      onCopy: _copyCode,
                      onOpen: _openCreatedRoom,
                      isCreating: _isCreating,
                    ),
                    const SizedBox(height: 12),
                    _OrDivider(),
                    const SizedBox(height: 12),
                    _JoinPanel(
                      isExpanded: _activePanel == _PanelMode.join,
                      codeController: _joinCodeController,
                      focusNode: _joinFocusNode,
                      error: _joinError,
                      isLoading: _isJoining,
                      onToggle: _handleJoinTap,
                      onJoin: _joinRoom,
                      onCodeChanged: (_) {
                        if (_joinError.isNotEmpty) {
                          setState(() => _joinError = '');
                        }
                      },
                    ),
                    const SizedBox(height: 40),
                    const _Footer(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Panel mode enum ────────────────────────────────────────
enum _PanelMode { none, create, join }

// ═══════════════════════════════════════════════════════════
// Sub-widgets (extracted for clarity and reuse)
// ═══════════════════════════════════════════════════════════

class _AppLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.accent],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.folder_shared_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        const Text(
          'SharedRoom',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        const AppBadge(label: 'Beta'),
      ],
    );
  }
}

class _HeroText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Share files\ninstantly.',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 38,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Create a private room or join one with a code.\nFiles stay end-to-end encrypted.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Divider(
                color: AppColors.surfaceBorder.withValues(alpha: 0.8),
                height: 1)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
            child: Divider(
                color: AppColors.surfaceBorder.withValues(alpha: 0.8),
                height: 1)),
      ],
    );
  }
}

// ── Create Panel ───────────────────────────────────────────

class _CreatePanel extends StatelessWidget {
  final bool isExpanded;
  final Room? createdRoom;
  final TextEditingController roomNameController;
  final VoidCallback onToggle;
  final Future<void> Function() onGenerate; // FIX: was VoidCallback, now async
  final VoidCallback onCopy;
  final VoidCallback onOpen;
  final bool isCreating; // FIX: needed to disable button while API is in-flight

  const _CreatePanel({
    required this.isExpanded,
    required this.createdRoom,
    required this.roomNameController,
    required this.onToggle,
    required this.onGenerate,
    required this.onCopy,
    required this.onOpen,
    required this.isCreating,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isExpanded ? AppColors.primarySurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded
              ? AppColors.primaryBorder
              : AppColors.surfaceBorder,
          width: isExpanded ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelHeader(
              icon: Icons.add_rounded,
              accentColor: AppColors.primary,
              title: 'Create a room',
              subtitle: 'Get a shareable 6-character code',
              isExpanded: isExpanded,
              onTap: onToggle,
              actionLabel: 'Create',
              actionStyle: _ActionStyle.filled,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              child: isExpanded
                  ? _CreatePanelBody(
                      createdRoom: createdRoom,
                      roomNameController: roomNameController,
                      onGenerate: onGenerate,
                      onCopy: onCopy,
                      onOpen: onOpen,
                      isCreating: isCreating,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePanelBody extends StatelessWidget {
  final Room? createdRoom;
  final TextEditingController roomNameController;
  final Future<void> Function() onGenerate; // FIX: async
  final VoidCallback onCopy;
  final VoidCallback onOpen;
  final bool isCreating; // FIX: drives the loading state on the button

  const _CreatePanelBody({
    required this.createdRoom,
    required this.roomNameController,
    required this.onGenerate,
    required this.onCopy,
    required this.onOpen,
    required this.isCreating,
  });

  @override
  Widget build(BuildContext context) {
    if (createdRoom == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Room name (optional)',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: roomNameController,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'e.g. Project Files, Trip Photos…',
              hintStyle: TextStyle(color: AppColors.textTertiary),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Generate code',
            onTap: onGenerate,
            isLoading: isCreating,
          ),
        ],
      );
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryBorder),
          ),
          child: Column(
            children: [
              const Text(
                'ROOM CODE',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: createdRoom!.code
                    .split('')
                    .map((c) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: CodeCell(
                              char: c, accentColor: AppColors.primary),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 14),
              const Text(
                'Share this code with your collaborators',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Copy code',
                icon: Icons.copy_rounded,
                onTap: onCopy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                label: 'Open room',
                onTap: onOpen,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Join Panel ─────────────────────────────────────────────

class _JoinPanel extends StatelessWidget {
  final bool isExpanded;
  final TextEditingController codeController;
  final FocusNode focusNode;
  final String error;
  final bool isLoading;
  final VoidCallback onToggle;
  final VoidCallback onJoin;
  final ValueChanged<String> onCodeChanged;

  const _JoinPanel({
    required this.isExpanded,
    required this.codeController,
    required this.focusNode,
    required this.error,
    required this.isLoading,
    required this.onToggle,
    required this.onJoin,
    required this.onCodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded
              ? AppColors.accentBorder
              : AppColors.surfaceBorder,
          width: isExpanded ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelHeader(
              icon: Icons.login_rounded,
              accentColor: AppColors.accent,
              title: 'Join a room',
              subtitle: 'Enter a 6-character code',
              isExpanded: isExpanded,
              onTap: onToggle,
              actionLabel: 'Join',
              actionStyle: _ActionStyle.outlined,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              child: isExpanded
                  ? _JoinPanelBody(
                      codeController: codeController,
                      focusNode: focusNode,
                      error: error,
                      isLoading: isLoading,
                      onJoin: onJoin,
                      onCodeChanged: onCodeChanged,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinPanelBody extends StatelessWidget {
  final TextEditingController codeController;
  final FocusNode focusNode;
  final String error;
  final bool isLoading;
  final VoidCallback onJoin;
  final ValueChanged<String> onCodeChanged;

  const _JoinPanelBody({
    required this.codeController,
    required this.focusNode,
    required this.error,
    required this.isLoading,
    required this.onJoin,
    required this.onCodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        TextField(
          controller: codeController,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 10,
          ),
          inputFormatters: [
            LengthLimitingTextInputFormatter(6),
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
          ],
          decoration: InputDecoration(
            hintText: '· · · · · ·',
            hintStyle: const TextStyle(
              color: AppColors.textTertiary,
              letterSpacing: 8,
              fontSize: 20,
            ),
            errorText: error.isEmpty ? null : error,
            errorStyle:
                const TextStyle(color: AppColors.error, fontSize: 12),
            suffixIcon: codeController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textTertiary, size: 18),
                    onPressed: () {
                      codeController.clear();
                      onCodeChanged('');
                    },
                  )
                : null,
          ),
          onChanged: onCodeChanged,
          onSubmitted: (_) => onJoin(),
        ),
        if (error.isEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Codes are case-insensitive',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Join room',
          onTap: onJoin,
          isLoading: isLoading,
          gradient: const [AppColors.accent, Color(0xFF22A8A0)],
        ),
      ],
    );
  }
}

// ── Panel Header (shared between create & join) ────────────

enum _ActionStyle { filled, outlined }

class _PanelHeader extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final bool isExpanded;
  final VoidCallback onTap;
  final String actionLabel;
  final _ActionStyle actionStyle;

  const _PanelHeader({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.onTap,
    required this.actionLabel,
    required this.actionStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        AnimatedRotation(
          duration: const Duration(milliseconds: 250),
          turns: isExpanded ? 0.5 : 0,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: actionStyle == _ActionStyle.filled && !isExpanded
                    ? LinearGradient(
                        colors: [accentColor, accentColor.withValues(alpha: 0.7)])
                    : null,
                border: actionStyle == _ActionStyle.outlined || isExpanded
                    ? Border.all(color: accentColor.withValues(alpha: 0.5))
                    : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isExpanded ? '↑' : actionLabel,
                style: TextStyle(
                  color: isExpanded
                      ? AppColors.textSecondary
                      : (actionStyle == _ActionStyle.filled
                          ? Colors.white
                          : accentColor),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Footer ─────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded,
              color: AppColors.textTertiary, size: 12),
          const SizedBox(width: 6),
          const Text(
            'End-to-end encrypted · Files auto-expire in 24h',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}