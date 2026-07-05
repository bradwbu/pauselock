import 'package:flutter/material.dart';
import 'package:pauselock_app/src/services/auth_service.dart';
import 'package:pauselock_app/src/services/local_storage_service.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';

class AnnouncementBanner extends StatefulWidget {
  const AnnouncementBanner({super.key});

  @override
  State<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<AnnouncementBanner> {
  List<dynamic> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final announcements = await AuthService.getAnnouncements();
      final dismissed = LocalStorageService.getDismissedAnnouncements();
      if (mounted) {
        setState(() {
          _announcements = announcements
              .where((a) => !dismissed.contains(a['id']))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _dismiss(int id) async {
    await LocalStorageService.dismissAnnouncement(id);
    setState(() {
      _announcements = _announcements.where((a) => a['id'] != id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _announcements.isEmpty) return const SizedBox.shrink();

    return Column(
      children: _announcements.map((a) => _buildBanner(a)).toList(),
    );
  }

  Widget _buildBanner(Map<String, dynamic> announcement) {
    final type = announcement['type'] ?? 'info';
    final message = announcement['message'] ?? '';
    final id = announcement['id'] ?? 0;

    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    IconData icon;

    switch (type) {
      case 'warning':
        backgroundColor = const Color(0xFF2A1F00);
        borderColor = AppTheme.warningColor.withValues(alpha: 0.3);
        iconColor = AppTheme.warningColor;
        icon = Icons.warning_amber_rounded;
        break;
      case 'error':
        backgroundColor = const Color(0xFF2A0000);
        borderColor = AppTheme.errorColor.withValues(alpha: 0.3);
        iconColor = AppTheme.errorColor;
        icon = Icons.error_outline_rounded;
        break;
      case 'success':
        backgroundColor = const Color(0xFF002A1A);
        borderColor = AppTheme.successColor.withValues(alpha: 0.3);
        iconColor = AppTheme.successColor;
        icon = Icons.check_circle_outline_rounded;
        break;
      default:
        backgroundColor = const Color(0xFF0A1A30);
        borderColor = AppTheme.accentColor.withValues(alpha: 0.3);
        iconColor = AppTheme.accentColor;
        icon = Icons.info_outline_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _dismiss(id),
            child: Icon(
              Icons.close_rounded,
              color: Colors.white.withValues(alpha: 0.4),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
