import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pauselock_app/src/theme/app_theme.dart';
import 'package:pauselock_app/src/services/auth_service.dart';
import 'package:pauselock_app/src/services/pauselock_client.dart';
import 'package:pauselock_app/src/utils/formatters.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _isLoading = false;
  String? _success;
  String? _error;

  // Profile controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _profileDirty = false;

  // Password controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Steam linking
  bool _isLinkingSteam = false;
  List<dynamic> _steamSearchResults = [];
  String? _steamError;
  Map<String, dynamic>? _steamPlayerData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    final user = AuthService.currentUser;
    if (user == null) return;
    _firstNameController.text = user['firstName'] ?? '';
    _lastNameController.text = user['lastName'] ?? '';
    _usernameController.text = user['username'] ?? '';
    _emailController.text = user['email'] ?? '';
    _profileDirty = false;

    final steamId = user['steamAccountId'];
    if (steamId != null) {
      _loadSteamData(steamId);
    }
  }

  Future<void> _loadSteamData(int steamAccountId) async {
    try {
      final stats = await PauselockClient.getPlayerStats(steamAccountId);
      if (mounted && stats != null) {
        setState(() => _steamPlayerData = stats);
      }
    } catch (_) {}
  }

  void _onProfileChanged() {
    if (!_profileDirty) {
      setState(() => _profileDirty = true);
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      final result = await AuthService.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (result['error'] != null) {
        setState(() {
          _error = result['error'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _success = 'Profile updated successfully';
          _isLoading = false;
          _profileDirty = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to update profile';
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'New passwords do not match');
      return;
    }
    if (_newPasswordController.text.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      final result = await AuthService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (result['error'] != null) {
        setState(() {
          _error = result['error'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _success = 'Password changed successfully';
          _isLoading = false;
        });
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to change password';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchSteamPlayers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _steamSearchResults = []);
      return;
    }

    final numericId = int.tryParse(query.trim());
    if (numericId != null) {
      setState(() {
        _steamSearchResults = [
          {'accountId': numericId, 'playerName': 'Steam ID: $numericId'}
        ];
      });
      return;
    }

    try {
      final results = await PauselockClient.searchPlayers(query.trim());
      setState(() => _steamSearchResults = results ?? []);
    } catch (e) {
      setState(() => _steamError = 'Search failed');
    }
  }

  Future<void> _linkSteam(int steamAccountId) async {
    setState(() {
      _isLoading = true;
      _steamError = null;
    });

    try {
      final result = await AuthService.linkSteam(steamAccountId);
      if (result['error'] != null) {
        setState(() {
          _steamError = result['error'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _success = 'Steam account linked successfully';
          _isLoading = false;
          _isLinkingSteam = false;
          _steamSearchResults = [];
        });
        _loadSteamData(steamAccountId);
      }
    } catch (e) {
      setState(() {
        _steamError = 'Failed to link Steam account';
        _isLoading = false;
      });
    }
  }

  Future<void> _unlinkSteam() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Unlink Steam Account'),
        content: const Text(
            'Are you sure you want to unlink your Steam account? Your stats will no longer be shown on your profile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.unlinkSteam();
      if (result['error'] != null) {
        setState(() {
          _error = result['error'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _success = 'Steam account unlinked';
          _isLoading = false;
          _steamPlayerData = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to unlink Steam account';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    if (user == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
          child: Center(
            child: ElevatedButton.icon(
              onPressed: () => context.go('/auth'),
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
            ),
          ),
        ),
      );
    }

    final steamId = user['steamAccountId'];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/profile'),
                ),
                title: ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.primaryGradient.createShader(bounds),
                  child: const Text('ACCOUNT SETTINGS',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_success != null) _buildSuccessBanner(),
                      if (_error != null) _buildErrorBanner(),
                      _buildProfileSection(),
                      const SizedBox(height: 24),
                      _buildPasswordSection(),
                      const SizedBox(height: 24),
                      _buildSteamSection(steamId),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(_success!,
                  style: const TextStyle(color: Colors.green, fontSize: 13))),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => setState(() => _success = null),
            color: Colors.green,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(_error!,
                  style: const TextStyle(
                      color: AppTheme.errorColor, fontSize: 13))),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => setState(() => _error = null),
            color: AppTheme.errorColor,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return _buildSection(
      title: 'PROFILE INFORMATION',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person_outline,
                  onChanged: (_) => _onProfileChanged(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline,
                  onChanged: (_) => _onProfileChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.alternate_email,
            onChanged: (_) => _onProfileChanged(),
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _onProfileChanged(),
          ),
          const SizedBox(height: 16),
          if (_profileDirty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveProfile,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 18),
                label: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return _buildSection(
      title: 'CHANGE PASSWORD',
      child: Column(
        children: [
          _buildField(
            controller: _currentPasswordController,
            label: 'Current Password',
            icon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _newPasswordController,
            label: 'New Password',
            icon: Icons.lock,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _confirmPasswordController,
            label: 'Confirm New Password',
            icon: Icons.lock,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _changePassword,
              icon: const Icon(Icons.vpn_key, size: 18),
              label: const Text('Change Password'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppTheme.surfaceColorLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSteamSection(int? steamId) {
    return _buildSection(
      title: 'STEAM ACCOUNT',
      child: Column(
        children: [
          if (steamId != null) ...[
            _buildLinkedSteamCard(steamId),
          ] else if (_isLinkingSteam) ...[
            _buildSteamLinkingForm(),
          ] else ...[
            _buildSteamLinkPrompt(),
          ],
        ],
      ),
    );
  }

  Widget _buildLinkedSteamCard(int steamId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecorationSmall,
      child: Column(
        children: [
          if (_steamPlayerData != null) ...[
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _steamPlayerData!['avatarUrl'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            _steamPlayerData!['avatarUrl'],
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _steamPlayerData!['playerName'] ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        'Steam ID: $steamId',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formatRank(_steamPlayerData!['rank'] ?? 0),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatChip(
                    '${_steamPlayerData!['totalMatches'] ?? 0} matches',
                    AppTheme.accentColor),
                const SizedBox(width: 8),
                _buildStatChip(
                    '${(_steamPlayerData!['winRate'] ?? 0).toStringAsFixed(1)}% win rate',
                    Colors.green),
                const SizedBox(width: 8),
                _buildStatChip(
                    formatRank(_steamPlayerData!['rank'] ?? 0),
                    AppTheme.primaryColor),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(Icons.sports_esports, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Steam Account Linked',
                          style: Theme.of(context).textTheme.titleSmall),
                      Text('ID: $steamId',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _unlinkSteam,
              icon: const Icon(Icons.link_off, size: 16),
              label: const Text('Unlink Steam Account'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                side: BorderSide(
                    color: AppTheme.errorColor.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSteamLinkPrompt() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecorationSmall,
      child: Column(
        children: [
          Icon(Icons.sports_esports,
              color: AppTheme.primaryColor.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 12),
          Text('Link your Steam account',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Connect your Steam account to display your Deadlock stats on your profile and sync data across Pauselock.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _isLinkingSteam = true),
              icon: const Icon(Icons.link, size: 18),
              label: const Text('Link Steam Account'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSteamLinkingForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecorationSmall,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_esports, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text('Link Steam Account',
                  style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() {
                  _isLinkingSteam = false;
                  _steamSearchResults = [];
                  _steamError = null;
                }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search by player name or enter Steam ID...',
              prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
            ),
            style: const TextStyle(color: AppTheme.textPrimary),
            onChanged: _searchSteamPlayers,
            onSubmitted: (value) {
              final id = int.tryParse(value.trim());
              if (id != null) _linkSteam(id);
            },
          ),
          if (_steamError != null) ...[
            const SizedBox(height: 8),
            Text(_steamError!,
                style:
                    const TextStyle(color: AppTheme.errorColor, fontSize: 12)),
          ],
          if (_steamSearchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _steamSearchResults.length,
                itemBuilder: (context, index) {
                  final player = _steamSearchResults[index];
                  return ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          AppTheme.primaryColor.withValues(alpha: 0.2),
                      child: const Icon(Icons.person,
                          size: 16, color: AppTheme.primaryColor),
                    ),
                    title: Text(player['playerName'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 13)),
                    subtitle: Text(
                        'ID: ${player['accountId']}',
                        style: const TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.link, size: 16),
                    onTap: () => _linkSteam(player['accountId']),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.glassDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  )),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        filled: true,
        fillColor: AppTheme.surfaceColorLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: onChanged,
    );
  }
}
