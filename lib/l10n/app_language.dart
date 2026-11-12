import 'package:flutter/material.dart' as material;

class AppLanguage {
  AppLanguage._();

  static final material.ValueNotifier<material.Locale> locale =
      material.ValueNotifier(const material.Locale('en'));

  static void toggle() {
    locale.value = locale.value.languageCode == 'ar'
        ? const material.Locale('en')
        : const material.Locale('ar');
  }
}

String translateAppText(String value) {
  final language = AppLanguage.locale.value.languageCode;
  if (language == 'en') {
    final translation = _englishTranslations[value];
    if (translation != null) return translation;
    for (final entry in _englishPrefixes.entries) {
      if (value.startsWith(entry.key)) {
        return '${entry.value}${value.substring(entry.key.length)}';
      }
    }
    final ownerCount = RegExp(r'^(\d+) مرة$').firstMatch(value);
    if (ownerCount != null) return '${ownerCount.group(1)} times';
    final amount = RegExp(r'^(.+) ر\.ي$').firstMatch(value);
    if (amount != null) return 'YER ${amount.group(1)}';
    const transferSuccessPrefix =
        'تم توثيق عملية نقل ملكية الجهاز وحفظ السجل برقم مرجعي: ';
    if (value.startsWith(transferSuccessPrefix)) {
      final reference = value
          .substring(transferSuccessPrefix.length)
          .replaceFirst(' في قاعدة بيانات الفايربيس بنجاح.', '');
      return 'Device ownership transfer verified. Reference number: '
          '$reference. The record was saved to Firebase successfully.';
    }
    if (value.startsWith('بلاغ الشرطة: ')) {
      return 'Police report: ${value.substring('بلاغ الشرطة: '.length)}';
    }
    if (value.startsWith('تفاصيل العقد ')) {
      return 'Contract Details: ${value.substring('تفاصيل العقد '.length)}';
    }
    return value;
  }
  return _arabicTranslations[value] ?? value;
}

const Map<String, String> _englishPrefixes = {
  'تعذر جلب سجل الأجهزة: ': 'Could not load the device registry: ',
  'حدث خطأ أثناء تسجيل البلاغ: ': 'Error submitting the report: ',
  'حدث خطأ أثناء الحفظ سحابياً: ': 'Cloud save failed: ',
  'خطأ في الاتصال: ': 'Connection error: ',
  'خطأ في التحقق من الاشتراك: ': 'Subscription verification error: ',
  'خطأ في فحص IMEI: ': 'IMEI check error: ',
  'حدث خطأ تقني أثناء الحفظ: ': 'A technical error occurred while saving: ',
  'خطأ أثناء تعديل العقد: ': 'Error updating the contract: ',
  'خطأ أثناء تقديم بلاغ السرقة: ': 'Error submitting the theft report: ',
  'خطأ أثناء حذف العقد: ': 'Error deleting the contract: ',
  'خطأ أثناء حفظ عقد البيع: ': 'Error saving the sales contract: ',
  'خطأ أثناء حفظ ملف المستخدم: ': 'Error saving the user profile: ',
  'خطأ في تحديث الاشتراك: ': 'Subscription update error: ',
  'خطأ في جلب بيانات المستخدم: ': 'Error loading user data: ',
};

const Map<String, String> _arabicTranslations = {
  'Welcome': 'مرحباً',
  'Continue': 'متابعة',
  'Sign in': 'تسجيل الدخول',
  'Sign In': 'تسجيل الدخول',
  'Email': 'البريد الإلكتروني',
  'Password': 'كلمة المرور',
  'Enter your password': 'أدخل كلمة المرور',
  'enter your password': 'أدخل كلمة المرور',
  'Remember Me': 'تذكرني',
  'Forgot Password?': 'هل نسيت كلمة المرور؟',
  'Login': 'تسجيل الدخول',
  'Sign up': 'إنشاء حساب',
  'Create Account': 'إنشاء حساب',
  "Don't have an Account ? ": 'ليس لديك حساب؟ ',
  'AMAN SYSTEM': 'منظومة أمان',
  'demo@email.com': 'demo@email.com',
};

