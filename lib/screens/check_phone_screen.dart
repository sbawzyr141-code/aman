import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import '../l10n/app_language.dart';
import '../services/firebase_service.dart'; // استدعاء خدمة الفايربيس
import '../services/form_draft_storage.dart';

class CheckPhoneScreen extends StatefulWidget {
  const CheckPhoneScreen({super.key});

  @override
  State<CheckPhoneScreen> createState() => _CheckPhoneScreenState();
}

class _CheckPhoneScreenState extends State<CheckPhoneScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _imeiController = TextEditingController();

  bool _isLoading = false;
  bool _hasChecked = false;

  // نتائج الفحص القادمة من الفايربيس
  Map<String, dynamic> _checkResult = {};

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final draft = await FormDraftStorage.load('check_phone');
    if (!mounted) return;
    _imeiController.text = draft['imei'] as String? ?? '';
    setState(() {});
  }

  Future<void> _saveDraft() {
    return FormDraftStorage.save('check_phone', {'imei': _imeiController.text});
  }

  void _checkDevice() async {
    final imei = _imeiController.text.trim();
    // التحقق المرن: يقبل الرقم التسلسلي أو IMEI من 10 إلى 15 خانة (شامل أجهزة الآيفون والأندرويد)
    if (imei.isEmpty || imei.length < 10 || imei.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الرجاء إدخال رقم IMEI أو تسلسلي صحيح (بين 10 إلى 15 خانة)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasChecked = false;
    });

    // استدعاء دالة الفحص الحقيقية من FirebaseService
    final result = await _firebaseService.checkImeiStatus(imei);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _hasChecked = true;
      _checkResult = result;
    });
  }

  @override
  void dispose() {
    _imeiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // كارت إدخال رقم IMEI أو التسلسلي
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8EEF0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'أدخل رقم IMEI أو الرقم التسلسلي ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF243943),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _imeiController,
                  keyboardType: TextInputType
                      .text, // مدعوم للأحرف والأرقام (مثل Serial للآيفون)
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      15,
                    ), // الحد الأقصى العالمي 15 خانة
                  ],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: translateAppText(
                      'أدخل من 10 إلى 15 خانة (IMEI / Serial)',
                    ),
                    prefixIcon: const Icon(
                      Icons.qr_code_scanner,
                      color: Color(0xFF315F73),
                    ),
                    suffixIcon: _imeiController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _imeiController.clear();
                              unawaited(FormDraftStorage.clear('check_phone'));
                              setState(() {
                                _hasChecked = false;
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8EEF0)),
                    ),
                    enabledBorder: OutlineInputBorder(
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
                  onChanged: (val) {
                    setState(() {});
                    unawaited(_saveDraft());
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF315F73),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isLoading ? null : _checkDevice,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'فحص الجهاز',
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
          const SizedBox(height: 20),

          // عرض النتائج بناءً على حالة الـ IMEI من قاعدة البيانات
          if (_hasChecked) ...[
            if (_checkResult['isStolen'] == true)
              _buildStolenResultCard(_checkResult['reportData'] ?? {})
            else if (_checkResult['isRegistered'] == true)
              _buildRegisteredResultCard(
                _checkResult['contractData'] ?? {},
                _checkResult['totalOwners'] ?? 1,
              )
            else
              _buildCleanResultCard(),
          ],
        ],
      ),
    );
  }

  // 1. كارت الهاتف المسروق (تحذير خطير)
  Widget _buildStolenResultCard(Map<String, dynamic> reportData) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  'الهاتف مسروق ومبلغ عنه!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _checkResult['statusText'] ??
                'تحذير: هذا الهاتف مسجل كمفقود أو مسروق!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _buildRowItem(
                  'اسم المالك',
                  reportData['ownerName'] ?? 'غير متوفر',
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildRowItem(
                  'رقم هاتف المالك',
                  reportData['ownerPhone'] ?? 'غير متوفر',
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildRowItem(
                  'مدينة الحادثة',
                  reportData['incidentCity'] ?? 'غير متوفرة',
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildRowItem(
                  'رقم بلاغ الشرطة',
                  reportData['policeReportNumber'] ?? 'بدون رقم',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. كارت الهاتف الموثق (عقد بيع مسجل مسبقاً)
  Widget _buildRegisteredResultCard(
    Map<String, dynamic> contractData,
    int totalOwners,
  ) {
    final device = contractData['device'] ?? {};
    final buyer = contractData['buyer'] ?? {};

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE8EC)),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified, color: Color(0xFF315F73), size: 48),
          const SizedBox(height: 10),
          const Text(
            'هاتف موثق ومرتبط بعقد رسمي',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF315F73),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'هذا الهاتف مسجل في عقود البيع الموثقة عبر المنظومة.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF527F90), height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _buildRowItem(
                  'ماركة وموديل الجهاز',
                  '${device['brand'] ?? ''} ${device['model'] ?? ''}',
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildRowItem(
                  'اسم المالك الحالي',
                  buyer['name'] ?? 'غير متوفر',
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildRowItem('عدد مرات تداول الجهاز', '$totalOwners مرة'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. كارت الهاتف السليم تماماً
  Widget _buildCleanResultCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 48),
          const SizedBox(height: 10),
          const Text(
            'الهاتف سليم تماماً',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'لا توجد أي بلاغات سرقة أو عقود بيع مسجلة لهذا الرقم التسلسلي.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF527F90), height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _buildRowItem('رقم التسلسل / IMEI', _imeiController.text),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 4,
                          backgroundColor: Color(0xFF16A34A),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'سليم / غير مسروق',
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'الحالة',
                      style: TextStyle(color: Color(0xFF87969D), fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF87969D), fontSize: 13),
        ),
      ],
    );
  }
}
