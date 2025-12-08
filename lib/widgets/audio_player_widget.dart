import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String filePath;
  final VoidCallback? onDelete;

  const AudioPlayerWidget({
    super.key,
    required this.filePath,
    this.onDelete,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  bool _isPlaying = false;
  bool _isPaused = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _playerInitialized = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _audioPlayer.openPlayer();
    setState(() => _playerInitialized = true);
    _audioPlayer.setSubscriptionDuration(const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    _audioPlayer.closePlayer();
    super.dispose();
  }

  Future<void> _play() async {
    if (!_playerInitialized) return;
    
    try {
      await _audioPlayer.startPlayer(
        fromURI: widget.filePath,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        },
      );
      
      setState(() => _isPlaying = true);
      
      _audioPlayer.onProgress!.listen((event) {
        setState(() {
          _position = event.position;
          _duration = event.duration;
        });
      });
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> _pause() async {
    await _audioPlayer.pausePlayer();
    setState(() {
      _isPlaying = false;
      _isPaused = true;
    });
  }

  Future<void> _resume() async {
    await _audioPlayer.resumePlayer();
    setState(() {
      _isPlaying = true;
      _isPaused = false;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2DBD6C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2DBD6C).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: const Color(0xFF2DBD6C),
            ),
            onPressed: _isPlaying
                ? _pause
                : _isPaused
                    ? _resume
                    : _play,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  value: _position.inMilliseconds.toDouble(),
                  max: _duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                  activeColor: const Color(0xFF2DBD6C),
                  onChanged: (value) async {
                    final newPosition = Duration(milliseconds: value.toInt());
                    await _audioPlayer.seekToPlayer(newPosition);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: widget.onDelete,
            ),
        ],
      ),
    );
  }
}
