import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/database_service.dart';
import '../../utils/image_helper.dart';
import '../../utils/theme.dart';
import '../../utils/translations.dart';

class ProfileScreen extends StatefulWidget {
  final String currentLang;

  const ProfileScreen({Key? key, required this.currentLang}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  late TextEditingController _passwordController;
  late String _currentAvatar;

  // Preset Avatar Gallery for instant selection
  final List<String> _avatarGallery = [
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
    'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=200',
    'https://images.unsplash.com/photo-1628157582853-a796fa650a6a?w=200',
    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=200',
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
    'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200',
  ];

  String t(String key) => AppTranslations.get(key, widget.currentLang);

  @override
  void initState() {
    super.initState();
    final user = DatabaseService().currentUser;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _dobController = TextEditingController(text: user?.dateOfBirth ?? '');
    _passwordController = TextEditingController();
    _currentAvatar = user?.avatar ?? _avatarGallery.first;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openAvatarPickerSheet() {
    final customUrlController = TextEditingController(text: _currentAvatar);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0E1A1B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: isDark ? const Color(0xFF1B3234) : const Color(0xFFD1FAE5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t('avatarPickerTitle'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppTheme.darkTextMain : AppTheme.lightTextMain,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  t('avatarPickerSub'),
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSub : AppTheme.lightTextSub),
                ),
                const SizedBox(height: 14),

                // Primary Gallery & Camera action buttons
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          try {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(source: ImageSource.gallery);
                            if (picked != null) {
                              final bytes = await picked.readAsBytes();
                              final base64String = base64Encode(bytes);
                              setState(() => _currentAvatar = 'data:image/jpeg;base64,$base64String');
                              Navigator.pop(ctx);
                            }
                          } catch (e) {
                            debugPrint("Avatar gallery error: $e");
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.neonGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.neonGreen, width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.photo_library_rounded, color: AppTheme.neonGreen, size: 20),
                              const SizedBox(width: 8),
                              Text(t('galleryPick'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.neonGreen)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          try {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(source: ImageSource.camera);
                            if (picked != null) {
                              final bytes = await picked.readAsBytes();
                              final base64String = base64Encode(bytes);
                              setState(() => _currentAvatar = 'data:image/jpeg;base64,$base64String');
                              Navigator.pop(ctx);
                            }
                          } catch (e) {
                            debugPrint("Avatar camera error: $e");
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF06B6D4), width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt_rounded, color: Color(0xFF06B6D4), size: 20),
                              const SizedBox(width: 8),
                              Text(t('cameraPick'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF06B6D4))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(t('avatarPresets'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
                const SizedBox(height: 8),

                // Avatar Grid (Presets)
                SizedBox(
                  height: 120,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _avatarGallery.length,
                    itemBuilder: (context, index) {
                      final url = _avatarGallery[index];
                      final isSelected = _currentAvatar == url;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _currentAvatar = url);
                          setModalState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppTheme.neonGreen : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.neonGreen.withOpacity(0.4),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(url),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Custom Image URL input
                TextField(
                  controller: customUrlController,
                  decoration: InputDecoration(
                    labelText: t('customAvatarUrl'),
                    hintText: "https://...",
                    prefixIcon: const Icon(Icons.link_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: AppTheme.neonGreen),
                      onPressed: () {
                        if (customUrlController.text.trim().isNotEmpty) {
                          setState(() => _currentAvatar = customUrlController.text.trim());
                          Navigator.pop(ctx);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonGreen,
                      foregroundColor: const Color(0xFF042F2E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(t('confirm'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    final db = DatabaseService();
    final user = db.currentUser;
    if (user == null) return;

    user.fullName = _fullNameController.text.trim();
    user.username = _usernameController.text.trim();
    user.phone = _phoneController.text.trim();
    user.email = _emailController.text.trim();
    user.dateOfBirth = _dobController.text.trim();
    user.avatar = _currentAvatar;

    if (_passwordController.text.isNotEmpty) {
      user.password = _passwordController.text;
    }

    db.updateProfile(user);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t('profileUpdated')),
        backgroundColor: AppTheme.neonGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final db = DatabaseService();
    final user = db.currentUser;
    final debts = db.debts;

    final bgGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF071110), Color(0xFF091717), Color(0xFF050D0E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFFF0FDF4), Color(0xFFE6F9F0), Color(0xFFDCFCE7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    final cardBg = isDark ? const Color(0xFF0E1A1B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1B3234) : const Color(0xFFD1FAE5);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF064E3B);
    final textSecondary = isDark ? const Color(0xFF7B9CA0) : const Color(0xFF059669);

    final activeDebtsCount = debts.where((d) => d.status == 'active').length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Center(
                          child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textPrimary),
                        ),
                      ),
                    ),
                    Text(
                      t('profile'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_rounded, color: AppTheme.neonGreen),
                      onPressed: _saveProfile,
                    ),
                  ],
                ),
              ),

              // Smooth Scrollable Content (Fixes scroll issue)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 24.0 + MediaQuery.of(context).padding.bottom),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Creative Hero Avatar Card
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black.withOpacity(0.4) : AppTheme.neonGreen.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [AppTheme.neonGreen, Color(0xFF047857)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.neonGreen.withOpacity(0.4),
                                          blurRadius: 14,
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 46,
                                      backgroundColor: isDark ? const Color(0xFF132324) : Colors.white,
                                      backgroundImage: SmartImageHelper.getProvider(_currentAvatar),
                                      child: _currentAvatar.isEmpty
                                          ? const Icon(Icons.person, size: 40, color: AppTheme.neonGreen)
                                          : null,
                                    ),
                                  ),
                                  // Camera / Gallery edit button
                                  GestureDetector(
                                    onTap: _openAvatarPickerSheet,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.neonGreen,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF042F2E), size: 18),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                user?.fullName ?? "User",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "@${user?.username ?? 'user'}",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                              ),
                              const SizedBox(height: 16),

                              // Quick Stats Row inside Avatar Card (Fixed concise labels and beautiful layout)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF132324) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    _buildStatItem("Qarzlar", "${debts.length} ta", isDark, textPrimary, textSecondary),
                                    Container(width: 1, height: 28, color: cardBorder),
                                    _buildStatItem(t('active'), "$activeDebtsCount ta", isDark, textPrimary, textSecondary),
                                    Container(width: 1, height: 28, color: cardBorder),
                                    _buildStatItem("Tarif", "Pro VIP", isDark, AppTheme.neonGreen, textSecondary),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 2. Personal Information Fields Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('profile'),
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _fullNameController,
                                validator: (v) => (v == null || v.trim().isEmpty) ? t('fillRequiredFields') : null,
                                decoration: InputDecoration(
                                  labelText: t('fullName'),
                                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.neonGreen),
                                ),
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _usernameController,
                                validator: (v) => (v == null || v.trim().isEmpty) ? t('fillRequiredFields') : null,
                                decoration: InputDecoration(
                                  labelText: t('username'),
                                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppTheme.neonGreen),
                                ),
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: t('phone'),
                                  prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.neonGreen),
                                ),
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: t('email'),
                                  prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppTheme.neonGreen),
                                ),
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _dobController,
                                decoration: InputDecoration(
                                  labelText: t('dob'),
                                  prefixIcon: const Icon(Icons.cake_outlined, color: AppTheme.neonGreen),
                                  hintText: "YYYY-MM-DD",
                                ),
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: t('changePassword'),
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.neonGreen),
                                  hintText: t('newPasswordHint'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 3. Action Buttons (Save & Logout)
                        ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonGreen,
                            foregroundColor: const Color(0xFF042F2E),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          child: Text(t('save'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                        const SizedBox(height: 12),

                        OutlinedButton.icon(
                          onPressed: () {
                            db.logout();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 20),
                          label: Text(t('logout'), style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w800)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.danger, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, bool isDark, Color textPrimary, Color textSecondary) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
