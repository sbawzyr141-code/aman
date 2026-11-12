import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:simple_icons/simple_icons.dart';
import '../l10n/app_language.dart';
import '../services/firebase_service.dart';
import '../services/form_draft_storage.dart';
import '../services/pdf_contract_service.dart';

class RegisterSaleScreen extends StatefulWidget {
  const RegisterSaleScreen({super.key});

  @override
  State<RegisterSaleScreen> createState() => _RegisterSaleScreenState();
}

class _RegisterSaleScreenState extends State<RegisterSaleScreen> {
  // كائن خدمة الفايربيس
  final FirebaseService _firebaseService = FirebaseService();

  // حالة التحميل أثناء الإرسال لـ Firebase
  bool _isLoading = false;
  bool _isDraftLoaded = false;

  // الخطوات 3 فقط: 1 = بيانات المشتري، 2 = بيانات الهاتف والسعر، 3 = مراجعة وتأكيد
  int _currentStep = 1;

  // الحقول الخاصة بالخطوة 1 (بيانات المشتري)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // الحقول الخاصة بالخطوة 2 (بيانات الهاتف والسعر)
  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _selectedDeviceType = 'هاتف ذكي';
  String _selectedBrand = 'Apple';
  String _selectedModel = 'iPhone 17 Pro';
  String _selectedColor = 'تيتانيوم طبيعي';
  String _selectedStorage = '256 GB';
  final Map<String, List<String>> _customModelsByBrand = {};
  List<String> _customBrands = [];

  // قوائم الخيارات
  final List<String> _deviceTypes = [
    'هاتف ذكي',
    'جهاز لوحي (تابلت)',
    'ساعة ذكية',
  ];
  final List<String> _brands = [
    'Apple',
    'Samsung',
    'Xiaomi',
    'Huawei',
    'Google',
    'Honor',
    'OnePlus',
    'OPPO',
    'vivo',
    'Motorola',
    'Realme',
    'Sony',
    'Nokia',
    'Tecno',
    'Infinix',
  ];
  final Map<String, List<String>> _modelsByBrand = {
    'Apple': [
      'iPhone 18 Pro Max',
      'iPhone 18 Pro',
      'iPhone 18',
      'iPhone 18 Air',
      'iPhone 17 Pro Max',
      'iPhone 17 Pro',
      'iPhone 17',
      'iPhone 17 Air',
      'iPhone 16 Pro Max',
      'iPhone 16 Pro',
      'iPhone 16 Plus',
      'iPhone 16',
      'iPhone 16e',
      'iPhone 15 Pro Max',
      'iPhone 15 Pro',
      'iPhone 15 Plus',
      'iPhone 15',
      'iPhone 14 Pro Max',
      'iPhone 14 Pro',
      'iPhone 14 Plus',
      'iPhone 14',
      'iPhone 13 Pro Max',
      'iPhone 13 Pro',
      'iPhone 13 mini',
      'iPhone 13',
      'iPhone SE (3rd generation)',
      'iPhone 12 Pro Max',
      'iPhone 12 Pro',
      'iPhone 12 mini',
      'iPhone 12',
      'iPhone 11 Pro Max',
      'iPhone 11 Pro',
      'iPhone 11',
      'iPhone XS Max',
      'iPhone XS',
      'iPhone XR',
      'iPhone X',
      'iPhone 8 Plus',
      'iPhone 8',
      'iPhone 7 Plus',
      'iPhone 7',
      'iPhone 6 Plus',
      'iPhone 6',
      'iPhone 6s Plus',
      'iPhone 6s',
      'iPhone SE (2nd generation)',
      'iPhone SE (1st generation)',
      'iPhone 5s',
    ],
    'Samsung': [
      'Galaxy S25 Ultra',
      'Galaxy S25+',
      'Galaxy S25',
      'Galaxy S24 Ultra',
      'Galaxy S24+',
      'Galaxy S24',
      'Galaxy Z Fold6',
      'Galaxy Z Flip6',
      'Galaxy A56',
      'Galaxy A36',
      'Galaxy A26',
      'Galaxy A16',
      'Galaxy A15',
      'Galaxy A14',
    ],
    'Xiaomi': [
      'Xiaomi 15 Ultra',
      'Xiaomi 15 Pro',
      'Xiaomi 15',
      'Xiaomi 14 Ultra',
      'Xiaomi 14 Pro',
      'Xiaomi 14',
      'Redmi Note 14 Pro+',
      'Redmi Note 14 Pro',
      'Redmi Note 14',
      'POCO X7 Pro',
      'POCO X7',
    ],
    'Huawei': [
      'Pura 70 Ultra',
      'Pura 70 Pro',
      'Pura 70',
      'Mate 70 Pro',
      'Mate 60 Pro',
      'nova 13 Pro',
      'nova 13',
    ],
    'Google': [
      'Pixel 9 Pro XL',
      'Pixel 9 Pro',
      'Pixel 9',
      'Pixel 8 Pro',
      'Pixel 8',
      'Pixel 8a',
      'Pixel 7 Pro',
      'Pixel 7',
      'Pixel 7a',
      'Pixel 6 Pro',
      'Pixel 6',
      'Pixel 6a',
    ],
    'Honor': [
      'Magic7 Pro',
      'Magic7',
      'Magic6 Pro',
      'Honor 200 Pro',
      'Honor 200',
    ],
    'OnePlus': [
      'OnePlus 13',
      'OnePlus 13R',
      'OnePlus Open',
      'OnePlus Nord 5',
      'OnePlus Nord 4',
    ],
    'OPPO': [
      'Find X8 Pro',
      'Find X8',
      'Reno14 Pro',
      'Reno14',
      'Reno13 Pro',
      'Reno13',
    ],
    'vivo': ['X200 Pro', 'X200', 'V60', 'V50'],
    'Motorola': ['Edge 60 Pro', 'Edge 60', 'Moto G86', 'Moto G75'],
    'Realme': ['GT 7 Pro', 'GT 7', '14 Pro+', '14 Pro', '14'],
    'Sony': ['Xperia 1 VI', 'Xperia 10 VI'],
    'Nokia': ['XR21', 'G42 5G', 'G22', 'X30 5G', 'G60 5G'],
    'Tecno': ['Camon 40 Pro', 'Camon 40', 'Spark 30 Pro'],
    'Infinix': ['Zero Flip', 'Zero 40', 'Hot 50 Pro+'],
  };
  final List<String> _colors = [
    'تيتانيوم طبيعي',
    'أسود',
    'أبيض',
    'أزرق',
    'ذهبي',
    'رمادي',
  ];
  final List<String> _storages = [
    '64 GB',
    '128 GB',
    '256 GB',
    '512 GB',
    '1 TB',
  ];

