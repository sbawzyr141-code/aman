import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_language.dart';
import '../services/firebase_service.dart';
import '../services/form_draft_storage.dart';

class ReportTheftScreen extends StatefulWidget {
  const ReportTheftScreen({super.key});

  @override
  State<ReportTheftScreen> createState() => _ReportTheftScreenState();
}

class _ReportTheftScreenState extends State<ReportTheftScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _deviceModelController = TextEditingController();
  final TextEditingController _policeReportController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _ownerPhoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final draft = await FormDraftStorage.load('report_theft');
    if (!mounted) return;
    _imeiController.text = draft['imei'] as String? ?? '';
    _deviceModelController.text = draft['deviceModel'] as String? ?? '';
    _policeReportController.text = draft['policeReport'] as String? ?? '';
    _ownerNameController.text = draft['ownerName'] as String? ?? '';
    _ownerPhoneController.text = draft['ownerPhone'] as String? ?? '';
  }

  Future<void> _saveDraft() {
    return FormDraftStorage.save('report_theft', {
      'imei': _imeiController.text,
      'deviceModel': _deviceModelController.text,
      'policeReport': _policeReportController.text,
      'ownerName': _ownerNameController.text,
      'ownerPhone': _ownerPhoneController.text,
    });
  }

  Future<void> _clearDraftAfterSuccess() async {
    try {
      await FormDraftStorage.clear('report_theft');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل البلاغ، لكن تعذر حذف المسودة: $error'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    _imeiController.dispose();
    _deviceModelController.dispose();
    _policeReportController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submitStolenReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      final String activeUserId = currentUser?.uid ?? 'unknown_user';

      final String imei = _imeiController.text.trim();
      final String deviceModel = _deviceModelController.text.trim();
      final String policeReportNo = _policeReportController.text.trim();
      final String ownerName = _ownerNameController.text.trim();
      final String ownerPhone = _ownerPhoneController.text.trim();

      final bool success = await _firebaseService.reportStolenPhone(
        userId: activeUserId,
        ownerName: ownerName.isNotEmpty ? ownerName : 'غير مدخل',
        ownerPhone: ownerPhone.isNotEmpty ? ownerPhone : 'غير مدخل',
        ownerIdNumber: '0000000000',
        imei: imei,
        deviceModel: deviceModel,
        incidentCity: 'المكلا',
        incidentDetails: 'بلاغ سرقة عبر التطبيق',
        policeReportNumber: policeReportNo.isNotEmpty
            ? policeReportNo
            : 'بدون رقم',
      );

      if (!mounted) return;

      if (success) {
        await _clearDraftAfterSuccess();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('تم تسجيل البلاغ وحظر الهاتف في النظام بنجاح'),
                ),
              ],
            ),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ فشل تقديم البلاغ. تأكد من تفعيل اشتراكك أو الصلاحيات أولاً.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تسجيل البلاغ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF315F73),
        foregroundColor: Colors.white,
        title: const Text(
          'الإبلاغ عن سرقة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: const [LanguageSwitchButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAEEEE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF0DADA)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'سيتم تعميم رقم IMEI أو الرقم التسلسلي على مستوى الأنظمة والمحلات لمنع تداول الهاتف وحظره فوراً.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _imeiController,
                onChanged: (_) => unawaited(_saveDraft()),
                keyboardType: TextInputType.text,
                inputFormatters: [LengthLimitingTextInputFormatter(15)],
                decoration: InputDecoration(
                  labelText: translateAppText('الرقم التسلسلي أو IMEI *'),
                  hintText: translateAppText('أدخل من 10 إلى 15 خانة'),
                  prefixIcon: const Icon(
                    Icons.qr_code_scanner,
                    color: Color(0xFF315F73),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
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
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return translateAppText(
                      'يرجى إدخال رقم الـ IMEI أو التسلسلي',
                    );
                  }
                  if (val.trim().length < 10 || val.trim().length > 15) {
                    return translateAppText(
                      'رقم التسلسل غير صالح (يجب أن يكون بين 10 إلى 15 خانة)',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deviceModelController,
                onChanged: (_) => unawaited(_saveDraft()),
                decoration: InputDecoration(
                  labelText: translateAppText('موديل الهاتف والشركة *'),
                  hintText: translateAppText(
                    'مثال: iPhone 15 Pro / Samsung S24',
                  ),
                  prefixIcon: const Icon(
                    Icons.phone_android,
                    color: Color(0xFF315F73),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
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
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return translateAppText('يرجى إدخال موديل الهاتف والشركة');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _policeReportController,
                onChanged: (_) => unawaited(_saveDraft()),
                decoration: InputDecoration(
                  labelText: translateAppText('رقم بلاغ الشرطة (إن وجد)'),
                  prefixIcon: const Icon(
                    Icons.local_police_outlined,
                    color: Color(0xFF315F73),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
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
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerNameController,
                onChanged: (_) => unawaited(_saveDraft()),
                decoration: InputDecoration(
                  labelText: translateAppText('اسم المالك / الشاكي'),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF315F73),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
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
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerPhoneController,
                onChanged: (_) => unawaited(_saveDraft()),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: translateAppText('رقم الهاتف للتواصل'),
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: Color(0xFF315F73),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
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
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC45D5D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _submitStolenReport,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'تسجيل البلاغ وحظر الهاتف فوراً',
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
      ),
    );
  }
}