const Map<String, String> _englishTranslations = {
  'نظام حماية الهواتف': 'Phone Security System',
  'منظومة أمان لتأمين الهواتف وتوثيق عقود البيع الرسمية للمحلات التجارية ومنع سرقة الأجهزة.':
      'Aman helps secure phones, document official sales contracts, and prevent device theft.',
  'مرحباً بك في أ مــان': 'Welcome to Aman',
  'معاً نحو بيئة أكثر أماناً لتداول وشراء الهواتف.':
      'Together, we make buying and selling phones safer.',
  'حماية تثق بها': 'Protection you can trust',
  'الخدمات الرئيسية': 'Main Services',
  'خدمات أمان': 'Aman Services',
  'فحص هاتف': 'Check a Phone',
  'فحص الهاتف': 'Phone Check',
  'فحص جهاز': 'Check Device',
  'التحقق من حالة الهاتف': 'Check the phone status',
  'فحص الجهاز': 'Check Device',
  'تسجيل بيع': 'Register a Sale',
  'تسجيل عملية بيع جديدة': 'Register a new sale',
  'سجل الأجهزة': 'Device Registry',
  'الأجهزة': 'Devices',
  'الأجهزة المسجلة': 'Registered devices',
  'الإبلاغ عن جهاز مسروق': 'Report a stolen device',
  'خدمات إضافية': 'Additional Services',
  'نقل ملكية الهاتف': 'Transfer Device Ownership',
  'نقل ملكية الجهاز أو استبداله': 'Transfer or exchange device ownership',
  'إدارة العقود': 'Manage Contracts',
  'عرض وتعديل وحذف العقود': 'View, edit, and delete contracts',
  'نصيحة من أمان': 'Aman Tip',
  'لا تقم بشراء أي هاتف مستعمل قبل التحقق من رقمه التسلسلي وحالته عبر التطبيق لضمان حقوقك.':
      'Before buying a used phone, check its serial number and status in the app to protect yourself.',
  'الملف الشخصي': 'Profile',
  'التنبيهات والبلاغات': 'Alerts and Reports',
  'الرئيسية': 'Home',
  'أ مــان ': 'AMAN',
  'معاً ضد سرقة الهواتف': 'Together against phone theft',
  'فحص هاتف (IMEI)': 'Check Phone (IMEI)',
  'الإشعارات والتنبيهات': 'Notifications and Alerts',
  'أمانك يبدأ من التحقق': 'Your safety starts with verification',
  'حسابي': 'My Account',
  'التنبيهات': 'Alerts',
  'قائمة الأجهزة المحظورة والمبلغ عنها حديثاً لحماية أصحاب المحلات والمستعملين.':
      'Recently reported and blocked devices to help protect retailers and buyers.',
  'الأجهزة المبلغ عنها': 'Reported Devices',
  'حدث خطأ أثناء تحميل التنبيهات': 'Could not load alerts',
  'لا توجد تنبيهات جديدة': 'No new alerts',
  'ستظهر هنا الأجهزة المبلغ عنها حديثاً':
      'Recently reported devices will appear here',
  'جهاز غير معروف': 'Unknown Device',
  'غير مدخل': 'Not provided',
  'أدخل رقم IMEI أو الرقم التسلسلي ': 'Enter the IMEI or serial number',
  'أدخل من 10 إلى 15 خانة (IMEI / Serial)':
      'Enter 10 to 15 characters (IMEI / Serial)',
  'الرجاء إدخال رقم IMEI أو تسلسلي صحيح (بين 10 إلى 15 خانة)':
      'Enter a valid IMEI or serial number (10 to 15 characters)',
  'الهاتف مسروق ومبلغ عنه!': 'Phone reported stolen!',
  'تحذير: هذا الهاتف مسجل كمفقود أو مسروق!':
      'Warning: This phone is registered as lost or stolen!',
  'اسم المالك': 'Owner Name',
  'غير متوفر': 'Not available',
  'رقم هاتف المالك': 'Owner Phone',
  'مدينة الحادثة': 'Incident City',
  'غير متوفرة': 'Not available',
  'رقم بلاغ الشرطة': 'Police Report Number',
  'بدون رقم': 'None',
  'هاتف موثق ومرتبط بعقد رسمي': 'Verified phone linked to an official contract',
  'هذا الهاتف مسجل في عقود البيع الموثقة عبر المنظومة.':
      'This phone is registered in the platform’s verified sales contracts.',
  'ماركة وموديل الجهاز': 'Device Brand and Model',
  'اسم المالك الحالي': 'Current Owner',
  'عدد مرات تداول الجهاز': 'Number of Previous Owners',
  'الهاتف سليم تماماً': 'Phone is Clear',
  'لا توجد أي بلاغات سرقة أو عقود بيع مسجلة لهذا الرقم التسلسلي.':
      'No theft reports or sales contracts are registered for this serial number.',
  'رقم التسلسل / IMEI': 'Serial Number / IMEI',
  'سليم / غير مسروق': 'Clear / Not Stolen',
  'الحالة': 'Status',
  'ابحث برقم IMEI، اسم المشتري، أو الموديل...':
      'Search by IMEI, buyer name, or model...',
  'جهاز بدون اسم': 'Unnamed Device',
  'غ/م': 'N/A',
  'مؤخراً': 'Recently',
  'لا توجد أجهزة موثقة مطابقة': 'No matching verified devices',
  'تأكد من كتابة IMEI بشكل صحيح أو قم بتسجيل عملية بيع جديدة لإضافتها للسجل السحابي.':
      'Check the IMEI or register a new sale to add a device to the cloud registry.',
  'موثق ✅': 'Verified ✅',
  'موثّق وسليم': 'Verified and Clear',
  'الجهاز والموديل': 'Device and Model',
  'رقم الـ IMEI': 'IMEI Number',
  'السعة واللون': 'Storage and Color',
  'اسم المشتري': 'Buyer Name',
  'هاتف المشتري': 'Buyer Phone',
  'هوية المشتري': 'Buyer ID',
  'عنوان المشتري': 'Buyer Address',
  'تاريخ التوثيق': 'Verification Date',
  'إغلاق': 'Close',
  'البريد الإلكتروني': 'Email',
  'رقم الهاتف': 'Phone Number',
  'نوع الحساب': 'Account Type',
  'حسابك محمي': 'Your Account Is Protected',
  'بيانات حسابك مرتبطة بخدمات أمان السحابية':
      'Your account is connected to Aman cloud services',
  'تسجيل الخروج': 'Sign Out',
  'جاري التحميل...': 'Loading...',
  'صاحب محل': 'Shop Owner',
  'مستخدم': 'User',
  'محل معتمد': 'Verified Shop',
  'صاحب محل هواتف': 'Phone Shop Owner',
  'مستخدم عادي': 'Regular User',
  'محل تجاري': 'Business',
  'أمان — معاً ضد سرقة الهواتف': 'Aman — Together against phone theft',
  'تعديل عقد البيع': 'Edit Sales Contract',
  'قم بتحديث بيانات العقد': 'Update the contract details',
  'بيانات المشتري': 'Buyer Information',
  'رقم هاتف المشتري': 'Buyer Phone Number',
  'رقم هوية المشتري': 'Buyer ID Number',
  'بيانات الجهاز': 'Device Information',
  'ماركة الجهاز': 'Device Brand',
  'موديل الجهاز': 'Device Model',
  'الرقم التسلسلي IMEI': 'Serial Number (IMEI)',
  'السعر بالريال اليمني': 'Price in Yemeni Riyals',
  'إلغاء': 'Cancel',
  'يرجى إدخال سعر صحيح': 'Enter a valid price',
  'تم تعديل العقد بنجاح': 'Contract updated successfully',
  'فشل تعديل العقد': 'Could not update contract',
  'حفظ': 'Save',
  'حذف العقد؟': 'Delete Contract?',
  'هل أنت متأكد من حذف هذا العقد نهائياً من النظام؟ لا يمكن التراجع عن هذا الإجراء.':
      'Are you sure you want to permanently delete this contract? This cannot be undone.',
  'تم حذف العقد بنجاح': 'Contract deleted successfully',
  'فشل حذف العقد': 'Could not delete contract',
  'حذف نهائياً': 'Delete Permanently',
  'عقد بيع جهاز': 'Device Sales Contract',
  'مسجل': 'Registered',
  'قيمة العقد': 'Contract Value',
  'تعديل العقد': 'Edit Contract',
  'حذف العقد': 'Delete Contract',
  'عقود المحل': 'Shop Contracts',
  'إدارة ومتابعة عمليات البيع المسجلة': 'Manage and track registered sales',
  'جميع العقود': 'All Contracts',
  'حدث خطأ أثناء تحميل العقود': 'Could not load contracts',
  'لا توجد عقود مسجلة': 'No contracts registered',
  'ستظهر هنا عقود البيع الخاصة بمحلك':
      'Your shop’s sales contracts will appear here',
  'ماركة غير معروفة': 'Unknown Brand',
  'بدون اسم': 'Unnamed',
  'معلومات الحساب': 'Account Information',
  'مرحباً': 'Hello',
  'تم تسجيل عملية البيع بنجاح': 'Sale registered successfully',
  'البريد الإلكتروني أو كلمة المرور غير صحيحة.':
      'The email or password is incorrect.',
  'صيغة البريد الإلكتروني غير صحيحة.': 'The email address is invalid.',
  'الرجاء إدخال البريد الإلكتروني': 'Enter your email address',
  'بريد إلكتروني غير صالح': 'Invalid email address',
  'الرجاء إدخال رقم الهاتف': 'Enter your phone number',
  'الرجاء إدخال كلمة المرور': 'Enter your password',
  'كلمة المرور قصيرة جداً': 'Password is too short',
  'تم إرسال رابط استعادة كلمة المرور إلى بريدك':
      'A password reset link was sent to your email',
  'الرجاء كتابة البريد الإلكتروني أولاً': 'Enter your email address first',
  'حدث خطأ أثناء تسجيل الدخول': 'An error occurred while signing in',
  'حدث خطأ أثناء إنشاء الحساب': 'An error occurred while creating the account',
  'البريد الإلكتروني مستخدم مسبقاً لحساب آخر.':
      'This email is already in use by another account.',
  'كلمة المرور ضعيفة جداً.': 'The password is too weak.',
  'الرجاء إدخال بيانات المالك السابق، الجديد، وموديل ورقم الجهاز (IMEI / Serial)':
      'Enter the previous and new owner details, device model, and IMEI/serial number.',
  'يجب الموافقة على الإقرار القانوني بصحة نقل الملكية أولاً':
      'Accept the legal declaration to confirm the ownership transfer.',
  'رقم الهوية': 'ID Number',
  'كلمة المرور': 'Password',
  'تم تسجيل العقد بنجاح': 'Contract registered successfully',
  'حدث خطأ أثناء الاتصال بقاعدة البيانات':
      'A database connection error occurred',
  'عقد موثق ورسمي': 'Verified Official Contract',
  'أطراف العقد:': 'Contract Parties:',
  'الصفة': 'Role',
  'البائع': 'Seller',
  'المشتري': 'Buyer',
  'بيانات الهاتف المباع:': 'Sold Device Details:',
  'الإقرار والتعهد:': 'Declaration and Acknowledgment:',
  'توقيع البائع': 'Seller Signature',
  'توقيع المشتري': 'Buyer Signature',
  'مسروق': 'Stolen',
  'نظام حماية الهواتف الموحد': 'Unified Phone Security System',
  'وثيقة عقد بيع هاتف موثق إلكترونياً':
      'Electronic Verified Phone Sales Contract',
  'ℹ️ لا توجد بيانات مسجلة لهذا الرقم (IMEI) في النظام':
      'ℹ️ No information is registered for this IMEI in the system',
  '⚠️ تحذير: هذا الهاتف مسجل كمفقود أو مسروق!':
      '⚠️ Warning: This phone is registered as lost or stolen!',
  '✅ الهاتف موثق ومسجل في قاعدة البيانات':
      '✅ This phone is verified and registered in the database',
  '❌ عذراً، اشتراكك منتهي أو غير مفعيل. يجب تجديد الاشتراك الشهري لإتمام توثيق العقود.':
      '❌ Your subscription has expired or is inactive. Renew it to verify contracts.',
  'بلاغ سرقة عبر التطبيق': 'Theft report submitted through the app',
  'هاتف ذكي': 'Smartphone',
  'جهاز لوحي (تابلت)': 'Tablet',
  'ساعة ذكية': 'Smartwatch',
  'تيتانيوم طبيعي': 'Natural Titanium',
  'أسود': 'Black',
  'أبيض': 'White',
  'أزرق': 'Blue',
  'ذهبي': 'Gold',
  'رمادي': 'Gray',
  'المكلا': 'Mukalla',
  'مستعمل بحالة ممتازة': 'Used - Excellent Condition',
  'فشل توثيق العقد. تأكد من تفعيل الاشتراك الشهري.':
      'Contract verification failed. Check that your monthly subscription is active.',
  'تسجيل عملية بيع': 'Register Sale',
  'جاري التحقق من الاشتراك وتوثيق العقد سحابياً...':
      'Checking subscription and verifying the contract in the cloud...',
  'مراجعة وتأكيد': 'Review and Confirm',
  'الاسم الكامل': 'Full Name',
  'أدخل الاسم الكامل': 'Enter full name',
  'رقم الهوية / جواز السفر': 'ID Number / Passport',
  'أدخل رقم الهوية أو جواز السفر': 'Enter ID number or passport',
  'أدخل رقم الهاتف': 'Enter phone number',
  'العنوان': 'Address',
  'أدخل العنوان (المدينة / الحي)': 'Enter address (city / neighborhood)',
  'الرجاء إدخال الاسم، رقم الهوية ورقم الهاتف':
      'Enter the name, ID number, and phone number',
  'التالي': 'Next',
  'بيانات الجهاز المباع والسعر': 'Device and Sale Price',
  'الرقم التسلسلي (IMEI)': 'Serial Number (IMEI)',
  'أدخل الرقم التسلسلي (IMEI)': 'Enter serial number (IMEI)',
  'كيف تجد رقم IMEI ؟': 'How to find the IMEI',
  '1. افتح تطبيق الهاتف واطلب الرمز: *#06# وسيظهر لك الرقم فوراً.\n\n2. تجد رقم IMEI مطبوعاً على العلبة الأصلية للجهاز.\n\n3. من الإعدادات: اذهب إلى (حول الهاتف).':
      '1. Open the Phone app and dial *#06# to display the number.\n\n2. Find the IMEI printed on the device box.\n\n3. Go to Settings > About phone.',
  'نوع الجهاز': 'Device Type',
  'الشركة المصنعة': 'Manufacturer',
  'الموديل': 'Model',
  'اللون': 'Color',
  'سعة التخزين': 'Storage Capacity',
  'سعر البيع (ر.ي)': 'Sale Price (YER)',
  'أدخل مبلغ البيع': 'Enter sale amount',
  'السابق': 'Previous',
  'الرجاء إدخال الرقم التسلسلي IMEI': 'Enter the serial number (IMEI)',
  'مراجعة وتأكيد عملية البيع': 'Review and Confirm Sale',
  'ملخص عقد المبايعة الإلكتروني': 'Electronic Sales Contract Summary',
  'لم يحدد': 'Not specified',
  'الجهاز': 'Device',
  'رقم IMEI': 'IMEI Number',
  'السعر': 'Price',
  'أقر أنا بصحة كافة البيانات المذكورة وأن الهاتف غير خاضع لأي قيود جنائية أو بلاغات سرقة.':
      'I confirm that all information above is accurate and that the phone is not subject to legal restrictions or theft reports.',
  'تأكيد وإصدار العقد': 'Confirm and Issue Contract',
  'حسناً': 'OK',
  'ماسح الـ IMEI والباركود': 'IMEI and Barcode Scanner',
  'وجّه الكاميرا نحو باركود العلبة أو ظهر الجهاز':
      'Point the camera at the box barcode or the back of the device',
  'محاكاة مسح باركود سليم': 'Simulate a valid barcode scan',
  'تم التوثيق بنجاح!': 'Verified Successfully!',
  'تمت إضافة عقد البيع الإلكتروني بنجاح  وربطه بحساب المحل الخاص بك.':
      'The electronic sales contract was added and linked to your shop account.',
  'طباعة العقد (PDF)': 'Print Contract (PDF)',
  'إغلاق والعودة': 'Close and Return',
  'الإبلاغ عن سرقة': 'Report a Theft',
  'تم تسجيل البلاغ وحظر الهاتف في النظام بنجاح':
      'The report was submitted and the phone was blocked successfully',
  '❌ فشل تقديم البلاغ. تأكد من تفعيل اشتراكك أو الصلاحيات أولاً.':
      '❌ Report failed. Check that your subscription and permissions are active.',
  'سيتم تعميم رقم IMEI أو الرقم التسلسلي على مستوى الأنظمة والمحلات لمنع تداول الهاتف وحظره فوراً.':
      'The IMEI or serial number will be shared with participating systems and shops to block the phone and prevent its sale.',
  'الرقم التسلسلي أو IMEI *': 'Serial Number or IMEI *',
  'أدخل من 10 إلى 15 خانة': 'Enter 10 to 15 characters',
  'يرجى إدخال رقم الـ IMEI أو التسلسلي': 'Enter the IMEI or serial number',
  'رقم التسلسل غير صالح (يجب أن يكون بين 10 إلى 15 خانة)':
      'Invalid serial number (must be 10 to 15 characters)',
  'موديل الهاتف والشركة *': 'Phone Model and Brand *',
  'مثال: iPhone 15 Pro / Samsung S24': 'Example: iPhone 15 Pro / Samsung S24',
  'يرجى إدخال موديل الهاتف والشركة': 'Enter the phone model and brand',
  'رقم بلاغ الشرطة (إن وجد)': 'Police Report Number (if available)',
  'اسم المالك / الشاكي': 'Owner / Complainant Name',
  'رقم الهاتف للتواصل': 'Contact Phone Number',
  'تسجيل البلاغ وحظر الهاتف فوراً': 'Submit Report and Block Phone',
  'خدمة نقل الملكية (استبدال الأجهزة)': 'Ownership Transfer (Device Exchange)',
  'جاري توثيق وتثبيت عملية نقل الملكية سحابياً...':
      'Verifying the ownership transfer in the cloud...',
  'هذه الخدمة مخصصة لتوثيق تنازل أو استبدال الأجهزة المستعملة بين الأفراد لمنع تداول الأجهزة المسروقة.':
      'Document the transfer or exchange of used devices between individuals to prevent stolen devices from being sold.',
  'أولاً: بيانات المالك السابق (البائع أو المسلم للجهاز)':
      '1. Previous Owner (Seller or Transferor)',
  'الاسم الكامل للمالك السابق': 'Previous Owner Full Name',
  'رقم الهوية أو جواز السفر': 'ID Number or Passport',
  'ثانياً: بيانات المالك الجديد (المستلم)': '2. New Owner (Recipient)',
  'الاسم الكامل للمالك الجديد': 'New Owner Full Name',
  'رقم هاتف المالك الجديد': 'New Owner Phone Number',
  'رقم هوية المالك الجديد': 'New Owner ID Number',
  'ثالثاً: بيانات الجهاز الرقمية': '3. Device Details',
  'موديل الجهاز (مثال: iPhone 14 Pro / Samsung)':
      'Device Model (e.g., iPhone 14 Pro / Samsung)',
  'الرقم التسلسلي أو IMEI (من 10 إلى 15 خانة)':
      'Serial Number or IMEI (10 to 15 characters)',
  'مبلغ البيع أو الفارق (إن وجد)': 'Sale Price or Difference (if applicable)',
  'أقر أنا المسؤول عن المحل أو المنظومة بصحة بيانات الطرفين وأن الجهاز غير محظور أو مسروق.':
      'I confirm that both parties’ information is accurate and that the device is not blocked or stolen.',
  'إتمام وتوثيق نقل الملكية': 'Complete and Verify Ownership Transfer',
  'تم نقل الملكية بنجاح!': 'Ownership Transferred Successfully!',
  'Welcome': 'Welcome',
  'Continue': 'Continue',
  'Login': 'Sign In',
  'Sign up': 'Sign Up',
  'Remember Me': 'Remember Me',
  'Forgot Password?': 'Forgot Password?',
  'Password': 'Password',
  'enter your password': 'Enter your password',
  'demo@email.com': 'demo@email.com',
  'الاسم الكامل أو اسم المحل': 'Full name or shop name',
  'أدخل اسمك أو اسم محلك التجاري': 'Enter your name or shop name',
  'الرجاء إدخال الاسم': 'Enter your name',
  'أدخل رقم هاتفك': 'Enter your phone number',
  'أدخل كلمة مرور قوية': 'Enter a strong password',
  'كلمة المرور يجب أن تكون 6 أحرف على الأقل':
      'Password must be at least 6 characters',
  'صاحب محل هواتف / موثق عقود': 'Phone Shop Owner / Contract Verifier',
  'مستخدم عادي / فرد': 'Regular User / Individual',
  'جاري التحميل': 'Loading',
};

