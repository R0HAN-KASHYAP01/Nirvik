import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart';

enum NgoFeedType { upload, liveLink }

class NgoCameraFeed {
  final String id;
  final NgoFeedType type;
  final String? label;
  final String? videoPath;
  final String? streamUrl;
  final DateTime createdAt;

  NgoCameraFeed({
    required this.id,
    required this.type,
    this.label,
    this.videoPath,
    this.streamUrl,
    required this.createdAt,
  });

  factory NgoCameraFeed.fromMap(Map<String, dynamic> map) {
    return NgoCameraFeed(
      id: map['id'] as String,
      type: (map['feed_type'] as String) == 'upload'
          ? NgoFeedType.upload
          : NgoFeedType.liveLink,
      label: map['label'] as String?,
      videoPath: map['video_path'] as String?,
      streamUrl: map['stream_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class NgoCameraService {
  NgoCameraService._();

  static final NgoCameraService instance = NgoCameraService._();

  final SupabaseClient _client = Supabase.instance.client;

  // ------------------------------------------------------------
  // ADD UPLOADED VIDEO
  // ------------------------------------------------------------

  Future<void> addUploadedVideo({
    required AppUser user,
    required String videoPath,
    String? label,
  }) async {
    final authUser = _client.auth.currentUser;

    debugPrint('========== CAMERA UPLOAD DEBUG ==========');
    debugPrint('Supabase Auth UID: ${authUser?.id}');
    debugPrint('AppUser ID: ${user.id}');
    debugPrint('Organization ID: ${user.organizationId}');
    debugPrint('Video Path: $videoPath');
    debugPrint('==========================================');

    try {
      await _client.from('ngo_camera_feeds').insert({
        'profile_id': user.id,
        'organization_id': user.organizationId,
        'feed_type': 'upload',
        'label': label,
        'video_path': videoPath,
      });

      debugPrint('CAMERA UPLOAD DB INSERT: SUCCESS');
    } on PostgrestException catch (e, stackTrace) {
      debugPrint('CAMERA UPLOAD DB INSERT: FAILED');
      debugPrint('Message: ${e.message}');
      debugPrint('Code: ${e.code}');
      debugPrint('Details: ${e.details}');
      debugPrint('Hint: ${e.hint}');
      debugPrint('StackTrace: $stackTrace');

      rethrow;
    } catch (e, stackTrace) {
      debugPrint('CAMERA UPLOAD INSERT UNKNOWN ERROR: $e');
      debugPrint('StackTrace: $stackTrace');

      rethrow;
    }
  }

  // ------------------------------------------------------------
  // ADD LIVE CAMERA LINK
  // ------------------------------------------------------------

  Future<void> addLiveLink({
    required AppUser user,
    required String streamUrl,
    String? label,
  }) async {
    final authUser = _client.auth.currentUser;

    debugPrint('========== CAMERA LIVE LINK DEBUG ==========');
    debugPrint('Supabase Auth UID: ${authUser?.id}');
    debugPrint('AppUser ID: ${user.id}');
    debugPrint('Organization ID: ${user.organizationId}');
    debugPrint('Stream URL: $streamUrl');
    debugPrint('Label: $label');
    debugPrint('============================================');

    try {
      await _client.from('ngo_camera_feeds').insert({
        'profile_id': user.id,
        'organization_id': user.organizationId,
        'feed_type': 'live_link',
        'label': label,
        'stream_url': streamUrl,
      });

      debugPrint('CAMERA LIVE LINK DB INSERT: SUCCESS');
    } on PostgrestException catch (e, stackTrace) {
      debugPrint('CAMERA LIVE LINK DB INSERT: FAILED');
      debugPrint('Message: ${e.message}');
      debugPrint('Code: ${e.code}');
      debugPrint('Details: ${e.details}');
      debugPrint('Hint: ${e.hint}');
      debugPrint('StackTrace: $stackTrace');

      rethrow;
    } catch (e, stackTrace) {
      debugPrint('CAMERA LIVE LINK INSERT UNKNOWN ERROR: $e');
      debugPrint('StackTrace: $stackTrace');

      rethrow;
    }
  }

  // ------------------------------------------------------------
  // UPDATE LIVE CAMERA LINK
  // ------------------------------------------------------------

  Future<void> updateLiveLink({
    required String feedId,
    required String streamUrl,
    String? label,
  }) async {
    final authUser = _client.auth.currentUser;

    if (authUser == null) {
      throw Exception('No authenticated user found.');
    }

    final cleanedUrl = streamUrl.trim();
    final cleanedLabel = label?.trim();

    if (cleanedUrl.isEmpty) {
      throw Exception('Camera stream URL cannot be empty.');
    }

    debugPrint('========== CAMERA LIVE LINK UPDATE ==========');
    debugPrint('Supabase Auth UID: ${authUser.id}');
    debugPrint('Feed ID: $feedId');
    debugPrint('New Stream URL: $cleanedUrl');
    debugPrint('New Label: $cleanedLabel');
    debugPrint('==============================================');

    try {
      final updatedRows = await _client
          .from('ngo_camera_feeds')
          .update({
            'stream_url': cleanedUrl,
            'label': cleanedLabel?.isEmpty == true ? null : cleanedLabel,
          })
          .eq('id', feedId)
          .eq('profile_id', authUser.id)
          .select('id, label, stream_url');

      if (updatedRows.isEmpty) {
        debugPrint(
          'CAMERA LIVE LINK UPDATE: NO ROW UPDATED',
        );

        throw Exception(
          'Camera could not be updated. '
          'The camera may not belong to the current NGO account, '
          'or Supabase Row Level Security may be blocking the update.',
        );
      }

      debugPrint('CAMERA LIVE LINK UPDATE: SUCCESS');
      debugPrint('Updated row: ${updatedRows.first}');
    } on PostgrestException catch (e, stackTrace) {
      debugPrint('CAMERA LIVE LINK UPDATE: FAILED');
      debugPrint('Message: ${e.message}');
      debugPrint('Code: ${e.code}');
      debugPrint('Details: ${e.details}');
      debugPrint('Hint: ${e.hint}');
      debugPrint('StackTrace: $stackTrace');

      rethrow;
    } catch (e, stackTrace) {
      debugPrint('CAMERA LIVE LINK UPDATE UNKNOWN ERROR: $e');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');

      rethrow;
    }
  }

  // ------------------------------------------------------------
  // DELETE CAMERA FEED
  // ------------------------------------------------------------

  Future<void> deleteFeed(String feedId) async {
    final authUser = _client.auth.currentUser;

    if (authUser == null) {
      throw Exception('No authenticated user found.');
    }

    debugPrint('========== CAMERA DELETE DEBUG ==========');
    debugPrint('Supabase Auth UID: ${authUser.id}');
    debugPrint('Feed ID: $feedId');
    debugPrint('==========================================');

    try {
      final deletedRows = await _client
          .from('ngo_camera_feeds')
          .delete()
          .eq('id', feedId)
          .eq('profile_id', authUser.id)
          .select('id');

      if (deletedRows.isEmpty) {
        debugPrint('CAMERA FEED DELETE: NO ROW DELETED');

        throw Exception(
          'Camera could not be deleted. '
          'The camera may not belong to the current NGO account '
          'or Supabase Row Level Security may be blocking the delete.',
        );
      }

      debugPrint('CAMERA FEED DELETE: SUCCESS');
      debugPrint('Deleted row: ${deletedRows.first}');
    } on PostgrestException catch (e, stackTrace) {
      debugPrint('CAMERA FEED DELETE: FAILED');
      debugPrint('Message: ${e.message}');
      debugPrint('Code: ${e.code}');
      debugPrint('Details: ${e.details}');
      debugPrint('Hint: ${e.hint}');
      debugPrint('StackTrace: $stackTrace');

      rethrow;
    } catch (e, stackTrace) {
      debugPrint('CAMERA FEED DELETE UNKNOWN ERROR: $e');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');

      rethrow;
    }
  }

  // ------------------------------------------------------------
  // FETCH CAMERA FEEDS
  // ------------------------------------------------------------

  Future<List<NgoCameraFeed>> fetchFeeds(String profileId) async {
    debugPrint('========== CAMERA FETCH DEBUG ==========');
    debugPrint('Requested Profile ID: $profileId');
    debugPrint(
      'Supabase Auth UID: ${_client.auth.currentUser?.id}',
    );
    debugPrint('=========================================');

    try {
      final rows = await _client
          .from('ngo_camera_feeds')
          .select()
          .eq('profile_id', profileId)
          .order('created_at', ascending: false);

      final feeds = (rows as List)
          .map(
            (r) => NgoCameraFeed.fromMap(
              r as Map<String, dynamic>,
            ),
          )
          .toList();

      debugPrint('Camera feeds fetched: ${feeds.length}');

      for (final feed in feeds) {
        debugPrint(
          'Camera: ${feed.label} | '
          'Type: ${feed.type} | '
          'URL: ${feed.streamUrl}',
        );
      }

      return feeds;
    } on PostgrestException catch (e, stackTrace) {
      debugPrint('CAMERA FETCH FAILED');
      debugPrint('Message: ${e.message}');
      debugPrint('Code: ${e.code}');
      debugPrint('Details: ${e.details}');
      debugPrint('Hint: ${e.hint}');
      debugPrint('StackTrace: $stackTrace');

      rethrow;
    } catch (e, stackTrace) {
      debugPrint('CAMERA FETCH UNKNOWN ERROR: $e');
      debugPrint('StackTrace: $stackTrace');

      rethrow;
    }
  }
}