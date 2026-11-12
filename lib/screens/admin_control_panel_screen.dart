import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminControlPanelScreen extends StatefulWidget {
  const AdminControlPanelScreen({super.key});

  static bool isAdmin(User? user, Map<String, dynamic>? userData) {
    return user != null && userData?['isAdmin'] == true;
  }

  @override
  State<AdminControlPanelScreen> createState() =>
      _AdminControlPanelScreenState();
}

enum _AdminSection {
  overview,
  stores,
  users,
  alerts,
  sales,
  transfers,
  reports,
}

class _AdminControlPanelScreenState extends State<AdminControlPanelScreen> {
  static const Color _navy = Color(0xFF0D253F);
  static const Color _teal = Color(0xFF315F73);
  static const Color _muted = Color(0xFF718096);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  _AdminSection _section = _AdminSection.overview;
  late Future<List<int>> _overviewMetrics;

  @override
  void initState() {
    super.initState();
    _overviewMetrics = _fetchOverviewMetrics();
  }

  Future<List<int>> _fetchOverviewMetrics() async {
    final counts = await Future.wait([
      _firestore.collection('users').count().get(),
      _firestore
          .collection('users')
          .where('role', isEqualTo: 'shop_owner')
          .count()
          .get(),
      _firestore.collection('sales_contracts').count().get(),
      _firestore
          .collection('stolen_reports')
          .where('status', isEqualTo: 'active')
          .count()
          .get(),
      _firestore.collection('device_transfers').count().get(),
    ]);
    return counts.map((snapshot) => snapshot.count ?? 0).toList();
  }

