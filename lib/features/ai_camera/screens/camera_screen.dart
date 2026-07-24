import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  String? _errorMessage;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    print('>>> RUNNING FIXED CAMERA SCREEN <<<'); // Diagnostic print
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera found on this device.';
        });
        return;
      }
      
      _controller = CameraController(
        cameras.first, 
        ResolutionPreset.high,
        enableAudio: false, 
      );
      
      final future = _controller!.initialize();
      
      setState(() {
        _initializeControllerFuture = future;
      });
      
      await future;
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not start camera: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndContinue() async {
    if (_controller == null || _isCapturing) return;
    
    setState(() {
      _isCapturing = true;
    });

    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      if (!mounted) return;
      context.pop(image.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not capture photo: $e'))
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Capture Food'), 
        backgroundColor: Colors.black, 
        foregroundColor: Colors.white
      ),
      body: _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white)))
          : FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CameraPreview(_controller!),
                      if (_isCapturing) const Center(child: CircularProgressIndicator(color: Colors.green)),
                    ],
                  );
                } else {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                }
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isCapturing ? null : _captureAndContinue,
        backgroundColor: _isCapturing ? Colors.grey : Colors.green,
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}