  List<String> get _availableModels => _modelsByBrand[_selectedBrand] ?? [];
  List<String> get _brandsForSelection => [..._brands, ..._customBrands];
  List<String> get _modelsForSelectedBrand => [
    ..._availableModels,
    ...?_customModelsByBrand[_selectedBrand],
  ];

  // الخطوة الأخيرة: الإقرار والشروط
  bool _agreementAccepted = false;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final draft = await FormDraftStorage.load('register_sale');
    if (!mounted) return;

    _nameController.text = draft['buyerName'] as String? ?? '';
    _idController.text = draft['buyerId'] as String? ?? '';
    _phoneController.text = draft['buyerPhone'] as String? ?? '';
    _addressController.text = draft['buyerAddress'] as String? ?? '';
    _imeiController.text = draft['imei'] as String? ?? '';
    _priceController.text = draft['price'] as String? ?? '';

    final savedCustomModels = draft['customModels'];
    if (savedCustomModels is Map) {
      for (final entry in savedCustomModels.entries) {
        if (entry.value is List) {
          _customModelsByBrand[entry.key.toString()] = (entry.value as List)
              .whereType<String>()
              .toList();
        }
      }
    }
    final savedCustomBrands = draft['customBrands'];
    if (savedCustomBrands is List) {
      _customBrands = savedCustomBrands.whereType<String>().toList();
    }

