import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfContractService {
  /// توليد ومعاينة وطباعة عقد البيع الموثق.
  ///
  /// يجب إضافة الخطين إلى المشروع في المسارين التاليين:
  /// assets/fonts/NotoSansArabic-Regular.ttf
  /// assets/fonts/NotoSansArabic-Bold.ttf
  static Future<void> generateAndShowContract({
    required String contractId,
    required String sellerName,
    required String sellerId,
    required String buyerName,
    required String buyerId,
    required String deviceModel,
    required String imei,
    required String price,
    required String date,
  }) async {
    final pw.Document pdf = pw.Document();

    // تحميل الخط العربي من ملفات التطبيق بدل تحميله من الإنترنت.
    // هذا يمنع ظهور الحروف العربية كمربعات عند الطباعة أو التصدير.
    // تحميل خطوط Beiruti العربية
    final ByteData regularFontData = await rootBundle.load(
      'assets/fonts/Beiruti-Regular.ttf',
    );

    final ByteData boldFontData = await rootBundle.load(
      'assets/fonts/Beiruti-Bold.ttf',
    );

    final pw.Font arabicRegularFont =
    pw.Font.ttf(regularFontData);

    final pw.Font arabicBoldFont =
    pw.Font.ttf(boldFontData);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: arabicRegularFont,
          bold: arabicBoldFont,
        ),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // ترويسة العقد
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'نظام حماية الهواتف الموحد',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.Text(
                            'وثيقة عقد بيع هاتف موثق إلكترونياً',
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green100,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(color: PdfColors.green700),
                        ),
                        child: pw.Text(
                          'عقد موثق ورسمي',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.green900,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.Divider(
                    thickness: 1.5,
                    color: PdfColors.blue900,
                    height: 24,
                  ),

                  // رقم العقد والتاريخ
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'رقم العقد: $contractId',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      pw.Text(
                        'تاريخ التوثيق: $date',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),

                  // بيانات أطراف العقد
                  pw.Text(
                    'أطراف العقد:',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColors.grey400,
                      width: 0.5,
                    ),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey200,
                        ),
                        children: [
                          _tableCell('الصفة', isHeader: true),
                          _tableCell('الاسم الكامل', isHeader: true),
                          _tableCell('رقم الهوية', isHeader: true),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          _tableCell('البائع'),
                          _tableCell(sellerName),
                          _tableCell(sellerId),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          _tableCell('المشتري'),
                          _tableCell(buyerName),
                          _tableCell(buyerId),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),

                  // بيانات الهاتف
                  pw.Text(
                    'بيانات الهاتف المباع:',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('• موديل الجهاز: $deviceModel'),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '• الرقم التسلسلي (IMEI): $imei',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('• مبلغ البيع: $price'),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // الإقرار
                  pw.Text(
                    'الإقرار والتعهد:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'يقر البائع بأن الهاتف الموضح أعلاه ملك خالص له وغير مسروق أو محظور، وتحت مسؤوليته الكاملة. '
                        'كما يقر المشتري بمعاينة الجهاز واستلامه وتوثيقه رسمياً في المنظومة.',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),

                  pw.Spacer(),

                  // التوقيعات ورمز QR
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text(
                            'توقيع البائع',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 25),
                          pw.Text('.............................'),
                        ],
                      ),
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: 'CONTRACT:$contractId|IMEI:$imei',
                        width: 55,
                        height: 55,
                      ),
                      pw.Column(
                        children: [
                          pw.Text(
                            'توقيع المشتري',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 25),
                          pw.Text('.............................'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // معاينة وتصدير وطباعة المستند.
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'عقد_بيع_$imei.pdf',
    );
  }

  /// خلية موحدة لجدول بيانات البائع والمشتري.
  static pw.Widget _tableCell(
      String text, {
        bool isHeader = false,
      }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
