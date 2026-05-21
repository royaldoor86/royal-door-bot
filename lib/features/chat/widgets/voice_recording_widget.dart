import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/recording_service.dart';
import 'package:royaldoor/app_theme.dart';

class VoiceRecordingButton extends StatefulWidget {
  final RecordingService recordingService;
  final VoidCallback onRecordingStart;
  final Future<void> Function(String audioUrl, int duration) onRecordingSent;
  final VoidCallback onRecordingCancelled;
  final Function(String errorMessage)? onError;
  final String roomId;

  const VoiceRecordingButton({
    super.key,
    required this.recordingService,
    required this.onRecordingStart,
    required this.onRecordingSent,
    required this.onRecordingCancelled,
    this.onError,
    required this.roomId,
  });

  @override
  State<VoiceRecordingButton> createState() => _VoiceRecordingButtonState();
}

class _VoiceRecordingButtonState extends State<VoiceRecordingButton>
    with WidgetsBindingObserver {
  double _dragX = 0;
  double _dragY = 0;
  bool _isSlidingCancel = false;
  bool _isSlidingLock = false;
  late Offset _initialPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleLongPressStart(LongPressStartDetails details) async {
    try {
      debugPrint('[VoiceRecordingButton] Starting recording...');
      _initialPosition = details.globalPosition;
      _isSlidingCancel = false;
      _isSlidingLock = false;

      widget.onRecordingStart();
      await widget.recordingService.startRecording();
      HapticFeedback.heavyImpact();

      setState(() {
        _dragX = 0;
        _dragY = 0;
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        widget.onError?.call('خطأ في بدء التسجيل: $e');
      }
    }
  }

  void _handleLongPressMove(LongPressMoveUpdateDetails details) {
    if (!widget.recordingService.isRecording) {
      debugPrint('[VoiceRecordingButton] Recording not active, ignoring move');
      return;
    }

    if (widget.recordingService.isRecordingLocked && _isSlidingLock) {
      // Already locked, don't track movement
      return;
    }

    final totalDragX = details.globalPosition.dx - _initialPosition.dx;
    final totalDragY = details.globalPosition.dy - _initialPosition.dy;

    setState(() {
      _dragX = totalDragX;
      _dragY = totalDragY;
    });

    debugPrint(
        '[VoiceRecordingButton] Drag - X: $_dragX, Y: $_dragY, locked: ${widget.recordingService.isRecordingLocked}');

    // Slide up to lock (showing lock icon like Telegram)
    if (_dragY < -80 &&
        !widget.recordingService.isRecordingLocked &&
        !_isSlidingLock) {
      debugPrint('[VoiceRecordingButton] Locking recording...');
      _isSlidingLock = true;
      widget.recordingService.lockRecording();
      HapticFeedback.mediumImpact();
    }

    // Slide right to cancel (RTL: swipe right cancels) - require stronger swipe (250 pixels)
    if (_dragX > 250 && !_isSlidingCancel) {
      debugPrint('[VoiceRecordingButton] Cancelling recording by swipe...');
      _isSlidingCancel = true;
      _cancelRecording();
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    debugPrint(
        '[VoiceRecordingButton] Long press ended - isRecording: ${widget.recordingService.isRecording}, isSlidingCancel: $_isSlidingCancel, isLocked: ${widget.recordingService.isRecordingLocked}');

    // If already cancelled, don't try to send
    if (_isSlidingCancel) {
      debugPrint('[VoiceRecordingButton] Already cancelled, skipping send');
      return;
    }

    // If recording is not active, don't try to send
    if (!widget.recordingService.isRecording) {
      debugPrint('[VoiceRecordingButton] Recording not active, skipping send');
      return;
    }

    // If not locked, send immediately
    if (!widget.recordingService.isRecordingLocked) {
      debugPrint('[VoiceRecordingButton] Sending recording (not locked)');
      _sendRecording();
    } else {
      debugPrint(
          '[VoiceRecordingButton] Recording locked, waiting for send button');
      // If locked, user needs to tap send button to send
    }
  }

  void _cancelRecording() async {
    try {
      debugPrint('[VoiceRecordingButton] Cancelling recording...');
      HapticFeedback.selectionClick();
      await widget.recordingService.cancelRecording();

      if (mounted) {
        widget.onRecordingCancelled();
        _isSlidingCancel = false;
        _isSlidingLock = false;
        _dragX = 0;
        _dragY = 0;
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء التسجيل'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 800),
          ),
        );
      }
      debugPrint('[VoiceRecordingButton] Recording cancelled successfully');
    } catch (e) {
      debugPrint('[VoiceRecordingButton] Error cancelling: $e');
    }
  }

  void _sendRecording() async {
    try {
      debugPrint('[VoiceRecordingButton] Starting send process...');

      final floodError = widget.recordingService.checkFloodProtection();
      if (floodError != null) {
        debugPrint(
            '[VoiceRecordingButton] Flood protection triggered: $floodError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(floodError),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        await widget.recordingService.cancelRecording();
        if (mounted) {
          widget.onRecordingCancelled();
          setState(() {});
        }
        return;
      }

      widget.recordingService.setIsSendingVoice(true);
      final duration = widget.recordingService.recordingDuration;

      debugPrint(
          '[VoiceRecordingButton] Uploading recording with duration: $duration');

      final audioUrl =
          await widget.recordingService.uploadRecording(widget.roomId);

      debugPrint('[VoiceRecordingButton] Upload successful: $audioUrl');

      widget.recordingService.markVoiceSent();

      if (mounted) {
        HapticFeedback.mediumImpact();
        // Call the callback with the audio URL and duration - AWAIT it
        await widget.onRecordingSent(audioUrl, duration);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الرسالة الصوتية ✓'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 1500),
          ),
        );

        debugPrint('[VoiceRecordingButton] Recording sent successfully');
      }
    } catch (e) {
      debugPrint('[VoiceRecordingButton] Error sending recording: $e');
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        widget.onError?.call(errorMsg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $errorMsg'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        widget.recordingService.resetRecording();
        _isSlidingCancel = false;
        _isSlidingLock = false;
        _dragX = 0;
        _dragY = 0;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _handleLongPressStart,
      onLongPressMoveUpdate: _handleLongPressMove,
      onLongPressEnd: _handleLongPressEnd,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: AppTheme.royalGold.withValues(alpha: 0.1),
          radius: 22,
          child: widget.recordingService.isSendingVoice
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppTheme.royalGold,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.mic_none_rounded,
                  color: AppTheme.royalGold,
                ),
        ),
      ),
    );
  }
}

