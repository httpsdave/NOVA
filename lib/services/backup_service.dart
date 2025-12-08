import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class BackupService {
  static final BackupService instance = BackupService._init();
  
  BackupService._init();

  /// Creates a complete backup of all app data
  /// Returns the path to the backup ZIP file
  Future<String?> createBackup() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupName = 'nova_backup_$timestamp.zip';
      
      // Get directories
      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();
      final downloadsDir = Directory('/storage/emulated/0/Download');
      
      // Create temp backup directory
      final tempBackupDir = Directory(path.join(tempDir.path, 'nova_backup_$timestamp'));
      if (await tempBackupDir.exists()) {
        await tempBackupDir.delete(recursive: true);
      }
      await tempBackupDir.create(recursive: true);

      // 1. Copy database file
      final db = await DatabaseService.instance.database;
      final dbPath = db.path;
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        final dbBackupPath = path.join(tempBackupDir.path, 'nova.db');
        await dbFile.copy(dbBackupPath);
      }

      // 2. Copy all attachments (images, audio, drawings)
      final attachmentsDir = Directory(path.join(appDir.path, 'nova_attachments'));
      if (await attachmentsDir.exists()) {
        final attachmentsBackupDir = Directory(path.join(tempBackupDir.path, 'nova_attachments'));
        await attachmentsBackupDir.create(recursive: true);
        await _copyDirectory(attachmentsDir, attachmentsBackupDir);
      }

      // 3. Copy all HTML note files
      final notesDir = Directory(path.join(appDir.path, 'nova_notes'));
      if (await notesDir.exists()) {
        final notesBackupDir = Directory(path.join(tempBackupDir.path, 'nova_notes'));
        await notesBackupDir.create(recursive: true);
        await _copyDirectory(notesDir, notesBackupDir);
      }

      // 4. Copy audio recordings
      final audioDir = Directory(path.join(appDir.path, 'nova_audio'));
      if (await audioDir.exists()) {
        final audioBackupDir = Directory(path.join(tempBackupDir.path, 'nova_audio'));
        await audioBackupDir.create(recursive: true);
        await _copyDirectory(audioDir, audioBackupDir);
      }

      // 5. Copy images
      final imagesDir = Directory(path.join(appDir.path, 'nova_images'));
      if (await imagesDir.exists()) {
        final imagesBackupDir = Directory(path.join(tempBackupDir.path, 'nova_images'));
        await imagesBackupDir.create(recursive: true);
        await _copyDirectory(imagesDir, imagesBackupDir);
      }

      // 6. Create metadata file
      final metadata = {
        'version': '1.0',
        'app_version': '1.1.0',
        'created_at': DateTime.now().toIso8601String(),
        'device': Platform.operatingSystem,
      };
      final metadataFile = File(path.join(tempBackupDir.path, 'backup_info.txt'));
      await metadataFile.writeAsString(metadata.toString());

      // 7. Create ZIP archive
      final encoder = ZipFileEncoder();
      final zipPath = path.join(downloadsDir.path, backupName);
      encoder.create(zipPath);
      await encoder.addDirectory(tempBackupDir);
      encoder.close();

      // 8. Cleanup temp directory
      await tempBackupDir.delete(recursive: true);

      return zipPath;
    } catch (e) {
      print('Error creating backup: $e');
      return null;
    }
  }

  /// Restores data from a backup ZIP file
  /// Returns true if restoration was successful
  Future<bool> restoreBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        return false;
      }

      // Get directories
      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();
      
      // Create temp extraction directory
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extractDir = Directory(path.join(tempDir.path, 'nova_restore_$timestamp'));
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create(recursive: true);

      // 1. Extract ZIP file
      final bytes = await backupFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      for (final file in archive) {
        final filename = file.name;
        final filePath = path.join(extractDir.path, filename);
        
        if (file.isFile) {
          final outFile = File(filePath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filePath).create(recursive: true);
        }
      }

      // 2. Close existing database connection
      await DatabaseService.instance.close();

      // 3. Restore database
      final restoredDb = File(path.join(extractDir.path, 'nova.db'));
      if (await restoredDb.exists()) {
        final dbPath = await getDatabasesPath();
        final targetDbPath = path.join(dbPath, 'nova.db');
        await restoredDb.copy(targetDbPath);
      }

      // 4. Restore attachments
      final restoredAttachments = Directory(path.join(extractDir.path, 'nova_attachments'));
      if (await restoredAttachments.exists()) {
        final targetAttachments = Directory(path.join(appDir.path, 'nova_attachments'));
        if (await targetAttachments.exists()) {
          await targetAttachments.delete(recursive: true);
        }
        await targetAttachments.create(recursive: true);
        await _copyDirectory(restoredAttachments, targetAttachments);
      }

      // 5. Restore HTML notes
      final restoredNotes = Directory(path.join(extractDir.path, 'nova_notes'));
      if (await restoredNotes.exists()) {
        final targetNotes = Directory(path.join(appDir.path, 'nova_notes'));
        if (await targetNotes.exists()) {
          await targetNotes.delete(recursive: true);
        }
        await targetNotes.create(recursive: true);
        await _copyDirectory(restoredNotes, targetNotes);
      }

      // 6. Restore audio
      final restoredAudio = Directory(path.join(extractDir.path, 'nova_audio'));
      if (await restoredAudio.exists()) {
        final targetAudio = Directory(path.join(appDir.path, 'nova_audio'));
        if (await targetAudio.exists()) {
          await targetAudio.delete(recursive: true);
        }
        await targetAudio.create(recursive: true);
        await _copyDirectory(restoredAudio, targetAudio);
      }

      // 7. Restore images
      final restoredImages = Directory(path.join(extractDir.path, 'nova_images'));
      if (await restoredImages.exists()) {
        final targetImages = Directory(path.join(appDir.path, 'nova_images'));
        if (await targetImages.exists()) {
          await targetImages.delete(recursive: true);
        }
        await targetImages.create(recursive: true);
        await _copyDirectory(restoredImages, targetImages);
      }

      // 8. Cleanup temp directory
      await extractDir.delete(recursive: true);

      // 9. Reinitialize database connection
      await DatabaseService.instance.database;

      return true;
    } catch (e) {
      print('Error restoring backup: $e');
      return false;
    }
  }

  /// Helper method to recursively copy directories
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await for (final entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDirectory = Directory(path.join(destination.path, path.basename(entity.path)));
        await newDirectory.create(recursive: true);
        await _copyDirectory(entity, newDirectory);
      } else if (entity is File) {
        final newFile = File(path.join(destination.path, path.basename(entity.path)));
        await entity.copy(newFile.path);
      }
    }
  }

  /// Get list of all available backups in Downloads folder
  Future<List<FileSystemEntity>> getAvailableBackups() async {
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        return [];
      }

      final files = downloadsDir
          .listSync()
          .where((entity) => 
              entity is File && 
              path.basename(entity.path).startsWith('nova_backup_') &&
              path.extension(entity.path) == '.zip')
          .toList();

      // Sort by modification time (newest first)
      files.sort((a, b) => 
          (b as File).lastModifiedSync().compareTo((a as File).lastModifiedSync()));

      return files;
    } catch (e) {
      print('Error getting backups: $e');
      return [];
    }
  }

  /// Get backup file size in MB
  Future<double> getBackupSize(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        final bytes = await file.length();
        return bytes / (1024 * 1024); // Convert to MB
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Delete a backup file
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting backup: $e');
      return false;
    }
  }
}
