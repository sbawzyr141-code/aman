import 'package:flutter/material.dart' hide Text;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_language.dart';

import 'home_screen.dart';
import 'check_phone_screen.dart';
import 'device_registry_screen.dart';
import 'profile_screen.dart';
import 'report_theft_screen.dart';
import 'admin_control_panel_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 5;
  bool _isAdmin = false;
  bool _isNormalUser = false;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocument;
  int get _selectedIndex => _isNormalUser
      ? (_currentIndex == 5
            ? 0
            : _currentIndex < 0
            ? 0
            : _currentIndex > 2
            ? 2
            : _currentIndex)
      : (!_isAdmin && _currentIndex == 5 ? 2 : _currentIndex);

  static const Color primary = Color(0xFF315F73);
  static const Color secondary = Color(0xFF527F90);
  static const Color lightBlue = Color(0xFFE8F1F4);
  static const Color background = Color(0xFFF8FAFB);
  static const Color textDark = Color(0xFF243943);
  static const Color textGrey = Color(0xFF87969D);
  static const Color borderColor = Color(0xFFE8EEF0);

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userDocument = user == null
        ? Stream.error(StateError('No signed-in user is available.'))
        : FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots();
  }

  void _navigateToTab(int index) {
    if (_isNormalUser && (index < 0 || index > 2)) return;
    if (index == 5 && !_isAdmin) return;
    setState(() {
      _currentIndex = index;
    });
  }

  static const List<String> _titles = [
    'الملف الشخصي',
    'التنبيهات والبلاغات',
    'الرئيسية',
    'فحص الهاتف',
    'سجل الأجهزة',
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userDocument,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'تعذر تحميل صلاحيات الحساب: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final userData = snapshot.data!.data();
        _isAdmin = AdminControlPanelScreen.isAdmin(user, userData);
        _isNormalUser = !_isAdmin && userData?['role'] == 'user';
        final List<Widget> pages;
        final List<String> titles;
        if (_isNormalUser) {
          pages = const [
            ReportTheftScreen(),
            NotificationsScreen(),
            ProfileScreen(),
          ];
          titles = const [
            'الإبلاغ عن جهاز',
            'التنبيهات والبلاغات',
            'الملف الشخصي',
          ];
        } else {
          pages = [
            const ProfileScreen(),
            const NotificationsScreen(),
            HomeScreen(onNavigateTab: _navigateToTab),
            const CheckPhoneScreen(),
            const DeviceRegistryScreen(),
          ];
          if (_isAdmin) pages.add(const AdminControlPanelScreen());
          titles = [..._titles, if (_isAdmin) 'لوحة إدارة أمان'];
        }

        return _buildScaffold(
          currentIndex: _selectedIndex,
          pages: pages,
          titles: titles,
        );
      },
    );
  }

  Widget _buildScaffold({
    required int currentIndex,
    required List<Widget> pages,
    required List<String> titles,
  }) {
    return Scaffold(
      backgroundColor: background,

      // الشريط العلوي
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 65,
        title: Text(
          titles[currentIndex],
          style: const TextStyle(
            color: textDark,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded, color: primary, size: 25),
          ),
        ),
        actions: [
          const LanguageSwitchButton(),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: borderColor),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: primary,
                  size: 22,
                ),
                onPressed: () => _navigateToTab(1),
              ),
            ),
          ),
        ],
      ),

      // القائمة الجانبية
      drawer: Drawer(
        backgroundColor: Colors.white,
        width: 290,
        child: SafeArea(
          child: Column(
            children: [
              // رأس القائمة
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 30,
                ),
                decoration: const BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 50, height: 50),
                    const SizedBox(height: 16),

                    const Text(
                      'أ مــان ',
                      style: TextStyle(
                        fontSize: 22,

                        fontWeight: FontWeight.bold,
                        color: secondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'نظام حماية الهواتف',
                      style: TextStyle(fontSize: 12, color: secondary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'معاً ضد سرقة الهواتف',
                      style: TextStyle(fontSize: 11, color: textGrey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_isNormalUser) ...[
                _buildDrawerItem(
                  icon: Icons.report_gmailerrorred_rounded,
                  title: 'الإبلاغ عن جهاز',
                  index: 0,
                ),
                _buildDrawerItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'التنبيهات والبلاغات',
                  index: 1,
                ),
                _buildDrawerItem(
                  icon: Icons.person_outline_rounded,
                  title: 'الملف الشخصي',
                  index: 2,
                ),
              ] else ...[
                _buildDrawerItem(
                  icon: Icons.home_rounded,
                  title: 'الرئيسية',
                  index: 2,
                ),
                _buildDrawerItem(
                  icon: Icons.search_rounded,
                  title: 'فحص هاتف (IMEI)',
                  index: 3,
                ),
                _buildDrawerItem(
                  icon: Icons.devices_rounded,
                  title: 'سجل الأجهزة',
                  index: 4,
                ),
                _buildDrawerItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'الإشعارات والتنبيهات',
                  index: 1,
                ),
                _buildDrawerItem(
                  icon: Icons.person_outline_rounded,
                  title: 'الملف الشخصي',
                  index: 0,
                ),
                if (_isAdmin)
                  _buildDrawerItem(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'لوحة إدارة أمان',
                    index: 5,
                  ),
              ],

              const Spacer(),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: primary,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'أمانك يبدأ من التحقق',
                          style: TextStyle(
                            color: secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // محتوى الصفحات
      body: IndexedStack(index: currentIndex, children: pages),

      // شريط التنقل السفلي
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // عناصر القائمة الجانبية
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final bool selected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: selected ? lightBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.pop(context);
            _navigateToTab(index);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: selected ? primary : textGrey),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: selected ? primary : textDark,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // تصميم شريط التنقل السفلي
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: borderColor, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 73,
          child: Row(
            children: _isNormalUser
                ? [
                    _buildNavItem(
                      icon: Icons.report_gmailerrorred_rounded,
                      label: 'الإبلاغ',
                      index: 0,
                    ),
                    _buildNavItem(
                      icon: Icons.notifications_none_rounded,
                      label: 'التنبيهات',
                      index: 1,
                    ),
                    _buildNavItem(
                      icon: Icons.person_outline_rounded,
                      label: 'حسابي',
                      index: 2,
                    ),
                  ]
                : [
                    _buildNavItem(
                      icon: Icons.person_outline_rounded,
                      label: 'حسابي',
                      index: 0,
                    ),
                    _buildNavItem(
                      icon: Icons.notifications_none_rounded,
                      label: 'التنبيهات',
                      index: 1,
                    ),
                    _buildNavItem(
                      icon: Icons.shield_rounded,
                      label: 'الرئيسية',
                      index: 2,
                      isCenter: true,
                    ),
                    _buildNavItem(
                      icon: Icons.search_rounded,
                      label: 'فحص جهاز',
                      index: 3,
                    ),
                    _buildNavItem(
                      icon: Icons.devices_outlined,
                      label: 'الأجهزة',
                      index: 4,
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  // تصميم كل زر في الشريط السفلي
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool isCenter = false,
  }) {
    final bool selected = _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _navigateToTab(index),
        child: SizedBox(
          height: 73,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isCenter)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: selected ? 47 : 41,
                  height: selected ? 47 : 41,
                  decoration: BoxDecoration(
                    color: selected ? primary : lightBlue,
                    shape: BoxShape.circle,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.18),
                              blurRadius: 9,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    icon,
                    color: selected ? Colors.white : primary,
                    size: 23,
                  ),
                )
              else
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? lightBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? primary : textGrey,
                    size: 22,
                  ),
                ),

              if (!isCenter) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    color: selected ? primary : textGrey,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// صفحة الإشعارات والتنبيهات
// ============================================

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const Color primary = Color(0xFF315F73);
  static const Color secondary = Color(0xFF527F90);
  static const Color background = Color(0xFFF8FAFB);
  static const Color textDark = Color(0xFF243943);
  static const Color textGrey = Color(0xFF87969D);
  static const Color borderColor = Color(0xFFE8EEF0);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // التنبيه التوضيحي
        Container(
          margin: const EdgeInsets.fromLTRB(18, 12, 18, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF4F6),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFDCE8EC)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: primary, size: 25),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'قائمة الأجهزة المحظورة والمبلغ عنها حديثاً لحماية أصحاب المحلات والمستعملين.',
                  style: TextStyle(fontSize: 12, color: secondary, height: 1.7),
                ),
              ),
            ],
          ),
        ),

        // عنوان القائمة
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Text(
                'الأجهزة المبلغ عنها',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              Spacer(),
              Icon(Icons.security_rounded, color: primary, size: 19),
            ],
          ),
        ),

        // بيانات Firebase
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('stolen_reports')
                .orderBy('reportedAt', descending: true)
                .limit(20)
                .snapshots(),

            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: primary),
                );
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'حدث خطأ أثناء تحميل التنبيهات',
                    style: TextStyle(color: textGrey),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4F6),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 42,
                          color: secondary,
                        ),
                      ),
                      const SizedBox(height: 17),
                      const Text(
                        'لا توجد تنبيهات جديدة',
                        style: TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'ستظهر هنا الأجهزة المبلغ عنها حديثاً',
                        style: TextStyle(color: textGrey, fontSize: 11),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 25),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;

                  final String imei = data['imei']?.toString() ?? 'غ/م';

                  final String model =
                      data['deviceModel']?.toString() ?? 'جهاز غير معروف';

                  final String policeReport =
                      data['policeReportNo']?.toString() ?? 'غير مدخل';

                  String dateStr = 'مؤخراً';

                  if (data['createdAt'] is Timestamp) {
                    final dt = (data['createdAt'] as Timestamp).toDate();

                    dateStr =
                        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                  }

                  return Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAEEEE),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.phonelink_erase_rounded,
                            color: Color(0xFFC45D5D),
                            size: 24,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                model,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'IMEI: $imei',
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: secondary,
                                  fontFamily: 'monospace',
                                ),
                              ),

                              if (policeReport != 'غير مدخل') ...[
                                const SizedBox(height: 5),
                                Text(
                                  'بلاغ الشرطة: $policeReport',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: textGrey,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 8),

                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFC45D5D),
                          size: 20,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
