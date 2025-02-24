import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  double progress = 0.0;

  @override
  void initState() {
    super.initState();

    // requestStoragePermission();
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidVersion = int.parse((await _getAndroidVersion()) ?? "0");

      if (androidVersion >= 30) {
        // Android 11 va undan yuqori uchun manageExternalStorage ruxsatini so'rash
        if (await Permission.manageExternalStorage.isGranted) {
          return true;
        } else {
          var status = await Permission.manageExternalStorage.request();
          if (status.isGranted) return true;
        }
      } else {
        // Android 10 va past versiyalar uchun storage ruxsatini so'rash
        if (await Permission.storage.isGranted) {
          return true;
        } else {
          var status = await Permission.storage.request();
          if (status.isGranted) return true;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Xotira uchun ruxsat berilmadi")),
      );
      return false;
    }

    if (Platform.isIOS) {
      var photosStatus = await Permission.photos.request();
      var mediaStatus = await Permission.mediaLibrary.request();

      if (photosStatus.isGranted || mediaStatus.isGranted) {
        return true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ iOS: Ruxsat berilmadi")),
      );
      return false;
    }

    return false;
  }

  Future<String?> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      debugPrint(androidInfo.version.sdkInt.toString());
      return androidInfo.version.sdkInt.toString(); // Android SDK versiyasi
    }
    return null;
  }

  Future<void> downloadMp3(String url, [String? saveFolderPath]) async {
    bool isPermissionGranted = await requestStoragePermission();
    if (!isPermissionGranted) return;
    Directory? directory = await getDownloadDirectory();

    if (directory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Papka topilmadi")));
      return;
    }

    String savePath = "";

    if (saveFolderPath != null) {
      savePath =
          '$saveFolderPath/${DateTime.now().millisecondsSinceEpoch.remainder(100000)}.mp3';
    } else {
      savePath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch.remainder(100000)}.mp3';
    }

    debugPrint("Save folder path: $savePath ------");

    try {
      Dio dio = Dio();
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              progress = received / total;
            });
          }
        },
      );

      if (Platform.isIOS) {
        await openDownloadedFile(savePath);
      }

      debugPrint("✅ Yuklab olindi: $savePath");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("✅ Yuklab olindi: $savePath")));
    } on DioException catch (e) {
      debugPrint("Error on DioException catch (e)  $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ DioException: $e")));
    } catch (e) {
      debugPrint("Error on catch (e)  $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Xatolik: $e")));
    }
  }

  Future<String> getInternalStoragePath() async {
    Directory? directory = await getExternalStorageDirectory();
    return directory?.parent.parent.parent.path ?? '/storage/emulated/0';
  }

  Future<void> createCustomFolderForAndroid() async {
    if (!await requestStoragePermission()) return;

    String basePath = await getInternalStoragePath();
    Directory audioDir = Directory('$basePath/Novatio/Audio');

    if (!audioDir.existsSync()) {
      audioDir.createSync(recursive: true); // Papka yaratish
    }

    downloadMp3(
      "https://sakinat.novatio.uz/storage/media/24/1.mp3",
      audioDir.path,
    );

    print("✅ Papka manzili: ${audioDir.path}");
  }

  Future<Directory?> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      Directory? directory = await getDownloadsDirectory(); // Android 11+ uchun
      return directory ??
          (await getExternalStorageDirectory())!; // Agar null bo‘lsa, muqobil
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory(); // iOS uchun xavfsiz
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("MP3 Yuklab olish")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LinearProgressIndicator(value: progress),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // downloadMp3(
                //   "https://sakinat.novatio.uz/storage/media/24/1.mp3",
                // );

                if (Platform.isIOS) {
                  downloadMp3(
                    "https://sakinat.novatio.uz/storage/media/24/1.mp3",
                  );
                } else {
                  createCustomFolderForAndroid();
                }
              },
              child: Text("MP3 Yuklab olish"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openDownloadedFile(String filePath) async {
    final result = await OpenFile.open(filePath);

    if (result.type == ResultType.done) {
      debugPrint("✅ Fayl ochildi: $filePath");
    } else {
      debugPrint("❌ Fayl ochilmadi: ${result.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Fayl ochilmadi: ${result.message}")),
      );
    }
  }
}
