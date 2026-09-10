import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'app_permission_service.dart';
import 'odoo_service.dart';
import 'portal_api_service.dart';

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
  /// Upper bound applied before a file is converted to Base64.
  ///
  /// Keeping this limit client-side prevents accidental memory spikes while
  /// still leaving the definitive limit to Odoo/server-side configuration.
  static const int maxFileBytes = 10 * 1024 * 1024;

  AttachmentService({OdooService? odoo}) : _odoo = odoo ?? OdooService();

  final OdooService _odoo;
  final PortalApiService _portalApi = PortalApiService();

  Future<PickedUploadFile?> pickAnyFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return null;
    _validateFile(
      name: file.name,
      mimeType: _inferMimeType(file.name),
      bytes: bytes,
    );
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
    _validateFile(name: file.name, mimeType: 'application/pdf', bytes: bytes);
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
    String? portalSection,
    int? portalRecordId,
    String? portalFieldName,
    bool forcePortal = false,
  }) async {
    final usePortal =
        portalSection != null &&
        portalRecordId != null &&
        (forcePortal || _odoo.isPortalSession);
    if (!forcePortal) await AppPermissionService.requestDownloads();
    final data = usePortal
        ? await _portalApi.attachment(
            section: portalSection,
            recordId: portalRecordId,
            attachmentId: attachmentId,
            fieldName: portalFieldName,
          )
        : await _odoo.read(
            'ir.attachment',
            attachmentId,
            fields: const ['name', 'datas', 'mimetype'],
          );
    final name = (data['name'] ?? defaultName).toString();
    final mime = (data['mimetype'] ?? _inferMimeType(name)).toString();
    final raw = (data['datas'] ?? '').toString();
    if (raw.isEmpty) throw Exception('El adjunto no contiene datos.');
    final bytes = base64Decode(raw);
    _validateFile(name: name, mimeType: mime, bytes: bytes);
    final file = await _writeCacheFile(
      name: name,
      bytes: bytes,
      temporaryOnly: forcePortal,
    );
    return LocalDocument(file: file, name: name, mimeType: mime);
  }

  Future<int> createAttachment({
    required String name,
    required String mimeType,
    required String base64Data,
    required String resModel,
    required int resId,
  }) async {
    final bytes = _decodeAndValidateBase64(
      name: name,
      mimeType: mimeType,
      base64Data: base64Data,
    );
    return _odoo.create('ir.attachment', {
      'name': name,
      'mimetype': mimeType,
      'datas': base64Encode(bytes),
      'res_model': resModel,
      'res_id': resId,
    });
  }

  Future<File> _writeCacheFile({
    required String name,
    required Uint8List bytes,
    bool temporaryOnly = false,
  }) async {
    final cleanName = sanitizeFileName(name);
    try {
      final dir = await getTemporaryDirectory();
      await dir.create(recursive: true);
      final file = File('${dir.path}/$cleanName');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      if (temporaryOnly) rethrow;
      final dir = await getApplicationDocumentsDirectory();
      await dir.create(recursive: true);
      final file = File('${dir.path}/$cleanName');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      return file;
    }
  }

  Future<File> writeBytesToDocuments({
    required String name,
    required Uint8List bytes,
    String? folderName,
  }) async {
    await AppPermissionService.requestDownloads();
    final cleanName = sanitizeFileName(name);
    final baseDir = await getApplicationDocumentsDirectory();
    final targetDir = folderName == null || folderName.trim().isEmpty
        ? baseDir
        : Directory('${baseDir.path}/${sanitizeFileName(folderName)}');
    await targetDir.create(recursive: true);
    final file = File('${targetDir.path}/$cleanName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> writeBytesToTemporary({
    required String name,
    required Uint8List bytes,
    String? folderName,
  }) async {
    final cleanName = sanitizeFileName(name);
    final baseDir = await getTemporaryDirectory();
    final targetDir = folderName == null || folderName.trim().isEmpty
        ? baseDir
        : Directory('${baseDir.path}/${sanitizeFileName(folderName)}');
    await targetDir.create(recursive: true);
    final file = File('${targetDir.path}/$cleanName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static String sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  /// Validates a payload before handing it to an Odoo attachment endpoint.
  static void validateUpload({
    required String name,
    required String mimeType,
    required Uint8List bytes,
  }) => _validateFile(name: name, mimeType: mimeType, bytes: bytes);

  static Uint8List _decodeAndValidateBase64({
    required String name,
    required String mimeType,
    required String base64Data,
  }) {
    try {
      final bytes = Uint8List.fromList(base64Decode(base64Data));
      _validateFile(name: name, mimeType: mimeType, bytes: bytes);
      return bytes;
    } on FormatException {
      throw ArgumentError.value(base64Data, 'base64Data', 'Base64 no válido.');
    }
  }

  static void _validateFile({
    required String name,
    required String mimeType,
    required Uint8List bytes,
  }) {
    if (bytes.isEmpty) {
      throw ArgumentError.value(name, 'name', 'El archivo está vacío.');
    }
    if (bytes.length > maxFileBytes) {
      throw ArgumentError.value(
        name,
        'name',
        'El archivo supera el límite de 10 MB.',
      );
    }
    final extension = _extension(name);
    final expectedMime = _mimeByExtension[extension];
    final normalizedMime = mimeType.trim().toLowerCase();
    if (expectedMime != null && normalizedMime != expectedMime) {
      throw ArgumentError.value(
        mimeType,
        'mimeType',
        'El MIME no coincide con la extensión .$extension.',
      );
    }
    if (normalizedMime == 'application/x-msdownload' ||
        normalizedMime == 'application/x-sh' ||
        const {
          'exe',
          'dll',
          'bat',
          'cmd',
          'sh',
          'js',
          'html',
          'htm',
        }.contains(extension)) {
      throw ArgumentError.value(name, 'name', 'Tipo de archivo no permitido.');
    }
  }

  static String _extension(String name) {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  static const _mimeByExtension = <String, String>{
    'pdf': 'application/pdf',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  };

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