    final savedBrand = draft['brand'] as String?;
    if (savedBrand != null) {
      _selectedBrand = savedBrand;
      if (!_brandsForSelection.contains(savedBrand)) {
        _customBrands.add(savedBrand);
      }
    }
    final model = draft['model'] as String?;
    if (model != null) {
      _selectedModel = model;
      if (!_modelsForSelectedBrand.any(
        (savedModel) => savedModel.toLowerCase() == model.toLowerCase(),
      )) {
        _customModelsByBrand.putIfAbsent(_selectedBrand, () => []).add(model);
      }
    }
    final deviceType = draft['deviceType'] as String?;
    if (_deviceTypes.contains(deviceType)) _selectedDeviceType = deviceType!;
    final color = draft['color'] as String?;
    if (_colors.contains(color)) _selectedColor = color!;
    final storage = draft['storage'] as String?;
    if (_storages.contains(storage)) _selectedStorage = storage!;
    _currentStep = (draft['step'] as int?) ?? 1;
    _agreementAccepted = (draft['agreementAccepted'] as bool?) ?? false;

    setState(() => _isDraftLoaded = true);
  }

  Future<void> _saveDraft() {
    return FormDraftStorage.save('register_sale', {
      'buyerName': _nameController.text,
      'buyerId': _idController.text,
      'buyerPhone': _phoneController.text,
      'buyerAddress': _addressController.text,
      'imei': _imeiController.text,
      'price': _priceController.text,
      'deviceType': _selectedDeviceType,
      'brand': _selectedBrand,
      'model': _selectedModel,
      'customBrands': _customBrands,
      'color': _selectedColor,
      'storage': _selectedStorage,
      'customModels': _customModelsByBrand,
      'step': _currentStep,
      'agreementAccepted': _agreementAccepted,
    });
  }

  Future<void> _clearDraftAfterSuccess() async {
    try {
      await FormDraftStorage.clear('register_sale');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل عقد البيع، لكن تعذر حذف المسودة: $error'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _imeiController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ==========================================
  // دالة الإرسال والحفظ المباشر لـ Firebase
  // ==========================================
  Future<void> _saveContractToFirebase() async {
    setState(() => _isLoading = true);

    final double parsedPrice =
        double.tryParse(_priceController.text.trim()) ?? 0.0;
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String activeUserId = currentUser?.uid ?? 'unknown_shop';

    try {
      final Map<String, dynamic> result = await _firebaseService
          .registerSaleContract(
            userId: activeUserId,
            sellerName: currentUser?.displayName ?? 'محل معتمد',
            sellerPhone: currentUser?.phoneNumber ?? '0500000000',
            sellerIdNumber: activeUserId.length >= 10
                ? activeUserId.substring(0, 10)
                : '1000000000',
            sellerAddress: 'المكلا',
            buyerName: _nameController.text.trim(),
            buyerPhone: _phoneController.text.trim(),
            buyerIdNumber: _idController.text.trim(),
            buyerAddress: _addressController.text.trim().isEmpty
                ? 'المكلا'
                : _addressController.text.trim(),
            deviceBrand: _selectedBrand,
            deviceModel: _selectedModel,
            imei: _imeiController.text.trim(),
            deviceColor: _selectedColor,
            storageSize: _selectedStorage,
            deviceCondition: 'مستعمل بحالة ممتازة',
            price: parsedPrice,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        await _clearDraftAfterSuccess();
        if (!mounted) return;
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ??
                  'فشل توثيق العقد. تأكد من تفعيل الاشتراك الشهري.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الاتصال: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D253F),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'تسجيل عملية بيع',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: const [LanguageSwitchButton()],
      ),
      body: !_isDraftLoaded
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D253F)),
            )
          : _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0D253F)),
                  SizedBox(height: 16),
                  Text(
                    'جاري التحقق من الاشتراك وتوثيق العقد سحابياً...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D253F),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildStepProgressIndicator(),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: _currentStep == 1
                        ? _buildBuyerInfoStep()
                        : _currentStep == 2
                        ? _buildPhoneInfoStep()
                        : _buildReviewAndConfirmStep(),
                  ),
                ),
              ],
            ),
    );
  }

  // ==========================================
  // شريط مؤشر الخطوات الرقمي (3 خطوات)
  // ==========================================
  Widget _buildStepProgressIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepCircle(1, 'بيانات المشتري'),
          _buildStepConnector(_currentStep >= 2),
          _buildStepCircle(2, 'بيانات الجهاز'),
          _buildStepConnector(_currentStep >= 3),
          _buildStepCircle(3, 'مراجعة وتأكيد'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int stepNumber, String label) {
    final bool isCompleted = _currentStep > stepNumber;
    final bool isCurrent = _currentStep == stepNumber;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? const Color(0xFF16A34A)
                : isCurrent
                ? const Color(0xFF0D253F)
                : const Color(0xFFCBD5E1),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent
                ? const Color(0xFF0D253F)
                : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
        color: isActive ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
      ),
    );
  }

  // ==========================================
  // الخطوة 1: بيانات المشتري
  // ==========================================
  Widget _buildBuyerInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.person, color: Color(0xFF0D253F), size: 22),
            SizedBox(width: 8),
            Text(
              'بيانات المشتري',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D253F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'الاسم الكامل',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _buildTextField(
          _nameController,
          'أدخل الاسم الكامل',
          Icons.person_outline,
        ),
        const SizedBox(height: 14),
        const Text(
          'رقم الهوية / جواز السفر',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _buildTextField(
          _idController,
          'أدخل رقم الهوية أو جواز السفر',
          Icons.badge_outlined,
          isNumber: true,
        ),
        const SizedBox(height: 14),
        const Text(
          'رقم الهاتف',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _buildTextField(
          _phoneController,
          'أدخل رقم الهاتف',
          Icons.phone_outlined,
          isPhone: true,
        ),
        const SizedBox(height: 14),
        const Text(
          'العنوان',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _buildTextField(
          _addressController,
          'أدخل العنوان (المدينة / الحي)',
          Icons.location_on_outlined,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D253F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (_nameController.text.trim().isEmpty ||
                  _idController.text.trim().isEmpty ||
                  _phoneController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرجاء إدخال الاسم، رقم الهوية ورقم الهاتف'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              setState(() => _currentStep = 2);
              unawaited(_saveDraft());
            },
            child: const Text(
              'التالي',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // الخطوة 2: بيانات الهاتف والسعر
  // ==========================================
  Widget _buildPhoneInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.phone_android, color: Color(0xFF0D253F), size: 22),
            SizedBox(width: 8),
            Text(
              'بيانات الجهاز المباع والسعر',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D253F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'الرقم التسلسلي (IMEI)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _imeiController,
          onChanged: (_) => unawaited(_saveDraft()),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: translateAppText('أدخل الرقم التسلسلي (IMEI)'),
            prefixIcon: IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF0D253F)),
              onPressed: _showScannerMockDialog,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _showImeiHelpDialog,
            child: const Text(
              'كيف تجد رقم IMEI ؟',
              style: TextStyle(
                color: Color(0xFF0D253F),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const Text(
          'نوع الجهاز',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _buildDropdown(_deviceTypes, _selectedDeviceType, (val) {
          setState(() => _selectedDeviceType = val!);
          unawaited(_saveDraft());
        }),
        const SizedBox(height: 14),
        const Text(
          'الشركة المصنعة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _buildBrandSearchField(),
        const SizedBox(height: 14),
        const Text(
          'الموديل',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _buildModelSearchField(),
        const SizedBox(height: 14),
        const Text(
          'اللون',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _buildDropdown(_colors, _selectedColor, (val) {
          setState(() => _selectedColor = val!);
          unawaited(_saveDraft());
        }),
        const SizedBox(height: 14),
        const Text(
          'سعة التخزين',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _buildDropdown(_storages, _selectedStorage, (val) {
          setState(() => _selectedStorage = val!);
          unawaited(_saveDraft());
        }),
        const SizedBox(height: 14),
        const Text(
          'سعر البيع (ر.ي)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _buildTextField(
          _priceController,
          'أدخل مبلغ البيع',
          Icons.attach_money,
          isNumber: true,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  setState(() => _currentStep = 1);
                  unawaited(_saveDraft());
                },
                child: const Text(
                  'السابق',
                  style: TextStyle(
                    color: Color(0xFF0D253F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D253F),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  if (_imeiController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('الرجاء إدخال الرقم التسلسلي IMEI'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  setState(() => _currentStep = 3);
                  unawaited(_saveDraft());
                },
                child: const Text(
                  'التالي',
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
      ],
    );
  }

  // ==========================================
  // الخطوة 3: مراجعة وتأكيد العقد (الخطوة الأخيرة)
  // ==========================================
  Widget _buildReviewAndConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.verified, color: Color(0xFF16A34A), size: 22),
            SizedBox(width: 8),
            Text(
              'مراجعة وتأكيد عملية البيع',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D253F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ملخص عقد المبايعة الإلكتروني',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF0D253F),
                  ),
                ),
                const Divider(height: 20),
                _summaryRow(
                  'اسم المشتري',
                  _nameController.text.isEmpty
                      ? 'لم يحدد'
                      : _nameController.text,
                ),
                _summaryRow(
                  'رقم الهوية',
                  _idController.text.isEmpty ? 'لم يحدد' : _idController.text,
                ),
                _summaryRow(
                  'رقم الهاتف',
                  _phoneController.text.isEmpty
                      ? 'لم يحدد'
                      : _phoneController.text,
                ),
                _summaryRow(
                  'العنوان',
                  _addressController.text.isEmpty
                      ? 'المكلا'
                      : _addressController.text,
                ),
                const Divider(height: 20),
                _summaryRow('الجهاز', '$_selectedBrand $_selectedModel'),
                _summaryRow(
                  'السعة واللون',
                  '$_selectedStorage - $_selectedColor',
                ),
                _summaryRow(
                  'رقم IMEI',
                  _imeiController.text.isEmpty
                      ? 'لم يحدد'
                      : _imeiController.text,
                ),
                _summaryRow(
                  'السعر',
                  '${_priceController.text.isEmpty ? '0' : _priceController.text} ر.ي',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _agreementAccepted,
          activeColor: const Color(0xFF0D253F),
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'أقر أنا بصحة كافة البيانات المذكورة وأن الهاتف غير خاضع لأي قيود جنائية أو بلاغات سرقة.',
            style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
          onChanged: (val) {
            setState(() => _agreementAccepted = val ?? false);
            unawaited(_saveDraft());
          },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  setState(() => _currentStep = 2);
                  unawaited(_saveDraft());
                },
                child: const Text(
                  'السابق',
                  style: TextStyle(
                    color: Color(0xFF0D253F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D253F),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _agreementAccepted ? _saveContractToFirebase : null,
                child: const Text(
                  'تأكيد وإصدار العقد',
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
      ],
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
        prefixIcon: Icon(icon, color: const Color(0xFF0D253F), size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0D253F), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildModelSearchField() {
    return Autocomplete<String>(
      key: ValueKey(_selectedBrand),
      initialValue: TextEditingValue(text: _selectedModel),
      optionsBuilder: (value) {
        final query = value.text.trim();
        final models = _modelsForSelectedBrand;
        if (query.isEmpty) return models;

        final matches = models
            .where((model) => model.toLowerCase().contains(query.toLowerCase()))
            .toList();
        if (!models.any(
          (model) => model.toLowerCase() == query.toLowerCase(),
        )) {
          matches.add(query);
        }
        return matches;
      },
      onSelected: (model) {
        setState(() {
          _selectedModel = model;
          if (!_modelsForSelectedBrand.any(
            (savedModel) => savedModel.toLowerCase() == model.toLowerCase(),
          )) {
            _customModelsByBrand
                .putIfAbsent(_selectedBrand, () => [])
                .add(model);
          }
        });
        unawaited(_saveDraft());
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: options.map((model) {
                  final isNewModel = !_modelsForSelectedBrand.any(
                    (savedModel) =>
                        savedModel.toLowerCase() == model.toLowerCase(),
                  );
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isNewModel ? Icons.add : Icons.phone_android,
                      color: const Color(0xFF0D253F),
                    ),
                    title: Text(
                      isNewModel ? 'إضافة الموديل: $model' : model,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () => onSelected(model),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: translateAppText('ابحث أو أضف موديل الجهاز'),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF0D253F)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
    );
  }

  Widget _buildBrandSearchField() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _selectedBrand),
      optionsBuilder: (value) {
        final query = value.text.trim();
        final brands = _brandsForSelection;
        if (query.isEmpty) return brands;

        final matches = brands
            .where((brand) => brand.toLowerCase().contains(query.toLowerCase()))
            .toList();
        if (!brands.any(
          (brand) => brand.toLowerCase() == query.toLowerCase(),
        )) {
          matches.add(query);
        }
        return matches;
      },
      onSelected: (brand) {
        setState(() {
          _selectedBrand = brand;
          if (!_brandsForSelection.any(
            (savedBrand) => savedBrand.toLowerCase() == brand.toLowerCase(),
          )) {
            _customBrands.add(brand);
          }
          _selectedModel = _modelsForSelectedBrand.isNotEmpty
              ? _modelsForSelectedBrand.first
              : '';
        });
        unawaited(_saveDraft());
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: options.map((brand) {
                  final isNewBrand = !_brandsForSelection.any(
                    (savedBrand) =>
                        savedBrand.toLowerCase() == brand.toLowerCase(),
                  );
                  return ListTile(
                    dense: true,
                    leading: _buildManufacturerLogo(
                      brand,
                      isNewBrand: isNewBrand,
                    ),
                    title: Text(
                      isNewBrand ? 'إضافة الشركة: $brand' : brand,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () => onSelected(brand),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: translateAppText('ابحث أو أضف الشركة المصنعة'),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF0D253F)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
    );
  }

  Widget _buildManufacturerLogo(String brand, {bool isNewBrand = false}) {
    final normalizedBrand = brand.trim().toLowerCase();
    final (IconData? icon, Color color) = switch (normalizedBrand) {
      'apple' => (SimpleIcons.apple, Colors.black),
      'samsung' => (SimpleIcons.samsung, const Color(0xFF1428A0)),
      'xiaomi' => (SimpleIcons.xiaomi, const Color(0xFFFF6900)),
      'huawei' => (SimpleIcons.huawei, const Color(0xFFC7000B)),
      'google' => (SimpleIcons.google, const Color(0xFF4285F4)),
      'honor' => (SimpleIcons.honor, const Color(0xFF000000)),
      'oneplus' => (SimpleIcons.oneplus, const Color(0xFFEB0029)),
      'oppo' => (SimpleIcons.oppo, const Color(0xFF1FAD5C)),
      'vivo' => (SimpleIcons.vivo, const Color(0xFF415FFF)),
      'motorola' => (SimpleIcons.motorola, const Color(0xFF000000)),
      'sony' => (SimpleIcons.sony, const Color(0xFF000000)),
      'nokia' => (SimpleIcons.nokia, const Color(0xFF124191)),
      _ => (null, const Color(0xFF527F90)),
    };

    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: isNewBrand
          ? Icon(Icons.add, size: 20, color: color)
          : icon != null
          ? Icon(icon, size: 21, color: color)
          : Text(
              brand.trim().isEmpty ? '?' : brand.trim()[0].toUpperCase(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
    );
  }

  Widget _buildDropdown(
    List<String> items,
    String currentVal,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(currentVal) ? currentVal : items.first,
      onChanged: onChanged,
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            ),
          )
          .toList(),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  void _showImeiHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'كيف تجد رقم IMEI ؟',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          '1. افتح تطبيق الهاتف واطلب الرمز: *#06# وسيظهر لك الرقم فوراً.\n\n2. تجد رقم IMEI مطبوعاً على العلبة الأصلية للجهاز.\n\n3. من الإعدادات: اذهب إلى (حول الهاتف).',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'حسناً',
              style: TextStyle(
                color: Color(0xFF0D253F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showScannerMockDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ماسح الـ IMEI والباركود'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, size: 70, color: Color(0xFF0D253F)),
            SizedBox(height: 10),
            Text('وجّه الكاميرا نحو باركود العلبة أو ظهر الجهاز'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D253F),
            ),
            onPressed: () {
              setState(() => _imeiController.text = '864920194857216');
              Navigator.pop(ctx);
            },
            child: const Text(
              'محاكاة مسح باركود سليم',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 28),
            SizedBox(width: 8),
            Text('تم التوثيق بنجاح!'),
          ],
        ),
        content: const Text(
          'تمت إضافة عقد البيع الإلكتروني بنجاح  وربطه بحساب المحل الخاص بك.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final String contractId =
                  'CNT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
              final String currentDate =
                  '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';

              await PdfContractService.generateAndShowContract(
                contractId: contractId,
                sellerName: 'محل معتمد',
                sellerId: '1000000000',
                buyerName: _nameController.text.trim(),
                buyerId: _idController.text.trim(),
                deviceModel: '$_selectedBrand $_selectedModel',
                imei: _imeiController.text.trim(),
                price: '${_priceController.text.trim()} ر.ي',
                date: currentDate,
              );
            },
            child: const Text(
              'طباعة العقد (PDF)',
              style: TextStyle(
                color: Color(0xFF0D253F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D253F),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              if (mounted) Navigator.of(context).pop();
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
