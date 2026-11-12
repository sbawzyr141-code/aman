class DeviceRecord {
  final String imei;
  final String buyerName;
  final String buyerIdNumber;
  final String buyerPhone;
  final String buyerAddress;
  final String manufacturer;
  final String model;
  final String color;
  final String storageCapacity;
  final String deviceType;
  final String contractNumber;
  final String saleDate;
  final String status;

  DeviceRecord({
    required this.imei,
    required this.buyerName,
    required this.buyerIdNumber,
    required this.buyerPhone,
    required this.buyerAddress,
    required this.manufacturer,
    required this.model,
    required this.color,
    required this.storageCapacity,
    this.deviceType = 'هاتف ذكي',
    required this.contractNumber,
    required this.saleDate,
    this.status = 'موثّق وسليم',
  });
}