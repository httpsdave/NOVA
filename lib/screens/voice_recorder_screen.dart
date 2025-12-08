import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecorderScreen extends StatefulWidget {
  const VoiceRecorderScreen({super.key});

  @override
  State<VoiceRecorderScreen> createState() => _VoiceRecorderScreenState();
}

class _VoiceRecorderScreenState extends State<VoiceRecorderScreen> {
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  String? _recordedFilePath;
  Duration _recordDuration = Duration.zero;
  Duration _playDuration = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Timer? _recordTimer;
  bool _recorderInitialized = false;
  bool _playerInitialized = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _initPlayer();
  }

  Future<void> _initRecorder() async {
    await _audioRecorder.openRecorder();
    setState(() => _recorderInitialized = true);
  }

  Future<void> _initPlayer() async {
    await _audioPlayer.openPlayer();
    setState(() => _playerInitialized = true);
    
    _audioPlayer.setSubscriptionDuration(const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _audioRecorder.closeRecorder();
    _audioPlayer.closePlayer();
    super.dispose();
  }

  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _startRecording() async {
    if (!_recorderInitialized) return;
    
    final hasPermission = await _checkPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory(path.join(appDir.path, 'nova_audio'));
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final fileName = '${const Uuid().v4()}.aac';
      final filePath = path.join(audioDir.path, fileName);

      await _audioRecorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
        _recordDuration = Duration.zero;
        _recordedFilePath = filePath;
      });

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordDuration = Duration(seconds: timer.tick);
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stopRecorder();
      _recordTimer?.cancel();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
      }
    }
  }

  Future<void> _playRecording() async {
    if (_recordedFilePath == null || !_playerInitialized) return;

    try {
      await _audioPlayer.startPlayer(
        fromURI: _recordedFilePath!,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _playDuration = Duration.zero;
          });
        },
      );
      
      setState(() => _isPlaying = true);
      
      _audioPlayer.onProgress!.listen((event) {
        setState(() {
          _playDuration = event.position;
          _totalDuration = event.duration;
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing recording: $e')),
        );
      }
    }
  }

  Future<void> _pauseRecording() async {
    await _audioPlayer.pausePlayer();
    setState(() {
      _isPlaying = false;
      _isPaused = true;
    });
  }

  Future<void> _resumeRecording() async {
    await _audioPlayer.resumePlayer();
    setState(() {
      _isPlaying = true;
      _isPaused = false;
    });
  }

  void _discardRecording() {
    if (_recordedFilePath != null) {
      final file = File(_recordedFilePath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    Navigator.pop(context);
  }

  void _saveRecording() {
    if (_recordedFilePath != null) {
      Navigator.pop(context, _recordedFilePath);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2DBD6C),
        foregroundColor: Colors.white,
        title: const Text('Voice Recorder'),
        actions: [
          if (_recordedFilePath != null && !_isRecording)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveRecording,
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          // Recording/Playing indicator
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording
                  ? Colors.red.withOpacity(0.2)
                  : _isPlaying
                      ? const Color(0xFF2DBD6C).withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
              border: Border.all(
                color: _isRecording
                    ? Colors.red
                    : _isPlaying
                        ? const Color(0xFF2DBD6C)
                        : Colors.grey.shade600,
                width: 4,
              ),
            ),
            child: Center(
              child: Icon(
                _isRecording
                    ? Icons.mic
                    : _isPlaying
                        ? Icons.volume_up
                        : Icons.mic_none,
                size: 80,
                color: _isRecording
                    ? Colors.red
                    : _isPlaying
                        ? const Color(0xFF2DBD6C)
                        : Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Duration display
          Text(
            _isRecording
                ? _formatDuration(_recordDuration)
                : _isPlaying || _isPaused
                    ? '${_formatDuration(_playDuration)} / ${_formatDuration(_totalDuration)}'
                    : _recordedFilePath != null
                        ? _formatDuration(_recordDuration)
                        : '00:00',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          // Waveform visualization (simplified - no amplitude API in flutter_sound)
          if (_isRecording)
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: Text(
                  'Recording...',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          // Playback progress
          if (_recordedFilePath != null && !_isRecording)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Slider(
                    value: _playDuration.inMilliseconds.toDouble(),
                    max: _totalDuration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                    activeColor: const Color(0xFF2DBD6C),
                    onChanged: (value) async {
                      final newPosition = Duration(milliseconds: value.toInt());
                      await _audioPlayer.seekToPlayer(newPosition);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_playDuration),
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      Text(
                        _formatDuration(_totalDuration),
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const Spacer(),
          // Control buttons
          Padding(
            padding: const EdgeInsets.all(40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Discard button
                if (_recordedFilePath != null && !_isRecording)
                  FloatingActionButton(
                    heroTag: 'discard',
                    onPressed: _discardRecording,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.delete),
                  ),
                // Record/Stop button
                FloatingActionButton.large(
                  heroTag: 'record',
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  backgroundColor: _isRecording ? Colors.red : const Color(0xFF2DBD6C),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    size: 40,
                  ),
                ),
                // Play/Pause button
                if (_recordedFilePath != null && !_isRecording)
                  FloatingActionButton(
                    heroTag: 'play',
                    onPressed: _isPlaying
                        ? _pauseRecording
                        : _isPaused
                            ? _resumeRecording
                            : _playRecording,
                    backgroundColor: const Color(0xFF2DBD6C),
                    child: Icon(
                      _isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
