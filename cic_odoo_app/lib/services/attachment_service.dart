import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'app_permission_service.dart';
import 'odoo_service.dart';

class LocalDocument {
  const LocalDocument({
    required this.file,
    required this.name,
    required this.mimeType,
  });

  final File file;
  final String name;
  final String mimeType;
}

class PickedUploadFile {
  const PickedUploadFile({
    required this.name,
    required this.mimeType,
    required this.base64Data,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final String base64Data;
  final Uint8List bytes;
}

class AttachmentService {
  AttachmentService({OdooService? odoo}) : _odoo = odoo ?? OdooService();

  final OdooService _odoo;

  Future<PickedUploadFile?> pickAnyFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return null;
    return PickedUploadFile(
      name: file.name,
      mimeType: _inferMimeType(file.name),
      base64Data: base64Encode(bytes),
      bytes: bytes,
    );
  }

  Future<PickedUploadFile?> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return null;
    return PickedUploadFile(
      name: file.name,
      mimeType: 'application/pdf',
      base64Data: base64Encode(bytes),
      bytes: bytes,
    );
  }

  Future<LocalDocument> fetchAttachmentToCache({
    required int attachmentId,
    required String defaultName,
  }) async {
    await AppPermissionService.requestDownloads();
    final data = await _odoo.read(
      'ir.attachment',
      attachmentId,
      fields: const ['name', 'datas', 'mimetype'],
    );
    final name = (data['name'] ?? defaultName).toString();
    final mime = (data['mimetype'] ?? _inferMimeType(name)).toString();
    final raw = (data['datas'] ?? '').toString();
    if (raw.isEmpty) throw Exception('El adjunto no contiene datos.');
    final bytes = base64Decode(raw);
    final file = await _writeCacheFile(name: name, bytes: bytes);
    return LocalDocument(file: file, name: name, mimeType: mime);
  }

  Future<int> createAttachment({
    required String name,
    required String mimeType,
    required String base64Data,
    required String resModel,
    required int resId,
  }) async {
    return _odoo.create('ir.attachment', {
      'name': name,
      'mimetype': mimeType,
      'datas': base64Data,
      'res_model': resModel,
      'res_id': resId,
    });
  }

  Future<File> _writeCacheFile({
    required String name,
    required Uint8List bytes,
  }) async {
    final cleanName = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    try {
      final dir = await getTemporaryDirectory();
      await dir.create(recursive: true);
      final file = File('${dir.path}/$cleanName');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      final dir = await getApplicationDocumentsDirectory();
      await dir.create(recursive: true);
      final file = File('${dir.path}/$cleanName');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      return file;
    }
  }

  String _inferMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    return 'application/octet-stream';
  }
}
