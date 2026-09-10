import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:cic_odoo_app/services/attachment_service.dart';

void main() {
  test('accepts a matching PDF upload', () {
    expect(
      () => AttachmentService.validateUpload(
        name: 'informe.pdf',
        mimeType: 'application/pdf',
        bytes: Uint8List.fromList(const [37, 80, 68, 70]),
      ),
      returnsNormally,
    );
  });

  test('rejects a MIME/extension mismatch and executable types', () {
    expect(
      () => AttachmentService.validateUpload(
        name: 'informe.pdf',
        mimeType: 'text/plain',
        bytes: Uint8List.fromList(const [1]),
      ),
      throwsArgumentError,
    );
    expect(
      () => AttachmentService.validateUpload(
        name: 'script.js',
        mimeType: 'application/javascript',
        bytes: Uint8List.fromList(const [1]),
      ),
      throwsArgumentError,
    );
  });

  test('rejects payloads over the client-side limit', () {
    expect(
      () => AttachmentService.validateUpload(
        name: 'large.bin',
        mimeType: 'application/octet-stream',
        bytes: Uint8List(AttachmentService.maxFileBytes + 1),
      ),
      throwsArgumentError,
    );
  });
}
