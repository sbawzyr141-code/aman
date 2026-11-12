import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_language.dart';
import '../services/form_draft_storage.dart';

class DeviceRegistryScreen extends StatefulWidget {
  const DeviceRegistryScreen({super.key});

  @override
  State<DeviceRegistryScreen> createState() => _DeviceRegistryScreenState();
}

class _DeviceRegistryScreenState extends State<DeviceRegistryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final draft = await FormDraftStorage.load('device_registry');
    if (!mounted) return;
    final query = draft['search'] as String? ?? '';
    _searchController.text = query;
    setState(() => _searchQuery = query.trim().toLowerCase());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        // شريط البحث العلوي
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim().toLowerCase();
              });
              unawaited(
                FormDraftStorage.save('device_registry', {'search': val}),
              );
            },
            decoration: InputDecoration(
              hintText: translateAppText(
                'ابحث برقم IMEI، اسم المشتري، أو الموديل...',
              ),
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF0D253F)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        unawaited(FormDraftStorage.clear('device_registry'));
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF0D253F),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // قائمة الأجهزة المسجلة في Firestore
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: currentUserId == null
                ? Stream<QuerySnapshot<Map<String, dynamic>>>.error(
                    StateError('No signed-in user is available.'),
                  )
                : FirebaseFirestore.instance
                      .collection('sales_contracts')
                      .where('userId', isEqualTo: currentUserId)
                      .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0D253F)),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Text('تعذر جلب سجل الأجهزة: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final docs = snapshot.data?.docs.toList() ?? [];
              docs.sort((first, second) {
                final firstCreatedAt = first.data()['createdAt'];
                final secondCreatedAt = second.data()['createdAt'];
                if (firstCreatedAt is! Timestamp) {
                  return secondCreatedAt is! Timestamp ? 0 : 1;
                }
                if (secondCreatedAt is! Timestamp) return -1;
                return secondCreatedAt.compareTo(firstCreatedAt);
              });

              // تصفية البيانات بحسب نص البحث
              final filteredDocs = docs.where((doc) {
                final data = doc.data();
                final device = data['device'] ?? {};
                final buyer = data['buyer'] ?? {};

                final imei = (device['imei'] ?? '').toString().toLowerCase();
                final buyerName = (buyer['name'] ?? '')
                    .toString()
                    .toLowerCase();
                final brand = (device['brand'] ?? '').toString().toLowerCase();
                final model = (device['model'] ?? '').toString().toLowerCase();
                final contractNo = (data['contractNumber'] ?? '')
                    .toString()
                    .toLowerCase();

                return imei.contains(_searchQuery) ||
                    buyerName.contains(_searchQuery) ||
                    brand.contains(_searchQuery) ||
                    model.contains(_searchQuery) ||
                    contractNo.contains(_searchQuery);
              }).toList();

              if (filteredDocs.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredDocs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = filteredDocs[index].data();
                  final docId = filteredDocs[index].id;

                  final device = data['device'] ?? {};
                  final buyer = data['buyer'] ?? {};

                  final String contractNo =
                      data['contractNumber'] ??
                      '#${docId.substring(0, 8).toUpperCase()}';
                  final String brand = device['brand'] ?? '';
                  final String model = device['model'] ?? 'جهاز بدون اسم';
                  final String storage = device['storage'] ?? '';
                  final String color = device['color'] ?? '';
                  final String imei = device['imei'] ?? 'غ/م';
                  final String buyerName = buyer['name'] ?? 'غ/م';
                  final String buyerPhone = buyer['phone'] ?? '';

                  // تنسيق التاريخ
                  String formattedDate = 'مؤخراً';
                  if (data['createdAt'] != null &&
                      data['createdAt'] is Timestamp) {
                    final DateTime dt = (data['createdAt'] as Timestamp)
                        .toDate();
                    formattedDate =
                        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showContractDetailsBottomSheet(
                      context,
                      data,
                      contractNo,
                      formattedDate,
                    ),
                    child: _buildDeviceCard(
                      contractNo: contractNo,
                      name: '$brand $model'.trim(),
                      details: '$storage - $color'.trim().replaceAll(
                        RegExp(r'^ - | - $'),
                        '',
                      ),
                      imei: imei,
                      buyer: buyerName,
                      buyerPhone: buyerPhone,
                      date: formattedDate,
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

  Widget _buildDeviceCard({
    required String contractNo,
    required String name,
    required String details,
    required String imei,
    required String buyer,
    required String buyerPhone,
    required String date,
  }) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: 12,
                        color: Color(0xFF16A34A),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'موثّق وسليم',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  contractNo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D253F),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                details,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'IMEI: $imei',
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          buyer,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.devices_other,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد أجهزة موثقة مطابقة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'تأكد من كتابة IMEI بشكل صحيح أو قم بتسجيل عملية بيع جديدة لإضافتها للسجل السحابي.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContractDetailsBottomSheet(
    BuildContext context,
    Map<String, dynamic> data,
    String contractNo,
    String date,
  ) {
    final device = data['device'] ?? {};
    final buyer = data['buyer'] ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تفاصيل العقد $contractNo',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D253F),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'موثق ✅',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _detailRow(
                'الجهاز والموديل',
                '${device['brand'] ?? ''} ${device['model'] ?? ''}',
              ),
              _detailRow('رقم الـ IMEI', device['imei'] ?? 'غ/م'),
              _detailRow(
                'السعة واللون',
                '${device['storage'] ?? ''} - ${device['color'] ?? ''}',
              ),
              const Divider(height: 20),
              _detailRow('اسم المشتري', buyer['name'] ?? 'غ/م'),
              _detailRow('هاتف المشتري', buyer['phone'] ?? 'غ/م'),
              _detailRow('هوية المشتري', buyer['idNumber'] ?? 'غ/م'),
              _detailRow('عنوان المشتري', buyer['address'] ?? 'غ/م'),
              const Divider(height: 20),
              _detailRow('تاريخ التوثيق', date),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D253F),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'إغلاق',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
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
}
