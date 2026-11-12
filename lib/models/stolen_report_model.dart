class StolenReport {
  final String imei;
  final String reportNumber;
  final String reportDate;
  final String model;
  final String status;

  StolenReport({
    required this.imei,
    required this.reportNumber,
    required this.reportDate,
    required this.model,
    this.status = 'مسروق',
  });
}