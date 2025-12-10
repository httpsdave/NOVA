import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import 'package:html/parser.dart' as html_parser;

class PdfExportService {
  static final PdfExportService instance = PdfExportService._init();
  PdfExportService._init();

  /// Export a single note to PDF
  Future<File> exportNoteToPdf(Note note) async {
    final pdf = pw.Document();
    
    // Parse HTML content to plain text
    final content = _stripHtml(note.htmlContent);
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Title
          pw.Header(
            level: 0,
            child: pw.Text(
              note.title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          
          pw.SizedBox(height: 10),
          
          // Metadata
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(note.createdAt)}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                'Updated: ${DateFormat('MMM dd, yyyy HH:mm').format(note.updatedAt)}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          
          pw.SizedBox(height: 5),
          
          // Description
          if (note.description.isNotEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                note.description,
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey800,
                ),
              ),
            ),
          
          pw.SizedBox(height: 10),
          
          // Tags
          if (note.tags.isNotEmpty)
            pw.Wrap(
              spacing: 5,
              runSpacing: 5,
              children: note.tags.map((tag) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue100,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Text(
                    tag.trim(),
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.blue900,
                    ),
                  ),
                );
              }).toList(),
            ),
          
          pw.SizedBox(height: 20),
          
          // Divider
          pw.Divider(thickness: 1),
          
          pw.SizedBox(height: 20),
          
          // Content
          pw.Text(
            content,
            style: const pw.TextStyle(fontSize: 12),
            textAlign: pw.TextAlign.left,
          ),
          
          // Footer with page number
          pw.SizedBox(height: 20),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ),
      ),
    );
    
    // Save to Downloads folder
    final directory = await getExternalStorageDirectory();
    final downloadsPath = directory!.path.replaceAll('/Android/data/com.example.nova/files', '/Download');
    final downloadsDir = Directory(downloadsPath);
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    
    final fileName = '${note.title.replaceAll(RegExp(r'[^\w\s-]'), '')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${downloadsDir.path}/$fileName');
    
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Export multiple notes to a single PDF
  Future<File> exportMultipleNotesToPdf(List<Note> notes, String fileName) async {
    final pdf = pw.Document();
    
    for (var note in notes) {
      final content = _stripHtml(note.htmlContent);
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Title
            pw.Header(
              level: 0,
              child: pw.Text(
                note.title,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            
            pw.SizedBox(height: 10),
            
            // Metadata
            pw.Text(
              'Created: ${DateFormat('MMM dd, yyyy').format(note.createdAt)}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
            
            pw.SizedBox(height: 10),
            
            // Content
            pw.Text(
              content,
              style: const pw.TextStyle(fontSize: 11),
            ),
            
            pw.SizedBox(height: 20),
          ],
        ),
      );
    }
    
    // Save to Downloads folder
    final directory = await getExternalStorageDirectory();
    final downloadsPath = directory!.path.replaceAll('/Android/data/com.example.nova/files', '/Download');
    final downloadsDir = Directory(downloadsPath);
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    
    final file = File('${downloadsDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Share PDF directly (print dialog or share)
  Future<void> sharePdf(Note note) async {
    final pdf = pw.Document();
    final content = _stripHtml(note.htmlContent);
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              note.title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(content, style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
    
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${note.title}.pdf',
    );
  }

  /// Print PDF directly
  Future<void> printPdf(Note note) async {
    final content = _stripHtml(note.htmlContent);
    
    await Printing.layoutPdf(
      onLayout: (format) async {
        final pdf = pw.Document();
        
        pdf.addPage(
          pw.MultiPage(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(32),
            build: (context) => [
              pw.Header(
                level: 0,
                child: pw.Text(
                  note.title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(content, style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
        );
        
        return pdf.save();
      },
    );
  }

  /// Strip HTML tags from content
  String _stripHtml(String htmlString) {
    final document = html_parser.parse(htmlString);
    return document.body?.text ?? htmlString;
  }
}
