import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_feed/stream_feed.dart';
import 'package:stream_feed_flutter_core/src/upload/states.dart';

extension MapUpsert<K, V> on Map<K, V> {
  Map<K, V> upsert(K key, V value) {
    return this..update(key, (_) => value, ifAbsent: () => value);
  }
}

class UploadController {
  UploadController(this.client);
  late Map<AttachmentFile, CancelToken> cancelMap = {};
  final StreamFeedClient client;

  @visibleForTesting
  late BehaviorSubject<Map<AttachmentFile, UploadState>> stateMap =
      BehaviorSubject.seeded({});

  Stream<Map<AttachmentFile, UploadState>> get uploadsStream => stateMap.stream;


  void close() {
    stateMap.close();
  }

  void cancelUpload(AttachmentFile attachmentFile) {
    final token = cancelMap[attachmentFile];
    token!.cancel('cancelled');
  }

  Future<void> uploadFiles(List<AttachmentFile> attachmentFiles) async {
    await Future.wait(attachmentFiles.map(uploadFile));
  }

  Future<void> uploadFile(AttachmentFile attachmentFile,
      [CancelToken? cancelToken]) async {
    _initController(attachmentFile, cancelToken);

    try {
      final url = await client.images
          .upload(attachmentFile, cancelToken: cancelMap[attachmentFile],
              onSendProgress: (sentBytes, totalBytes) {
        final newState = stateMap.value.upsert(attachmentFile,
            UploadProgress(sentBytes: sentBytes, totalBytes: totalBytes));
        stateMap.add(newState);
        print(newState);
      });
      final newState = stateMap.value.upsert(
        attachmentFile,
        UploadSuccess(url!),
      ); //TODO: deal url null;
      stateMap.add(newState);
    } catch (e) {
      if (e is SocketException) {
        final newState = stateMap.value.upsert(attachmentFile, UploadFailed(e));
        stateMap.add(newState);
      }

      if (e is DioError && CancelToken.isCancel(e)) {
        final newState =
            stateMap.value.upsert(attachmentFile, UploadCancelled());
        stateMap.add(newState);
      }
    }
  }

  // UploadState _getController(
  //   AttachmentFile attachmentFile,
  // ) =>
  //     stateMap.value[attachmentFile]!;

  void _initController(AttachmentFile attachmentFile,
      [CancelToken? cancelToken]) {
    stateMap.value.upsert(attachmentFile, UploadEmptyState());
    cancelMap[attachmentFile] = cancelToken ?? CancelToken();
  }

  /// Remove upload from controller
  void removeUpload(AttachmentFile file) {
    final newMap = stateMap.value..removeWhere((key, value) => key == file);
    stateMap.add(newMap);
  }

  /// Get urls
  List<String> getUrls() {
    final successes = stateMap.value.values
        .map((state) => state)
        .toList()
        .whereType<UploadSuccess>();
    final urls = successes.map((success) => success.url).toList();
    return urls;
  }
}