class VoiceRecordingBar extends StatefulWidget {
  final RecordingService recordingService;
  final VoidCallback onCancel;
  final Future<void> Function() onSend;

  const VoiceRecordingBar({
    super.key,
    required this.recordingService,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<VoiceRecordingBar> createState() => _VoiceRecordingBarState();
}

class _VoiceRecordingBarState extends State<VoiceRecordingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isSending = false;
  late Offset _initialPosition;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleSendTap() async {
    if (_isSending) return;

    setState(() => _isSending = true);
    try {
      await widget.onSend();
    } catch (e) {
      debugPrint('[VoiceRecordingBar] Error sending: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _handlePanDown(DragDownDetails details) {
    debugPrint('[VoiceRecordingBar] 🎯 Pan DOWN - Starting drag');
    _initialPosition = details.globalPosition;
    _isLocked = false;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final dy = details.globalPosition.dy - _initialPosition.dy;
    final dx = details.globalPosition.dx - _initialPosition.dx;

    debugPrint(
        '[VoiceRecordingBar] 👆 DRAG - dy:$dy (negative=up), dx:$dx, locked:${widget.recordingService.isRecordingLocked}');

    // Drag UP to lock (negative dy means up)
    if (dy < -60 && !_isLocked && !widget.recordingService.isRecordingLocked) {
      debugPrint('[VoiceRecordingBar] ✅ RECORDING LOCKED!');
      _isLocked = true;
      widget.recordingService.lockRecording();
      HapticFeedback.mediumImpact();
      setState(() {});
    }

    // Drag LEFT to cancel (negative dx means left)
    if (dx < -100) {
      debugPrint('[VoiceRecordingBar] ❌ CANCELLED BY DRAG!');
      widget.onCancel();
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    debugPrint('[VoiceRecordingBar] 🏁 Drag ended');
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      child: GestureDetector(
        onPanDown: _handlePanDown,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        onTap: () {
          debugPrint('[VoiceRecordingBar] 🖱️ TAP DETECTED!');
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 70,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.95),
            border: Border.all(
              color: AppTheme.royalGold.withValues(alpha: 0.4),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: AppTheme.royalGold.withValues(alpha: 0.2),
                blurRadius: 12,
                spreadRadius: 2,
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // DELETE BUTTON - Left
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: _isSending ? null : widget.onCancel,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    // ignore: prefer_const_constructors
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                  ),
                ),
              ),

              // MIC & TIMER - Center Left
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Icon(
                              Icons.mic,
                              color: Colors.red.withValues(
                                alpha: (0.5 + (_pulseController.value * 0.5))
                                    .clamp(0.0, 1.0),
                              ),
                              size: 22,
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${(widget.recordingService.recordingDuration ~/ 60).toString().padLeft(2, '0')}:${(widget.recordingService.recordingDuration % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    if (!widget.recordingService.isRecordingLocked)
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          '⬆️ اسحب للأعلى للقفل',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      )
                  ],
                ),
              ),

              // WAVEFORM - Center
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(20, (index) {
                    final amp = (widget.recordingService.currentAmplitude + 160)
                            .clamp(0, 160) /
                        160;
                    final height = 4 + (Random().nextDouble() * 20 * amp);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        width: 2.5,
                        height: height,
                        decoration: BoxDecoration(
                          color: AppTheme.royalGold.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // SEND/LOCK BUTTON - Right
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: _isSending
                      ? null
                      : (widget.recordingService.isRecordingLocked
                          ? _handleSendTap
                          : null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.recordingService.isRecordingLocked
                          ? (_isSending
                              ? AppTheme.royalGold.withValues(alpha: 0.5)
                              : AppTheme.royalGold)
                          : Colors.white24,
                      shape: BoxShape.circle,
                      boxShadow: widget.recordingService.isRecordingLocked
                          ? [
                              BoxShadow(
                                color:
                                    AppTheme.royalGold.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : [],
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Icon(
                            widget.recordingService.isRecordingLocked
                                ? Icons.send_rounded
                                : Icons.lock_open_rounded,
                            color: widget.recordingService.isRecordingLocked
                                ? Colors.black
                                : Colors.white54,
                            size: 22,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
