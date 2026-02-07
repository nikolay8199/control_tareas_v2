import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';


class FullscreenImageViewer extends StatefulWidget {
  final String imageUrl;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  bool _saving = false;

  Future<void> _saveImage() async {
    try {
      setState(() => _saving = true);

      final status = await Permission.photos.request();

      if (!status.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permiso denegado")),
        );
        return;
      }

      // 🔽 Descargar imagen a memoria
      final response = await Dio().get(
        widget.imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      // 📁 Guardar en archivo temporal
      final tempDir = await getTemporaryDirectory();
      final filePath =
          "${tempDir.path}/img_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final file = File(filePath);
      await file.writeAsBytes(response.data);

      // 💾 Guardar en galería
      await Gal.putImage(filePath, album: "ControlTareas");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Imagen guardada en galería")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _saving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.download),
            onPressed: _saving ? null : _saveImage,
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: NetworkImage(widget.imageUrl),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}