  void _refreshOverview() {
    setState(() => _overviewMetrics = _fetchOverviewMetrics());
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('يلزم تسجيل الدخول للوصول إلى اللوحة.'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'تعذر التحقق من صلاحية الأدمن: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 16),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!AdminControlPanelScreen.isAdmin(user, snapshot.data!.data())) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'لا يملك هذا الحساب صلاحية الوصول إلى لوحة التحكم.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 16),
              ),
            ),
          );
        }

        return Column(
          children: [
            _buildHeader(),
            SizedBox(
              height: 58,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                children: _AdminSection.values.map(_buildSectionChip).toList(),
              ),
            ),
            Expanded(child: _buildSectionBody()),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, _teal],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.admin_panel_settings, color: Colors.white),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لوحة إدارة أمان',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'إدارة النظام والمستخدمين والعمليات',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.verified_user_outlined, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _buildSectionChip(_AdminSection section) {
    final selected = section == _section;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(_sectionLabel(section)),
        selected: selected,
        onSelected: (_) => setState(() => _section = section),
        selectedColor: const Color(0xFFDCEAF0),
        labelStyle: TextStyle(
          color: selected ? _navy : _muted,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  String _sectionLabel(_AdminSection section) => switch (section) {
    _AdminSection.overview => 'نظرة عامة',
    _AdminSection.stores => 'المتاجر',
    _AdminSection.users => 'المستخدمون والصلاحيات',
    _AdminSection.alerts => 'البلاغات والتنبيهات',
    _AdminSection.sales => 'عمليات البيع',
    _AdminSection.transfers => 'نقل الملكية',
    _AdminSection.reports => 'التقارير',
  };

  Widget _buildSectionBody() => switch (_section) {
    _AdminSection.overview => _buildOverview(),
    _AdminSection.stores => _buildUsers(storesOnly: true),
    _AdminSection.users => _buildUsers(storesOnly: false),
    _AdminSection.alerts => _buildAlerts(),
    _AdminSection.sales => _buildSales(),
    _AdminSection.transfers => _buildTransfers(),
    _AdminSection.reports => _buildReports(),
  };

  Widget _buildOverview() {
    return FutureBuilder<List<int>>(
      future: _overviewMetrics,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _errorPanel(snapshot.error!),
                TextButton.icon(
                  onPressed: _refreshOverview,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final counts = snapshot.data!;
        final metrics = [
          _Metric('المتاجر المسجلة', counts[1], Icons.storefront_outlined),
          _Metric('إجمالي المستخدمين', counts[0], Icons.people_outline),
          _Metric('عقود البيع', counts[2], Icons.point_of_sale_outlined),
          _Metric('بلاغات نشطة', counts[3], Icons.warning_amber_rounded),
          _Metric('نقل الملكية', counts[4], Icons.swap_horiz_rounded),
        ];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: IconButton(
                tooltip: 'تحديث الإحصاءات',
                onPressed: _refreshOverview,
                icon: const Icon(Icons.refresh, color: _teal),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 900
                    ? 3
                    : constraints.maxWidth > 540
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 10) / columns;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: metrics
                      .map(
                        (metric) =>
                            SizedBox(width: width, child: _metricCard(metric)),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            _panelCard(
              title: 'المهام السريعة',
              icon: Icons.flash_on_outlined,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _quickAction(
                    'مراجعة البلاغات',
                    Icons.warning_amber_rounded,
                    _AdminSection.alerts,
                  ),
                  _quickAction(
                    'إدارة المتاجر',
                    Icons.storefront_outlined,
                    _AdminSection.stores,
                  ),
                  _quickAction(
                    'إنشاء تقرير',
                    Icons.description_outlined,
                    _AdminSection.reports,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _metricCard(_Metric metric) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE5EBEF)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEAF2F5),
            child: Icon(metric.icon, color: _teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value.toString(),
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.bold,
                    fontSize: 21,
                  ),
                ),
                Text(
                  metric.label,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _quickAction(String label, IconData icon, _AdminSection section) {
    return OutlinedButton.icon(
      onPressed: () => setState(() => _section = section),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _buildUsers({required bool storesOnly}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .limit(200);
    if (storesOnly) {
      query = _firestore
          .collection('users')
          .where('role', isEqualTo: 'shop_owner')
          .limit(200);
    }
    return _queryList(
      query.snapshots(),
      (doc) => _accountCard(doc, storeMode: storesOnly),
      emptyMessage: storesOnly
          ? 'لا توجد متاجر مسجلة.'
          : 'لا يوجد مستخدمون مسجلون.',
    );
  }

  Widget _accountCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required bool storeMode,
  }) {
    final data = doc.data();
    final role = data['role'] == 'shop_owner' ? 'صاحب متجر' : 'مستخدم';
    final active = data['isActive'] != false;
    final subscribed = data['isSubscribed'] != false;
    final displayName =
        _string(data['storeName']) ??
        _string(data['fullName']) ??
        _string(data['name']) ??
        _string(data['email']) ??
        doc.id;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE5EBEF)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: active
              ? const Color(0xFFEAF2F5)
              : const Color(0xFFFFECEC),
          child: Icon(
            storeMode ? Icons.storefront_outlined : Icons.person_outline,
            color: active ? _teal : Colors.red,
          ),
        ),
        title: Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_string(data['email']) ?? '—'} • $role • '
          '${active ? 'نشط' : 'موقوف'}'
          '${storeMode ? ' • ${subscribed ? 'اشتراك فعال' : 'بلا اشتراك'}' : ''}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          tooltip: 'إدارة الحساب والصلاحيات',
          onPressed: () => _editAccount(doc),
          icon: const Icon(Icons.manage_accounts_outlined, color: _teal),
        ),
        onTap: () => _editAccount(doc),
      ),
    );
  }

  Future<void> _editAccount(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    var role = data['role'] == 'shop_owner' ? 'shop_owner' : 'user';
    var active = data['isActive'] != false;
    var subscribed = data['isSubscribed'] != false;
    var renewSubscription = false;
    final wasSubscribed = subscribed;
    final oldExpiryDate = data['subscriptionExpiryDate'];
    final oldPermissions = data['permissions'];
    final permissions = <String, bool>{
      'registerSales': _permissionValue(oldPermissions, 'registerSales', true),
      'submitReports': _permissionValue(oldPermissions, 'submitReports', true),
      'transferOwnership': _permissionValue(
        oldPermissions,
        'transferOwnership',
        true,
      ),
    };

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إدارة الحساب والصلاحيات'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _string(data['email']) ?? doc.id,
                    style: const TextStyle(color: _muted),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'نوع الحساب'),
                    items: const [
                      DropdownMenuItem(
                        value: 'shop_owner',
                        child: Text('صاحب متجر'),
                      ),
                      DropdownMenuItem(value: 'user', child: Text('مستخدم')),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => role = value);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('الحساب نشط'),
                    value: active,
                    onChanged: (value) => setDialogState(() => active = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('اشتراك المتجر فعال'),
                    value: subscribed,
                    onChanged: (value) =>
                        setDialogState(() => subscribed = value),
                  ),
                  if (subscribed)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('تجديد الاشتراك لمدة 30 يوماً'),
                      value: renewSubscription,
                      onChanged: (value) => setDialogState(
                        () => renewSubscription = value ?? false,
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  const Divider(),
                  const Text(
                    'الصلاحيات',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _permissionSwitch(
                    label: 'تسجيل عمليات البيع',
                    keyName: 'registerSales',
                    values: permissions,
                    setDialogState: setDialogState,
                  ),
                  _permissionSwitch(
                    label: 'تقديم البلاغات',
                    keyName: 'submitReports',
                    values: permissions,
                    setDialogState: setDialogState,
                  ),
                  _permissionSwitch(
                    label: 'نقل الملكية',
                    keyName: 'transferOwnership',
                    values: permissions,
                    setDialogState: setDialogState,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) return;

    final actor = FirebaseAuth.instance.currentUser!;
    final batch = _firestore.batch();
    batch.update(doc.reference, {
      'role': role,
      'isActive': active,
      'isSubscribed': subscribed,
      'subscriptionExpiryDate': !subscribed
          ? null
          : wasSubscribed && !renewSubscription
          ? oldExpiryDate
          : Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      'permissions': permissions,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final log = _firestore.collection('admin_audit_logs').doc();
    batch.set(log, {
      'actorUid': actor.uid,
      'actorEmail': actor.email,
      'action': 'update_user',
      'targetId': doc.id,
      'details': {
        'role': role,
        'isActive': active,
        'isSubscribed': subscribed,
        'permissions': permissions,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _runAdminAction(batch, 'تم تحديث الحساب والصلاحيات.');
  }

  Widget _permissionSwitch({
    required String label,
    required String keyName,
    required Map<String, bool> values,
    required StateSetter setDialogState,
  }) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: values[keyName],
      onChanged: (value) =>
          setDialogState(() => values[keyName] = value ?? false),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  bool _permissionValue(dynamic value, String key, bool defaultValue) {
    if (value is Map && value[key] is bool) return value[key] as bool;
    return defaultValue;
  }

  Widget _buildAlerts() => _queryList(
    _firestore
        .collection('stolen_reports')
        .orderBy('reportedAt', descending: true)
        .limit(200)
        .snapshots(),
    _alertCard,
    emptyMessage: 'لا توجد بلاغات.',
  );

  Widget _alertCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final status = _string(data['status']) ?? 'غير محدد';
    return _detailCard(
      icon: Icons.warning_amber_rounded,
      title: _string(data['deviceModel']) ?? 'بلاغ جهاز',
      subtitle:
          'IMEI: ${_string(data['imei']) ?? '—'} • الحالة: $status\n'
          'المالك: ${_string(data['ownerName']) ?? '—'} • '
          '${_formatDate(data['reportedAt'])}',
      details: [
        ('رقم الهاتف', _string(data['ownerPhone']) ?? '—'),
        ('المدينة', _string(data['incidentCity']) ?? '—'),
        ('تفاصيل البلاغ', _string(data['incidentDetails']) ?? '—'),
        ('رقم البلاغ الرسمي', _string(data['policeReportNumber']) ?? '—'),
      ],
      actions: [
        _statusAction(doc, 'active', 'مفتوح'),
        _statusAction(doc, 'resolved', 'تمت المراجعة'),
        _statusAction(doc, 'false_report', 'بلاغ غير صحيح'),
      ],
    );
  }

  Widget _statusAction(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String status,
    String label,
  ) {
    return TextButton(
      onPressed: () => _reviewAlert(doc, status),
      child: Text(label),
    );
  }

  Future<void> _reviewAlert(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String status,
  ) async {
    final actor = FirebaseAuth.instance.currentUser!;
    final batch = _firestore.batch();
    batch.update(doc.reference, {
      'status': status,
      'reviewedBy': actor.uid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    final log = _firestore.collection('admin_audit_logs').doc();
    batch.set(log, {
      'actorUid': actor.uid,
      'actorEmail': actor.email,
      'action': 'review_stolen_report',
      'targetId': doc.id,
      'details': {'status': status},
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _runAdminAction(batch, 'تم تحديث حالة البلاغ.');
  }

  Widget _buildSales() => _queryList(
    _firestore
        .collection('sales_contracts')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots(),
    _saleCard,
    emptyMessage: 'لا توجد عمليات بيع مسجلة.',
  );

  Widget _saleCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final device = _map(data['device']);
    final buyer = _map(data['buyer']);
    final seller = _map(data['seller']);
    return _detailCard(
      icon: Icons.point_of_sale_outlined,
      title:
          '${_string(device['brand']) ?? ''} ${_string(device['model']) ?? 'عقد بيع'}'
              .trim(),
      subtitle:
          'المشتري: ${_string(buyer['name']) ?? '—'} • '
          'IMEI: ${_string(device['imei']) ?? '—'}\n'
          'البائع: ${_string(seller['name']) ?? '—'} • '
          '${_formatDate(data['createdAt'])}',
      details: [
        ('هاتف المشتري', _string(buyer['phone']) ?? '—'),
        ('السعر', _string(device['price']) ?? '${device['price'] ?? '—'}'),
        ('معرف المتجر', _string(data['userId']) ?? '—'),
        ('الحالة', _string(data['status']) ?? '—'),
      ],
    );
  }

  Widget _buildTransfers() => _queryList(
    _firestore
        .collection('device_transfers')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots(),
    _transferCard,
    emptyMessage: 'لا توجد عمليات نقل ملكية.',
  );

  Widget _transferCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return _detailCard(
      icon: Icons.swap_horiz_rounded,
      title: _string(data['deviceModel']) ?? 'نقل ملكية جهاز',
      subtitle:
          'IMEI: ${_string(data['imei']) ?? '—'} • '
          '${_formatDate(data['createdAt'])}',
      details: [
        ('المالك السابق', _string(data['previousOwnerName']) ?? '—'),
        ('هوية المالك السابق', _string(data['previousOwnerId']) ?? '—'),
        ('المالك الجديد', _string(data['newOwnerName']) ?? '—'),
        ('هوية المالك الجديد', _string(data['newOwnerId']) ?? '—'),
        ('معرف المتجر', _string(data['shopId']) ?? '—'),
        ('مرجع العملية', _string(data['contractId']) ?? '—'),
      ],
    );
  }

  Widget _detailCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<(String, String)> details,
    List<Widget> actions = const [],
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE5EBEF)),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEAF2F5),
          child: Icon(icon, color: _teal),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle, maxLines: 3, overflow: TextOverflow.ellipsis),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          ...details.map(
            (detail) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      detail.$1,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      detail.$2,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (actions.isNotEmpty)
            Wrap(alignment: WrapAlignment.end, children: actions),
        ],
      ),
    );
  }

  Widget _buildReports() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _panelCard(
          title: 'تقارير النظام',
          icon: Icons.description_outlined,
          child: const Text(
            'إنشاء تقرير PDF يتضمن أعداد المتاجر والمستخدمين وعقود البيع '
            'والبلاغات ونقل الملكية، مع وقت إنشاء التقرير.',
            style: TextStyle(color: _muted, height: 1.6),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _generateReport,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('إنشاء وطباعة تقرير PDF'),
          style: FilledButton.styleFrom(
            backgroundColor: _navy,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        _panelCard(
          title: 'سجل إجراءات الإدارة',
          icon: Icons.history,
          child: _queryList(
            _firestore
                .collection('admin_audit_logs')
                .orderBy('createdAt', descending: true)
                .limit(30)
                .snapshots(),
            _auditCard,
            emptyMessage: 'لا توجد إجراءات مسجلة بعد.',
            embedded: true,
          ),
        ),
      ],
    );
  }

  Widget _auditCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return ListTile(
      dense: true,
      leading: const Icon(Icons.history, color: _teal),
      title: Text(_string(data['action']) ?? 'إجراء إداري'),
      subtitle: Text(
        '${_string(data['actorEmail']) ?? '—'} • '
        '${_formatDate(data['createdAt'])}',
      ),
    );
  }

  Future<void> _generateReport() async {
    try {
      final results = await Future.wait([
        _firestore.collection('users').count().get(),
        _firestore
            .collection('users')
            .where('role', isEqualTo: 'shop_owner')
            .count()
            .get(),
        _firestore.collection('sales_contracts').count().get(),
        _firestore
            .collection('stolen_reports')
            .where('status', isEqualTo: 'active')
            .count()
            .get(),
        _firestore.collection('device_transfers').count().get(),
      ]);
      final pdf = pw.Document();
      final now = DateTime.now();
      final metrics = [
        ('Registered stores', results[1].count ?? 0),
        ('All users', results[0].count ?? 0),
        ('Sales contracts', results[2].count ?? 0),
        ('Active theft reports', results[3].count ?? 0),
        ('Ownership transfers', results[4].count ?? 0),
      ];
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'AMAN SECURITY SYSTEM',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Administrative activity report'),
                pw.Text('Generated: ${now.toIso8601String()}'),
                pw.Divider(),
                ...metrics.map(
                  (metric) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(metric.$1),
                        pw.Text(
                          metric.$2.toString(),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.Spacer(),
                pw.Text(
                  'Confidential - for authorized system administration only',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await Printing.layoutPdf(
        name: 'aman_admin_report.pdf',
        onLayout: (_) => pdf.save(),
      );
    } catch (error) {
      _showMessage('تعذر إنشاء التقرير: $error', isError: true);
    }
  }

  Widget _queryList(
    Stream<QuerySnapshot<Map<String, dynamic>>> stream,
    Widget Function(QueryDocumentSnapshot<Map<String, dynamic>>) builder, {
    required String emptyMessage,
    bool embedded = false,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _errorPanel(snapshot.error!);
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(emptyMessage, style: const TextStyle(color: _muted)),
            ),
          );
        }
        if (embedded) {
          return Column(children: snapshot.data!.docs.map(builder).toList());
        }
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: snapshot.data!.docs.map(builder).toList(),
        );
      },
    );
  }

  Widget _panelCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5EBEF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _teal, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _errorPanel(Object error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'تعذر تحميل بيانات لوحة التحكم: $error',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red),
      ),
    ),
  );

  Future<void> _runAdminAction(WriteBatch batch, String successMessage) async {
    try {
      await batch.commit();
      if (mounted) _showMessage(successMessage);
    } catch (error) {
      if (mounted) _showMessage('فشل حفظ التغيير: $error', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : _teal,
      ),
    );
  }

  String? _string(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  String _formatDate(dynamic value) {
    DateTime? date;
    if (value is Timestamp) date = value.toDate();
    if (value is DateTime) date = value;
    if (date == null) return '—';
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);

  final String label;
  final int value;
  final IconData icon;
}