class Text extends material.StatelessWidget {
  const Text(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  final String data;
  final material.TextStyle? style;
  final material.StrutStyle? strutStyle;
  final material.TextAlign? textAlign;
  final material.TextDirection? textDirection;
  final material.Locale? locale;
  final bool? softWrap;
  final material.TextOverflow? overflow;
  final material.TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final material.TextWidthBasis? textWidthBasis;
  final material.TextHeightBehavior? textHeightBehavior;
  final material.Color? selectionColor;

  @override
  material.Widget build(material.BuildContext context) {
    material.Localizations.localeOf(context);
    return material.Text(
      translateAppText(data),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}

class LanguageSwitchButton extends material.StatelessWidget {
  const LanguageSwitchButton({super.key, this.foregroundColor});

  final material.Color? foregroundColor;

  @override
  material.Widget build(material.BuildContext context) {
    material.Localizations.localeOf(context);
    final isArabic = AppLanguage.locale.value.languageCode == 'ar';
    return material.TextButton.icon(
      onPressed: AppLanguage.toggle,
      icon: const material.Icon(material.Icons.language),
      label: material.Text(isArabic ? 'English' : 'العربية'),
      style: material.TextButton.styleFrom(
        foregroundColor: foregroundColor ?? const material.Color(0xFF315F73),
      ),
    );
  }
}
