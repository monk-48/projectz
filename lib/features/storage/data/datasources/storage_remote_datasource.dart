import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exception_handler.dart';

abstract class StorageRemoteDataSource {
  Future<String> uploadImage(Uint8List imageBytes, String fileName, String bucket);
  Future<String> getImageUrl(String fileName, String bucket);
  Future<void> deleteImage(String fileName, String bucket);
}

class StorageRemoteDataSourceImpl implements StorageRemoteDataSource {
  final SupabaseClient supabaseClient;

  StorageRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<String> uploadImage(Uint8List imageBytes, String fileName, String bucket) async {
    try {
      await supabaseClient.storage
          .from(bucket)
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: FileOptions(
              contentType: 'image/${fileName.split('.').last}',
              upsert: true,
            ),
          );

      return getImageUrl(fileName, bucket);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<String> getImageUrl(String fileName, String bucket) async {
    try {
      return supabaseClient.storage
          .from(bucket)
          .getPublicUrl(fileName);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> deleteImage(String fileName, String bucket) async {
    try {
      await supabaseClient.storage
          .from(bucket)
          .remove([fileName]);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }
}

