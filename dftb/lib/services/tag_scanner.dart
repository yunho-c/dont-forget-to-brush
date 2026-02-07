import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

import '../models/tag_models.dart';

class TagScanner {
  Future<NfcScanResult> scanNfcTag({
    Duration timeout = const Duration(seconds: 18),
  }) async {
    if (!_supportsNfcPlatform) {
      return NfcScanResult.unsupported(
        message: 'NFC scanning is only available on iOS/Android.',
      );
    }

    final availability = await _checkAvailability();
    if (availability != NfcAvailability.enabled) {
      if (availability == NfcAvailability.disabled) {
        return NfcScanResult.unavailable(
          message: 'NFC is disabled. Turn it on and retry.',
        );
      }
      return NfcScanResult.unsupported(
        message: 'This device does not support NFC.',
      );
    }

    final completer = Completer<NfcScanResult>();
    Timer? timeoutTimer;
    var sessionActive = false;

    Future<void> complete(
      NfcScanResult result, {
      String? iosErrorMessage,
    }) async {
      if (completer.isCompleted) return;
      timeoutTimer?.cancel();
      if (sessionActive) {
        try {
          await NfcManager.instance.stopSession(errorMessageIos: iosErrorMessage);
        } catch (_) {}
      }
      completer.complete(result);
    }

    try {
      await NfcManager.instance.startSession(
        pollingOptions: const {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        alertMessageIos: 'Hold near your bathroom tag',
        invalidateAfterFirstReadIos: false,
        onSessionErrorIos: (error) {
          if (error.code ==
              NfcReaderErrorCodeIos.readerSessionInvalidationErrorUserCanceled) {
            unawaited(
              complete(
                NfcScanResult.canceled(message: 'Scan canceled.'),
              ),
            );
            return;
          }
          if (error.code ==
              NfcReaderErrorCodeIos.readerSessionInvalidationErrorSessionTimeout) {
            unawaited(
              complete(
                NfcScanResult.timedOut(message: 'Timed out waiting for tag.'),
              ),
            );
            return;
          }
          unawaited(
            complete(
              NfcScanResult.error(message: error.message),
              iosErrorMessage: error.message,
            ),
          );
        },
        onDiscovered: (tag) async {
          final identifier = _extractIdentifier(tag);
          if (identifier == null || identifier.isEmpty) {
            await complete(
              NfcScanResult.error(
                message: 'Unable to read a tag identifier from this tag.',
              ),
              iosErrorMessage: 'Could not read this tag. Try another one.',
            );
            return;
          }
          await complete(
            NfcScanResult.found(identifier),
          );
        },
      );
      sessionActive = true;
    } on UnsupportedError {
      return NfcScanResult.unsupported(
        message: 'NFC scanning is not supported on this platform.',
      );
    } on PlatformException catch (error) {
      return NfcScanResult.error(message: error.message ?? 'NFC session failed.');
    } catch (error) {
      return NfcScanResult.error(message: 'NFC session failed: $error');
    }

    timeoutTimer = Timer(timeout, () {
      unawaited(
        complete(
          NfcScanResult.timedOut(message: 'Timed out waiting for tag.'),
          iosErrorMessage: 'Timed out waiting for tag.',
        ),
      );
    });

    return completer.future;
  }

  Future<NfcAvailability> _checkAvailability() async {
    try {
      return await NfcManager.instance.checkAvailability();
    } on UnsupportedError {
      return NfcAvailability.unsupported;
    } catch (_) {
      return NfcAvailability.unsupported;
    }
  }

  bool get _supportsNfcPlatform {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  String? _extractIdentifier(NfcTag tag) {
    final androidTag = NfcTagAndroid.from(tag);
    if (androidTag != null && androidTag.id.isNotEmpty) {
      return _toHex(androidTag.id);
    }

    final mifareTag = MiFareIos.from(tag);
    if (mifareTag != null && mifareTag.identifier.isNotEmpty) {
      return _toHex(mifareTag.identifier);
    }

    final iso15693Tag = Iso15693Ios.from(tag);
    if (iso15693Tag != null && iso15693Tag.identifier.isNotEmpty) {
      return _toHex(iso15693Tag.identifier);
    }

    final iso7816Tag = Iso7816Ios.from(tag);
    if (iso7816Tag != null && iso7816Tag.identifier.isNotEmpty) {
      return _toHex(iso7816Tag.identifier);
    }

    final felicaTag = FeliCaIos.from(tag);
    if (felicaTag != null && felicaTag.currentIDm.isNotEmpty) {
      return _toHex(felicaTag.currentIDm);
    }

    return null;
  }

  String _toHex(Uint8List bytes) {
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
