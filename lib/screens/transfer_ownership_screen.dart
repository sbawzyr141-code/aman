import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_language.dart';
import '../services/form_draft_storage.dart';
import '../services/pdf_contract_service.dart';

class TransferOwnershipScreen extends StatefulWidget {
  const TransferOwnershipScreen({super.key});

  @override
  State<TransferOwnershipScreen> createState() =>
      _TransferOwnershipScreenState();
}

class _TransferOwnershipScreenState extends State<TransferOwnershipScreen> {
  // حقول بيانات المالك السابق (البائع)
  final TextEditingController _prevOwnerNameController =
      TextEditingController();
  final TextEditingController _prevOwnerPhoneController =
      TextEditingController();
  final TextEditingController _prevOwnerIdController = TextEditingController();

  // حقول بيانات المالك الجديد (المشتري)
  final TextEditingController _newOwnerNameController = TextEditingController();
  final TextEditingController _newOwnerPhoneController =
      TextEditingController();
  final TextEditingController _newOwnerIdController = TextEditingController();

  // حقول بيانات الجهاز
  final TextEditingController _deviceModelController = TextEditingController();
  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool _isLoading = false;
  bool _agreementAccepted = false;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final draft = await FormDraftStorage.load('transfer_ownership');
    if (!mounted) return;
    _prevOwnerNameController.text = draft['previousOwnerName'] as String? ?? '';
    _prevOwnerPhoneController.text =
        draft['previousOwnerPhone'] as String? ?? '';
    _prevOwnerIdController.text = draft['previousOwnerId'] as String? ?? '';
    _newOwnerNameController.text = draft['newOwnerName'] as String? ?? '';
    _newOwnerPhoneController.text = draft['newOwnerPhone'] as String? ?? '';
    _newOwnerIdController.text = draft['newOwnerId'] as String? ?? '';
    _deviceModelController.text = draft['deviceModel'] as String? ?? '';
    _imeiController.text = draft['imei'] as String? ?? '';
    _priceController.text = draft['price'] as String? ?? '';
    _agreementAccepted = (draft['agreementAccepted'] as bool?) ?? false;
    setState(() {});
  }

  Future<void> _saveDraft() {
    return FormDraftStorage.save('transfer_ownership', {
      'previousOwnerName': _prevOwnerNameController.text,
      'previousOwnerPhone': _prevOwnerPhoneController.text,
      'previousOwnerId': _prevOwnerIdController.text,
      'newOwnerName': _newOwnerNameController.text,
      'newOwnerPhone': _newOwnerPhoneController.text,
      'newOwnerId': _newOwnerIdController.text,
      'deviceModel': _deviceModelController.text,
      'imei': _imeiController.text,
      'price': _priceController.text,
      'agreementAccepted': _agreementAccepted,
    });
  }

  Future<void> _clearDraftAfterSuccess() async {
    try {
      await FormDraftStorage.clear('transfer_ownership');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ نقل الملكية، لكن تعذر حذف المسودة: $error'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    _prevOwnerNameController.dispose();
    _prevOwnerPhoneController.dispose();
    _prevOwnerIdController.dispose();
    _newOwnerNameController.dispose();
    _newOwnerPhoneController.dispose();
    _newOwnerIdController.dispose();
    _deviceModelController.dispose();
    _imeiController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // دالة الحفظ والربط الحقيقي بـ Firebase Firestore
  Future<void> _submitTransferOwnership() async {
    // 1. التحقق من إدخال الحقول الإجبارية
    if (_prevOwnerNameController.text.trim().isEmpty ||
        _newOwnerNameController.text.trim().isEmpty ||
        _imeiController.text.trim().isEmpty ||
        _deviceModelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الرجاء إدخال بيانات المالك السابق، الجديد، وموديل ورقم الجهاز (IMEI / Serial)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // التحقق المرن لطول رقم التسلسل (بين 10 إلى 15 خانة للآيفون والأندرويد)
    final imeiText = _imeiController.text.trim();
    if (imeiText.length < 10 || imeiText.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'رقم التسلسل غير صالح (يجب أن يكون بين 10 إلى 15 خانة)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_agreementAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يجب الموافقة على الإقرار القانوني بصحة نقل الملكية أولاً',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      final String shopId = currentUser?.uid ?? 'unknown_shop';
      final String contractId =
          'TRN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;

      // 2. تخزين البيانات حقيقياً في قاعدة بيانات Firebase Firestore
      await FirebaseFirestore.instance.collection('device_transfers').add({
        'shopId': shopId,
        'contractId': contractId,
        'previousOwnerName': _prevOwnerNameController.text.trim(),
        'previousOwnerPhone': _prevOwnerPhoneController.text.trim(),
        'previousOwnerId': _prevOwnerIdController.text.trim(),
        'newOwnerName': _newOwnerNameController.text.trim(),
        'newOwnerPhone': _newOwnerPhoneController.text.trim(),
        'newOwnerId': _newOwnerIdController.text.trim(),
        'deviceModel': _deviceModelController.text.trim(),
        'imei': imeiText,
        'price': price,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      await _clearDraftAfterSuccess();
      if (!mounted) return;
      setState(() => _isLoading = false);

      // 3. عرض رسالة النجاح وخيار طباعة عقد النقل PDF
      _showSuccessDialog(contractId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء الحفظ سحابياً: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF315F73),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'خدمة نقل الملكية (استبدال الأجهزة)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: const [LanguageSwitchButton()],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF315F73)),
                  SizedBox(height: 16),
                  Text(
                    'جاري توثيق وتثبيت عملية نقل الملكية سحابياً...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF315F73),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ترويحة توضيحية
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1F4),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFDCE8EC)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF527F90)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'هذه الخدمة مخصصة لتوثيق تنازل أو استبدال الأجهزة المستعملة بين الأفراد لمنع تداول الأجهزة المسروقة.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF315F73),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 1. بيانات المالك السابق (البائع)
                  const Text(
                    'أولاً: بيانات المالك السابق (البائع أو المسلم للجهاز)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF315F73),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    _prevOwnerNameController,
                    'الاسم الكامل للمالك السابق',
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    _prevOwnerPhoneController,
                    'رقم الهاتف',
                    Icons.phone_outlined,
                    isPhone: true,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    _prevOwnerIdController,
                    'رقم الهوية أو جواز السفر',
                    Icons.badge_outlined,
                    isNumber: true,
                  ),

                  const Divider(height: 30),

                  // 2. بيانات المالك الجديد (المشتري)
                  const Text(
                    'ثانياً: بيانات المالك الجديد (المستلم)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF315F73),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    _newOwnerNameController,
                    'الاسم الكامل للمالك الجديد',
                    Icons.person_add_outlined,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    _newOwnerPhoneController,
                    'رقم هاتف المالك الجديد',
                    Icons.phone_outlined,
                    isPhone: true,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    _newOwnerIdController,
                    'رقم هوية المالك الجديد',
                    Icons.badge_outlined,
                    isNumber: true,
                  ),

                  const Divider(height: 30),

                  // 3. بيانات الجهاز الرقمية (IMEI / Serial)
                  const Text(
                    'ثالثاً: بيانات الجهاز الرقمية',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF315F73),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    _deviceModelController,
                    'موديل الجهاز (مثال: iPhone 14 Pro / Samsung)',
                    Icons.phone_android,
                  ),
                  const SizedBox(height: 10),
                  // حقل التسلسلي/IMEI المدعوم مرناً (من 10 إلى 15 خانة للأيفون والأندرويد)
                  TextField(
                    controller: _imeiController,
                    onChanged: (_) => unawaited(_saveDraft()),
                    keyboardType: TextInputType.text, // يدعم الحروف والأرقام
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(15), // حد أقصى 15 خانة
                    ],
                    decoration: InputDecoration(
                      hintText: translateAppText(
                        'الرقم التسلسلي أو IMEI (من 10 إلى 15 خانة)',
                      ),
                      prefixIcon: const Icon(
                        Icons.qr_code,
                        color: Color(0xFF315F73),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE8EEF0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF315F73),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    _priceController,
                    'مبلغ البيع أو الفارق (إن وجد)',
                    Icons.attach_money,
                    isNumber: true,
                  ),

                  const SizedBox(height: 20),

                  // الإقرار القانوني
                  CheckboxListTile(
                    value: _agreementAccepted,
                    activeColor: const Color(0xFF315F73),
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'أقر أنا المسؤول عن المحل أو المنظومة بصحة بيانات الطرفين وأن الجهاز غير محظور أو مسروق.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF527F90)),
                    ),
                    onChanged: (val) {
                      setState(() => _agreementAccepted = val ?? false);
                      unawaited(_saveDraft());
                    },
                  ),

                  const SizedBox(height: 24),

                  // زر إتمام وتوثيق نقل الملكية سحابياً
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF315F73),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: _submitTransferOwnership,
                      child: const Text(
                        'إتمام وتوثيق نقل الملكية',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPhone = false,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) => unawaited(_saveDraft()),
      keyboardType: isPhone
          ? TextInputType.phone
          : isNumber
          ? TextInputType.number
          : TextInputType.text,
      decoration: InputDecoration(
        hintText: translateAppText(hint),
        prefixIcon: Icon(icon, color: const Color(0xFF315F73), size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8EEF0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF315F73), width: 1.5),
        ),
      ),
    );
  }

  void _showSuccessDialog(String contractId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 28),
            SizedBox(width: 8),
            Text('تم نقل الملكية بنجاح!'),
          ],
        ),
        content: Text(
          'تم توثيق عملية نقل ملكية الجهاز وحفظ السجل برقم مرجعي: $contractId في قاعدة بيانات الفايربيس بنجاح.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final String currentDate =
                  '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
              await PdfContractService.generateAndShowContract(
                contractId: contractId,
                sellerName: _prevOwnerNameController.text.trim(),
                sellerId: _prevOwnerIdController.text.trim(),
                buyerName: _newOwnerNameController.text.trim(),
                buyerId: _newOwnerIdController.text.trim(),
                deviceModel: _deviceModelController.text.trim(),
                imei: _imeiController.text.trim(),
                price: '${_priceController.text.trim()} ر.ي',
                date: currentDate,
              );
            },
            child: const Text(
              'طباعة العقد (PDF)',
              style: TextStyle(
                color: Color(0xFF315F73),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF315F73),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              'إغلاق والعودة',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
