import 'package:flutter/material.dart' hide Text;
import '../l10n/app_language.dart';
import 'register_sale_screen.dart';
import 'manage_contracts_screen.dart';
import 'transfer_ownership_screen.dart';
import 'report_theft_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  // ألوان هوية تطبيق أمان
  static const Color primary = Color(0xFF315F73);
  static const Color secondary = Color(0xFF527F90);
  static const Color background = Color(0xFFF6F9FA);
  static const Color lightBlue = Color(0xFFE8F1F4);
  static const Color textDark = Color(0xFF243943);
  static const Color textGrey = Color(0xFF87969D);
  static const Color borderColor = Color(0xFFE8EEF0);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس الصفحة

            const SizedBox(height: 27),

            // البطاقة الترحيبية
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFDCE9ED)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'مرحباً بك في أ مــان',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'معاً نحو بيئة أكثر أماناً لتداول وشراء الهواتف.',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondary,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'حماية تثق بها',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 75,
                    height: 75,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/b.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.shield_rounded,
                            color: primary,
                            size: 36,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // عنوان الخدمات
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الخدمات الرئيسية',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                Text(
                  'خدمات أمان',
                  style: TextStyle(fontSize: 11, color: textGrey),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // الصف الأول
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    title: 'فحص هاتف',
                    subtitle: 'التحقق من حالة الهاتف',
                    icon: Icons.search_rounded,
                    onTap: () => onNavigateTab(3),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: _buildActionCard(
                    title: 'تسجيل بيع',
                    subtitle: 'تسجيل عملية بيع جديدة',
                    icon: Icons.receipt_long_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterSaleScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 13),

            // الصف الثاني
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    title: 'سجل الأجهزة',
                    subtitle: 'الأجهزة المسجلة',
                    icon: Icons.devices_rounded,
                    onTap: () => onNavigateTab(4),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: _buildActionCard(
                    title: 'الإبلاغ عن سرقة',
                    subtitle: 'الإبلاغ عن جهاز مسروق',
                    icon: Icons.report_gmailerrorred_rounded,
                    isWarning: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReportTheftScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              'خدمات إضافية',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),

            const SizedBox(height: 15),

            // نقل الملكية
            _buildWideAction(
              icon: Icons.swap_horiz_rounded,
              title: 'نقل ملكية الهاتف',
              subtitle: 'نقل ملكية الجهاز أو استبداله',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransferOwnershipScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // إدارة العقود
            _buildWideAction(
              icon: Icons.description_outlined,
              title: 'إدارة العقود',
              subtitle: 'عرض وتعديل وحذف العقود',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageContractsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            // تنبيه أمان
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: const Color(0xFFEDF4F6),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: const Color(0xFFDCE8EC)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: primary, size: 25),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نصيحة من أمان',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'لا تقم بشراء أي هاتف مستعمل قبل التحقق من رقمه التسلسلي وحالته عبر التطبيق لضمان حقوقك.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.7,
                            color: secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // بطاقة الخدمات الرئيسية
  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isWarning = false,
  }) {
    final Color iconColor = isWarning ? const Color(0xFFC45D5D) : primary;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          height: 148,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: isWarning ? const Color(0xFFFAEEEE) : lightBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 23),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: textGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // الأزرار العريضة للخدمات الإضافية
  Widget _buildWideAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: primary, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: textGrey),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: textGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
