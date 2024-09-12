import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class Exports extends StatelessWidget {
  const Exports({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عمليات التصدير السابقة'),
      ),
      body: FutureBuilder<List<FileSystemEntity>>(
        future: () async {
          final documentsDirectory = Platform.isAndroid
              ? (await getExternalStorageDirectories(
                  type: StorageDirectory.documents,
                ))!
                  .first
              : await getDownloadsDirectory();

          final exportsDirectory = Directory(
            path.join(
              documentsDirectory!.path,
              'Exports',
            ),
          );

          if (exportsDirectory.existsSync())
            return exportsDirectory.list().where((f) => f is File).toList();

          return <FileSystemEntity>[];
        }(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorWidget(snapshot.error!);

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, i) => Card(
              child: ListTile(
                onTap: () => OpenFile.open(snapshot.data![i].path),
                title: Text(
                  snapshot.data![i].uri.pathSegments[
                      snapshot.data![i].uri.pathSegments.length - 1],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
