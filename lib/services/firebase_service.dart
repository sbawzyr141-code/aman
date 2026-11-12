import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================
  // 1. التحقق من اشتراك المستخدم (للأطراف كافة: محلات ومستخدمين)
  // ==========================================
  Future<bool> checkUserSubscription(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return true;

      final data = doc.data();
      if (data?['isSubscribed'] == false) return false;

      final expiryDate = data?['subscriptionExpiryDate'];
      if (expiryDate is Timestamp &&
          expiryDate.toDate().isBefore(DateTime.now())) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('خطأ في التحقق من الاشتراك: $e');
      return false;
    }
  }

  // ==========================================
  // 2. تسجيل عقد بيع هاتف جديد (يتطلب اشتراك مفعل)
  // ==========================================
  Future<Map<String, dynamic>> registerSaleContract({
    required String userId, // معرف المستخدم أو صاحب المحل المنفذ للعملية
    // بيانات البائع
    required String sellerName,
    required String sellerPhone,
    required String sellerIdNumber,
    required String sellerAddress,

    // بيانات المشتري
    required String buyerName,
    required String buyerPhone,
    required String buyerIdNumber,
    required String buyerAddress,

    // بيانات الجهاز
    required String deviceBrand,
    required String deviceModel,
    required String imei,
    required String deviceColor,
    required String storageSize,
    required String deviceCondition,
    required double price,

    // ملاحظات وصور (اختياري)
    String notes = '',
    String? invoiceImageUrl,
    String? idCardImageUrl,
  }) async {
    try {
      // 1. التحقق من اشتراك المستخدم إجبارياً
      bool isActiveSub = await checkUserSubscription(userId);
      if (!isActiveSub) {
        return {
          'success': false,
          'message': '❌ عذراً، اشتراكك منتهي أو غير مفعيل. يجب تجديد الاشتراك الشهري لإتمام توثيق العقود.'
        };
      }

      final cleanImei = imei.trim();

      await _db.collection('sales_contracts').add({
        'userId': userId,
        'seller': {
          'name': sellerName,
          'phone': sellerPhone,
          'idNumber': sellerIdNumber,
          'address': sellerAddress,
        },
        'buyer': {
          'name': buyerName,
          'phone': buyerPhone,
          'idNumber': buyerIdNumber,
          'address': buyerAddress,
        },
        'device': {
          'brand': deviceBrand,
          'model': deviceModel,
          'imei': cleanImei,
          'color': deviceColor,
          'storage': storageSize,
          'condition': deviceCondition,
          'price': price,
        },
        'notes': notes,
        'invoiceImageUrl': invoiceImageUrl ?? '',
        'idCardImageUrl': idCardImageUrl ?? '',
        'status': 'clean',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'تم تسجيل العقد بنجاح'};
    } catch (e) {
      debugPrint('خطأ أثناء حفظ عقد البيع: $e');
      return {'success': false, 'message': 'حدث خطأ تقني أثناء الحفظ: $e'};
    }
  }

  // ==========================================
  // 3. فحص حالة الهاتف بواسطة IMEI (متاح للجميع)
  // ==========================================
  Future<Map<String, dynamic>> checkImeiStatus(String imei) async {
    final cleanImei = imei.trim();

    try {
      final stolenQuery = await _db
          .collection('stolen_reports')
          .where('imei', isEqualTo: cleanImei)
          .where('status', isEqualTo: 'active')
          .get();

      if (stolenQuery.docs.isNotEmpty) {
        final data = stolenQuery.docs.first.data();
        return {
          'found': true,
          'isStolen': true,
          'statusText': '⚠️ تحذير: هذا الهاتف مسجل كمفقود أو مسروق!',
          'reportData': data,
        };
      }

      final salesQuery = await _db
          .collection('sales_contracts')
          .where('device.imei', isEqualTo: cleanImei)
          .orderBy('createdAt', descending: true)
          .get();

      if (salesQuery.docs.isNotEmpty) {
        final lastContract = salesQuery.docs.first.data();
        return {
          'found': true,
          'isStolen': false,
          'isRegistered': true,
          'statusText': '✅ الهاتف موثق ومسجل في قاعدة البيانات',
          'contractData': lastContract,
          'totalOwners': salesQuery.docs.length,
        };
      }

      return {
        'found': false,
        'isStolen': false,
        'isRegistered': false,
        'statusText': 'ℹ️ لا توجد بيانات مسجلة لهذا الرقم (IMEI) في النظام',
      };
    } catch (e) {
      debugPrint('خطأ في فحص IMEI: $e');
      return {
        'found': false,
        'error': true,
        'statusText': 'حدث خطأ أثناء الاتصال بقاعدة البيانات',
      };
    }
  }

  // ==========================================
  // 4. تقديم بلاغ عن هاتف مسروق / مفقود (يتطلب اشتراك)
  // ==========================================
  Future<bool> reportStolenPhone({
    required String userId,
    required String ownerName,
    required String ownerPhone,
    required String ownerIdNumber,
    required String imei,
    required String deviceModel,
    required String incidentCity,
    required String incidentDetails,
    String? policeReportNumber,
  }) async {
    try {
      // التحقق من اشتراك المستخدم قبل السماح برفع البلاغ
      bool isActiveSub = await checkUserSubscription(userId);
      if (!isActiveSub) return false;

      final cleanImei = imei.trim();

      await _db.collection('stolen_reports').add({
        'userId': userId,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,
        'ownerIdNumber': ownerIdNumber,
        'imei': cleanImei,
        'deviceModel': deviceModel,
        'incidentCity': incidentCity,
        'incidentDetails': incidentDetails,
        'policeReportNumber': policeReportNumber ?? '',
        'status': 'active',
        'reportedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('خطأ أثناء تقديم بلاغ السرقة: $e');
      return false;
    }
  }

  // ==========================================
  // 5. جلب عقود البيع وبلاغات السرقة (Streams)
  // ==========================================
  Stream<QuerySnapshot> getRegisteredSalesStream() {
    return _db.collection('sales_contracts').orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot> getStolenReportsStream() {
    return _db.collection('stolen_reports').orderBy('reportedAt', descending: true).snapshots();
  }

  // ==========================================
  // 6. تسجيل ملف المستخدم وصلاحياته واشتراكه
  // ==========================================
  Future<bool> saveUserProfile({
    required String uid,
    required String fullName,
    required String phone,
    required String role, // 'shop_owner' أو 'user'
    bool isSubscribed = true, // افتراضياً تفعيل اشتراك تجريبي عند الإنشاء
  }) async {
    try {
      DateTime expiryDate = DateTime.now().add(const Duration(days: 30)); // 30 يوماً اشتراك شهري

      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': fullName,
        'phone': phone,
        'role': role,
        'isSubscribed': isSubscribed,
        'subscriptionExpiryDate': Timestamp.fromDate(expiryDate),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('خطأ أثناء حفظ ملف المستخدم: $e');
      return false;
    }
  }

  // ==========================================
  // 7. جلب بيانات المستخدم
  // ==========================================
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('خطأ في جلب بيانات المستخدم: $e');
      return null;
    }
  }

  // ==========================================
  // 8. تحديث وتجديد الاشتراك الشهري (للأدمن أو بعد تأكيد التحويل)
  // ==========================================
  Future<bool> updateUserSubscription(String uid, bool subscribe) async {
    try {
      DateTime? expiryDate;
      if (subscribe) {
        expiryDate = DateTime.now().add(const Duration(days: 30)); // تمديد شهر كامل
      }

      await _db.collection('users').doc(uid).update({
        'isSubscribed': subscribe,
        'subscriptionExpiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate) : null,
      });

      return true;
    } catch (e) {
      debugPrint('خطأ في تحديث الاشتراك: $e');
      return false;
    }
  }

  // ==========================================
  // 9. تعديل وحذف عقود البيع
  // ==========================================
  Future<bool> updateSaleContract({
    required String contractId,
    required String buyerName,
    required String buyerPhone,
    required String buyerIdNumber,
    required String deviceBrand,
    required String deviceModel,
    required String imei,
    required double price,
  }) async {
    try {
      await _db.collection('sales_contracts').doc(contractId).update({
        'buyer.name': buyerName,
        'buyer.phone': buyerPhone,
        'buyer.idNumber': buyerIdNumber,
        'device.brand': deviceBrand,
        'device.model': deviceModel,
        'device.imei': imei.trim(),
        'device.price': price,
      });
      return true;
    } catch (e) {
      debugPrint('خطأ أثناء تعديل العقد: $e');
      return false;
    }
  }

  Future<bool> deleteSaleContract(String contractId) async {
    try {
      await _db.collection('sales_contracts').doc(contractId).delete();
      return true;
    } catch (e) {
      debugPrint('خطأ أثناء حذف العقد: $e');
      return false;
    }
  }
}