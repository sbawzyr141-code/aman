import 'package:flutter/material.dart' hide Text;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_language.dart';
import '../services/firebase_service.dart';

class ManageContractsScreen extends StatefulWidget {
  const ManageContractsScreen({super.key});

  @override
  State<ManageContractsScreen> createState() => _ManageContractsScreenState();
}

class _ManageContractsScreenState extends State<ManageContractsScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  // هوية أمان
  static const Color primary = Color(0xFF315F73);
  static const Color secondary = Color(0xFF527F90);
  static const Color lightBlue = Color(0xFFE8F1F4);
  static const Color background = Color(0xFFF8FAFB);
  static const Color textDark = Color(0xFF243943);
  static const Color textGrey = Color(0xFF87969D);
  static const Color borderColor = Color(0xFFE8EEF0);
  static const Color danger = Color(0xFFC45D5D);
  static const Color successColor = Color(0xFF39866B);

  // =========================================
  // حقول تعديل العقد
  // =========================================

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13, color: textDark),
        decoration: InputDecoration(
          labelText: translateAppText(label),
          labelStyle: const TextStyle(color: textGrey, fontSize: 12),
          prefixIcon: Icon(icon, color: secondary, size: 20),
          filled: true,
          fillColor: background,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // =========================================
  // نافذة تعديل العقد
  // =========================================

  void _showEditDialog(String contractId, Map<String, dynamic> currentData) {
    final buyerData = currentData['buyer'] ?? {};
    final deviceData = currentData['device'] ?? {};

    final buyerNameController = TextEditingController(
      text: buyerData['name'] ?? '',
    );

    final buyerPhoneController = TextEditingController(
      text: buyerData['phone'] ?? '',
    );

    final buyerIdController = TextEditingController(
      text: buyerData['idNumber'] ?? '',
    );

    final brandController = TextEditingController(
      text: deviceData['brand'] ?? '',
    );

    final modelController = TextEditingController(
      text: deviceData['model'] ?? '',
    );

    final imeiController = TextEditingController(
      text: deviceData['imei'] ?? '',
    );

    final priceController = TextEditingController(
      text: deviceData['price']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: Directionality.of(dialogContext),
          child: AlertDialog(
            backgroundColor: Colors.white,
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 10,
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 5, 20, 20),

            title: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.edit_document,
                    color: primary,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تعديل عقد البيع',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'قم بتحديث بيانات العقد',
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      'بيانات المشتري',
                      Icons.person_outline_rounded,
                    ),

                    _buildEditField(
                      controller: buyerNameController,
                      label: 'اسم المشتري',
                      icon: Icons.person_outline,
                    ),

                    _buildEditField(
                      controller: buyerPhoneController,
                      label: 'رقم هاتف المشتري',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    _buildEditField(
                      controller: buyerIdController,
                      label: 'رقم هوية المشتري',
                      icon: Icons.badge_outlined,
                    ),

                    const SizedBox(height: 10),

                    _sectionTitle('بيانات الجهاز', Icons.smartphone_rounded),

                    _buildEditField(
                      controller: brandController,
                      label: 'ماركة الجهاز',
                      icon: Icons.devices_outlined,
                    ),

                    _buildEditField(
                      controller: modelController,
                      label: 'موديل الجهاز',
                      icon: Icons.phone_android_rounded,
                    ),

                    _buildEditField(
                      controller: imeiController,
                      label: 'الرقم التسلسلي IMEI',
                      icon: Icons.qr_code_rounded,
                      keyboardType: TextInputType.number,
                    ),

                    _buildEditField(
                      controller: priceController,
                      label: 'السعر بالريال اليمني',
                      icon: Icons.payments_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textGrey,
                        side: const BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final price = double.tryParse(
                          priceController.text.trim(),
                        );

                        if (price == null || price < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('يرجى إدخال سعر صحيح'),
                              backgroundColor: danger,
                            ),
                          );
                          return;
                        }

                        final success = await _firebaseService
                            .updateSaleContract(
                              contractId: contractId,
                              buyerName: buyerNameController.text.trim(),
                              buyerPhone: buyerPhoneController.text.trim(),
                              buyerIdNumber: buyerIdController.text.trim(),
                              deviceBrand: brandController.text.trim(),
                              deviceModel: modelController.text.trim(),
                              imei: imeiController.text.trim(),
                              price: price,
                            );

                        if (!mounted) return;

                        // ignore: use_build_context_synchronously
                        Navigator.pop(dialogContext);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'تم تعديل العقد بنجاح'
                                  : 'فشل تعديل العقد',
                            ),
                            backgroundColor: success ? successColor : danger,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text(
                        'حفظ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================
  // عنوان الأقسام
  // =========================================

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 19, color: primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================
  // نافذة تأكيد الحذف
  // =========================================

  void _confirmDelete(String contractId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: Directionality.of(dialogContext),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAEEEE),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: danger,
                    size: 35,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'حذف العقد؟',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'هل أنت متأكد من حذف هذا العقد نهائياً من النظام؟ لا يمكن التراجع عن هذا الإجراء.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, height: 1.7, color: textGrey),
                ),
              ],
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textGrey,
                        side: const BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final success = await _firebaseService
                            .deleteSaleContract(contractId);

                        if (!mounted) return;

                        // ignore: use_build_context_synchronously
                        Navigator.pop(dialogContext);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success ? 'تم حذف العقد بنجاح' : 'فشل حذف العقد',
                            ),
                            backgroundColor: success ? successColor : danger,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: danger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const Text(
                        'حذف نهائياً',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================
  // بطاقة العقد
  // =========================================

  Widget _buildContractCard({
    required String brand,
    required String model,
    required String buyerName,
    required String imei,
    required String price,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اسم الجهاز
          Row(
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.smartphone_rounded,
                  color: primary,
                  size: 26,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$brand $model',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'عقد بيع جهاز',
                      style: TextStyle(color: textGrey, fontSize: 11),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4EF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'مسجل',
                  style: TextStyle(
                    color: successColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(color: borderColor, height: 1),

          const SizedBox(height: 15),

          // معلومات المشتري
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'اسم المشتري',
            value: buyerName,
          ),

          const SizedBox(height: 12),

          _buildInfoRow(
            icon: Icons.qr_code_rounded,
            label: 'IMEI',
            value: imei,
            isLtr: true,
          ),

          const SizedBox(height: 15),

          // السعر
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined, color: primary, size: 19),
                const SizedBox(width: 9),
                const Text(
                  'قيمة العقد',
                  style: TextStyle(color: secondary, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '$price ر.ي',
                  style: const TextStyle(
                    color: primary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // أزرار التحكم
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('تعديل العقد'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: const BorderSide(color: Color(0xFFDCE8EC)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 17),
                  label: const Text('حذف العقد'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: danger,
                    side: const BorderSide(color: Color(0xFFF0DADA)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================
  // تفاصيل العقد
  // =========================================

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLtr = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: textGrey, size: 18),
        const SizedBox(width: 9),
        Text('$label:', style: const TextStyle(fontSize: 11, color: textGrey)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            value,
            textDirection: isLtr ? TextDirection.ltr : null,
            textAlign: isLtr ? TextAlign.left : TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================
  // الصفحة الرئيسية
  // =========================================

  @override
  Widget build(BuildContext context) {
    final String currentShopId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: background,

        appBar: AppBar(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: primary),
          title: const Text(
            'إدارة العقود',
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: const [LanguageSwitchButton()],
        ),

        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس الصفحة
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: const Color(0xFFDCE8EC)),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'عقود المحل',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            'إدارة ومتابعة عمليات البيع المسجلة',
                            style: TextStyle(fontSize: 11, color: secondary),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.description_rounded, color: primary, size: 42),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'جميع العقود',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sales_contracts')
                    .where('shopId', isEqualTo: currentShopId)
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
                        'حدث خطأ أثناء تحميل العقود',
                        style: TextStyle(color: textGrey),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: lightBlue,
                              borderRadius: BorderRadius.circular(27),
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              color: primary,
                              size: 43,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'لا توجد عقود مسجلة',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'ستظهر هنا عقود البيع الخاصة بمحلك',
                            style: TextStyle(fontSize: 11, color: textGrey),
                          ),
                        ],
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 5, 18, 25),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];

                      final data = doc.data() as Map<String, dynamic>;

                      final contractId = doc.id;

                      final device = data['device'] ?? {};
                      final buyer = data['buyer'] ?? {};

                      final String brand =
                          device['brand'] ?? 'ماركة غير معروفة';

                      final String model = device['model'] ?? '';

                      final String buyerName = buyer['name'] ?? 'بدون اسم';

                      final String imei = device['imei'] ?? 'غير متوفر';

                      final String price = device['price']?.toString() ?? '0';

                      return _buildContractCard(
                        brand: brand,
                        model: model,
                        buyerName: buyerName,
                        imei: imei,
                        price: price,
                        onEdit: () {
                          _showEditDialog(contractId, data);
                        },
                        onDelete: () {
                          _confirmDelete(contractId);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
