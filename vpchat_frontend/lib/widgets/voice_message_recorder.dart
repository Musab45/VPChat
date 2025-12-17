import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../config/app_theme.dart';
import 'animations/animated_widgets.dart';

/// Voice message recorder widget with actual audio recording
class VoiceMessageRecorder extends StatefulWidget {
  final Function(File file, int durationSeconds) onRecordingComplete;
  final VoidCallback onCancel;

  const VoiceMessageRecorder({
    super.key,
    required this.onRecordingComplete,
    required this.onCancel,
  });

  @override
  State<VoiceMessageRecorder> createState() => _VoiceMessageRecorderState();
}

class _VoiceMessageRecorderState extends State<VoiceMessageRecorder>
    with TickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordingDuration = 0;
  Timer? _timer;
  String? _recordingPath;

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  double _dragOffset = 0;
  static const double _cancelThreshold = -100;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: AppAnimations.normal,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _slideController,
            curve: AppAnimations.defaultCurve,
          ),
        );

    _slideController.forward();
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // Check permission
      if (!await _recorder.hasPermission()) {
        widget.onCancel();
        return;
      }

      // Get temp directory for recording
      final dir = await getTemporaryDirectory();
      _recordingPath =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });

      _pulseController.repeat(reverse: true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _recordingDuration++);
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Error starting recording: $e');
      widget.onCancel();
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _pulseController.stop();

    try {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);

      if (_recordingDuration >= 1 && path != null) {
        final file = File(path);
        if (await file.exists()) {
          widget.onRecordingComplete(file, _recordingDuration);
        } else {
          widget.onCancel();
        }
      } else {
        // Recording too short, delete file
        if (_recordingPath != null) {
          final file = File(_recordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
        widget.onCancel();
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      widget.onCancel();
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    _pulseController.stop();
    HapticFeedback.mediumImpact();

    try {
      await _recorder.stop();
      // Delete the recorded file
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Error canceling recording: $e');
    }

    widget.onCancel();
  }

  Future<void> _togglePause() async {
    try {
      if (_isPaused) {
        await _recorder.resume();
        _pulseController.repeat(reverse: true);
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordingDuration++);
        });
      } else {
        await _recorder.pause();
        _timer?.cancel();
        _pulseController.stop();
      }
      setState(() => _isPaused = !_isPaused);
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error toggling pause: $e');
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            _dragOffset += details.delta.dx;
            _dragOffset = _dragOffset.clamp(_cancelThreshold * 1.5, 0);
          });
        },
        onHorizontalDragEnd: (details) {
          if (_dragOffset < _cancelThreshold) {
            _cancelRecording();
          } else {
            setState(() => _dragOffset = 0);
          }
        },
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          transform: Matrix4.translationValues(_dragOffset, 0, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundMedium,
              border: Border(top: BorderSide(color: AppColors.backgroundDark)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Cancel hint
                  AnimatedOpacity(
                    duration: AppAnimations.fast,
                    opacity: _dragOffset < -20 ? 1.0 : 0.5,
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back,
                          color: _dragOffset < _cancelThreshold
                              ? AppColors.error
                              : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Slide to cancel',
                          style: AppTypography.bodySmall.copyWith(
                            color: _dragOffset < _cancelThreshold
                                ? AppColors.error
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Recording indicator
                  Row(
                    children: [
                      // Animated recording dot
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isRecording && !_isPaused
                                ? _pulseAnimation.value
                                : 1.0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                                boxShadow: _isRecording && !_isPaused
                                    ? [
                                        BoxShadow(
                                          color: AppColors.error.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // Duration
                      Text(
                        _formatDuration(_recordingDuration),
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Pause button
                  ScaleOnTap(
                    onTap: _togglePause,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLighter,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isPaused ? Icons.play_arrow : Icons.pause,
                        color: AppColors.textMuted,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  ScaleOnTap(
                    onTap: _stopRecording,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blurple.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Voice message player widget with actual audio playback
class VoiceMessagePlayer extends StatefulWidget {
  final String? audioUrl;
  final int durationSeconds;
  final bool isMine;

  const VoiceMessagePlayer({
    super.key,
    this.audioUrl,
    required this.durationSeconds,
    this.isMine = false,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  double _progress = 0;
  int _currentPosition = 0;
  late AnimationController _waveController;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _setupPlayer();
  }

  void _setupPlayer() {
    _positionSubscription = _player.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position.inSeconds;
          _progress = position.inSeconds / widget.durationSeconds;
        });
      }
    });

    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) {
            _progress = 0;
            _currentPosition = 0;
            _waveController.stop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _player.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    HapticFeedback.lightImpact();

    if (_isPlaying) {
      await _player.pause();
      _waveController.stop();
    } else {
      if (widget.audioUrl != null) {
        if (_progress == 0) {
          await _player.play(UrlSource(widget.audioUrl!));
        } else {
          await _player.resume();
        }
        _waveController.repeat();
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isMine
            ? Colors.white.withValues(alpha: 0.1)
            : AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          ScaleOnTap(
            onTap: _togglePlayback,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isMine
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.blurple.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: widget.isMine ? Colors.white : AppColors.blurple,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Waveform visualization
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24, child: _buildWaveform()),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: AppTypography.labelSmall.copyWith(
                        color: widget.isMine
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppColors.textMuted,
                      ),
                    ),
                    Text(
                      _formatDuration(widget.durationSeconds),
                      style: AppTypography.labelSmall.copyWith(
                        color: widget.isMine
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barCount = (constraints.maxWidth / 4).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(barCount, (index) {
            // Generate pseudo-random heights for waveform
            final seed = (index * 7 + widget.durationSeconds) % 10;
            final baseHeight = 0.3 + (seed / 10) * 0.7;
            final isPlayed = index / barCount <= _progress;

            return AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                double height = baseHeight;
                if (_isPlaying && isPlayed) {
                  height = baseHeight * (0.8 + 0.4 * _waveController.value);
                }
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  width: 2,
                  height: 24 * height,
                  decoration: BoxDecoration(
                    color: isPlayed
                        ? (widget.isMine ? Colors.white : AppColors.blurple)
                        : (widget.isMine
                              ? Colors.white.withValues(alpha: 0.3)
                              : AppColors.textDark),
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }
}
