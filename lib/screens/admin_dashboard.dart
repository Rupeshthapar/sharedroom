// screens/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/api.dart';
import 'login.dart';

class AdminDashboardScreen extends StatefulWidget {
  final int userId;
  final String email;

  const AdminDashboardScreen({
    super.key,
    required this.userId,
    required this.email,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _error;

  // Summary stats fetched from the backend
  int _totalUsers = 0;
  int _totalRooms = 0;
  int _totalFiles = 0;

  // Full user list
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error     = null;
    });

    final data = await fetchAdminStats(widget.userId);

    if (!mounted) return;

    if (data['success'] == true) {
      setState(() {
        _isLoading  = false;
        _totalUsers = (data['total_users'] as num?)?.toInt() ?? 0;
        _totalRooms = (data['total_rooms'] as num?)?.toInt() ?? 0;
        _totalFiles = (data['total_files'] as num?)?.toInt() ?? 0;
        _users      = List<Map<String, dynamic>>.from(data['users'] ?? []);
      });
    } else {
      setState(() {
        _isLoading = false;
        _error     = data['error']?.toString() ?? 'Failed to load admin data';
      });
    }
  }

  void _logout() {
    HapticFeedback.mediumImpact();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceBorder.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  widget.email,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const AppBadge(
            label: 'Admin',
            color: AppColors.primarySurface,
            textColor: AppColors.primaryLight,
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.textSecondary, size: 20),
            tooltip: 'Log out',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ── Error state ──────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 40),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Retry', onTap: _loadStats, width: 140),
          ],
        ),
      ),
    );
  }

  // ── Main body ────────────────────────────────────────────

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildStatsRow(),
          const SizedBox(height: 28),
          const Text(
            'All users',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          ..._users.map(_buildUserCard),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Stat cards ───────────────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Users',  value: _totalUsers, icon: Icons.people_rounded,     color: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Rooms',  value: _totalRooms, icon: Icons.folder_shared_rounded, color: AppColors.accent)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Files',  value: _totalFiles, icon: Icons.insert_drive_file_rounded, color: AppColors.success)),
      ],
    );
  }

  // ── User row ─────────────────────────────────────────────

  Widget _buildUserCard(Map<String, dynamic> user) {
    final email   = user['username']?.toString() ?? '—';
    final isAdmin = user['is_admin'] == true || user['is_admin'] == 1;
    final id      = user['id']?.toString() ?? '?';
    final initials = email.length >= 2
        ? email.substring(0, 2).toUpperCase()
        : email.toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            MemberAvatar(initials: initials, size: 38),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ID: $id',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isAdmin)
              const AppBadge(
                label: 'Admin',
                color: AppColors.primarySurface,
                textColor: AppColors.primaryLight,
              )
            else
              const AppBadge(
                label: 'User',
                color: AppColors.accentSurface,
                textColor: AppColors.accentLight,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Stat card widget ──────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}