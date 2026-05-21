import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' show PreviewData;

import '../../models/chat_model.dart';
import '../../theme/design_tokens.dart';
import '../../theme/reusable_widgets.dart';
import '../diaries/single_post_page.dart';
import '../voice_room_page.dart';

class PostCardMessage extends StatelessWidget {
  final bool isMe;
  final bool isSelected;
  final String postId;
  final String author;
  final String content;
  final String imageUrl;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const PostCardMessage({
    super.key,
    required this.isMe,
    required this.isSelected,
    required this.postId,
    required this.author,
    required this.content,
    required this.imageUrl,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXs),
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          decoration: BoxDecoration(
            color: isMe ? DesignTokens.primaryGold : DesignTokens.backgroundDarkMedium,
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusXl),
            border: isSelected
                ? Border.all(color: DesignTokens.primarySapphire, width: 2)
                : null,
          ),
          child: InkWell(
            onTap: () {
              if (postId.isNotEmpty) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SinglePostPage(postId: postId)));
              }
            },
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusXl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spacingMd,
                    DesignTokens.spacingMd,
                    DesignTokens.spacingMd,
                    DesignTokens.spacingXs,
                  ),
                  child: Text(
                    isMe ? 'قمت بمشاركة منشور' : 'شارك معك منشوراً',
                    style: TextStyle(
                      color: isMe ? Colors.black54 : Colors.white54,
                      fontSize: DesignTokens.fontSizeXs,
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spacingSm),
                  margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingXs),
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg)),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
                        child: CachedNetworkImage(
                          imageUrl: (imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.host.isNotEmpty == true) ? imageUrl : '',
                          width: 45,
                          height: 45,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => Container(
                              color: Colors.black12,
                              child: const Icon(Icons.image_not_supported,
                                  color: Colors.white24)),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacingSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(author,
                                style: TextStyle(
                                    color: isMe ? Colors.black : Colors.white,
                                    fontWeight: DesignTokens.fontWeightBold)),
                            const SizedBox(height: 2),
                            Text(content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: isMe
                                        ? Colors.black.withValues(alpha: 0.8)
                                        : Colors.white70,
                                    fontSize: DesignTokens.fontSizeXs)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingSm),
                    child: Text('عرض المنشور 👑',
                        style: TextStyle(
                            color: isMe ? Colors.black87 : Colors.white,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            fontSize: DesignTokens.fontSizeSm)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RoomCardMessage extends StatelessWidget {
  final bool isMe;
  final bool isSelected;
  final String roomId;
  final String roomName;
  final String? imageUrl;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const RoomCardMessage({
    super.key,
    required this.isMe,
    required this.isSelected,
    required this.roomId,
    required this.roomName,
    this.imageUrl,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: DesignTokens.spacingSm),
          padding: const EdgeInsets.all(DesignTokens.spacingMd),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          decoration: BoxDecoration(
            color: isSelected 
                ? DesignTokens.primarySapphire.withValues(alpha: 0.3) 
                : (isMe ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundDarkDeep),
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusXl),
            border: isSelected 
                ? Border.all(color: DesignTokens.primarySapphire, width: 2) 
                : Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: InkWell(
            onTap: () {
              if (isSelected) {
                onTap();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VoiceRoomPage(roomId: roomId, roomName: roomName))
                );
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
                  child: CachedNetworkImage(
                    imageUrl: (imageUrl != null && imageUrl!.isNotEmpty && Uri.tryParse(imageUrl!)?.host.isNotEmpty == true) ? imageUrl! : '',
                    width: 55,
                    height: 55,
                    fit: BoxFit.cover,
                    errorWidget: (c, e, s) => Container(
                      width: 55,
                      height: 55,
                      color: DesignTokens.primaryGold.withValues(alpha: 0.1),
                      child: const Icon(Icons.meeting_room_rounded, color: DesignTokens.primaryGold),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingLg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الغرفة الصوتية الملكية 👑', style: TextStyle(color: Colors.white54, fontSize: DesignTokens.fontSizeXs)),
                      const SizedBox(height: 4),
                      Text(roomName, style: const TextStyle(color: Colors.white, fontSize: DesignTokens.fontSizeSm, fontWeight: DesignTokens.fontWeightBold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('ID: $roomId', style: const TextStyle(color: DesignTokens.primaryGold, fontSize: DesignTokens.fontSizeXs, fontWeight: DesignTokens.fontWeightBold)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FileMessageWidget extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const FileMessageWidget({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (message.fileUrl != null) {
          final url = Uri.parse(message.fileUrl!);
          if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacingSm),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_rounded, color: DesignTokens.primaryGold, size: 30),
            const SizedBox(width: DesignTokens.spacingMd),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.text, style: TextStyle(color: isMe ? Colors.black : Colors.white, fontWeight: DesignTokens.fontWeightBold, fontSize: DesignTokens.fontSizeSm), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const Text('انقر للفتح 📥', style: TextStyle(color: Colors.white54, fontSize: DesignTokens.fontSizeXs)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SwipeToReply extends StatelessWidget {
  final Widget child;
  final VoidCallback onReply;
  final bool isMe;

  const SwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: isMe ? DismissDirection.endToStart : DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        HapticFeedback.lightImpact();
        onReply();
        return false;
      },
      background: Container(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingXl2),
        child: const Icon(Icons.reply_rounded, color: DesignTokens.primaryGold, size: 28),
      ),
      child: child,
    );
  }
}

class ChatMessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final bool isSelected;
  final String? senderAvatar;
  final String? senderName;
  final VoidCallback onReply;
  final VoidCallback onEdit;
  final VoidCallback onForward;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback? onAvatarTap;
  final Function(String) onVideoTap;
  final Function(String)? onImageTap;
  final bool isPlaying;
  final VoidCallback? onPlayVoice;
  final Duration? currentPosition;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isSelected = false,
    this.senderAvatar,
    this.senderName,
    required this.onReply,
    required this.onEdit,
    required this.onForward,
    required this.onLongPress,
    required this.onTap,
    required this.onDoubleTap,
    this.onAvatarTap,
    required this.onVideoTap,
    this.onImageTap,
    this.isPlaying = false,
    this.onPlayVoice,
    this.currentPosition,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  PreviewData? _previewData;

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '0:00';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  bool _isLink(String text) {
    return text.contains("http://") || text.contains("https://");
  }

  @override
  Widget build(BuildContext context) {
    final bool hasLink = widget.message.type == MessageType.text && _isLink(widget.message.text);

    return SwipeToReply(
      onReply: widget.onReply,
      isMe: widget.isMe,
      child: GestureDetector(
        onLongPress: widget.onLongPress,
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: Container(
          color: widget.isSelected ? DesignTokens.primarySapphire.withValues(alpha: 0.2) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd),
          child: Row(
            mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                  child: GestureDetector(
                    onTap: widget.onAvatarTap,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: DesignTokens.backgroundDarkLight,
                      backgroundImage: (widget.senderAvatar != null &&
                              widget.senderAvatar!.isNotEmpty &&
                              Uri.tryParse(widget.senderAvatar!)?.host.isNotEmpty == true)
                          ? CachedNetworkImageProvider(widget.senderAvatar!)
                          : null,
                      child: (widget.senderAvatar == null || widget.senderAvatar!.isEmpty)
                          ? const Icon(Icons.person, size: 16, color: Colors.white24)
                          : null,
                    ),
                  ),
                ),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXs),
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75),
                  padding: const EdgeInsets.all(DesignTokens.spacingMd),
                  decoration: BoxDecoration(
                    color: widget.isMe ? DesignTokens.primaryGold : DesignTokens.backgroundDarkMedium,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(DesignTokens.borderRadiusXl2),
                      topRight: const Radius.circular(DesignTokens.borderRadiusXl2),
                      bottomLeft: Radius.circular(widget.isMe ? DesignTokens.borderRadiusXl2 : DesignTokens.borderRadiusXs),
                      bottomRight: Radius.circular(widget.isMe ? DesignTokens.borderRadiusXs : DesignTokens.borderRadiusXl2),
                    ),
                    boxShadow: widget.isMe
                        ? [
                            BoxShadow(
                                color: DesignTokens.primaryGold.withValues(alpha: 0.2),
                                blurRadius: 8,
                                spreadRadius: 1)
                          ]
                        : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!widget.isMe && widget.senderName != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            widget.senderName!,
                            style: const TextStyle(
                              color: DesignTokens.primaryGold,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (widget.message.forwardedFrom != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.forward_rounded,
                                size: 10, color: Colors.white38),
                            const SizedBox(width: 4),
                            Text('محولة من ${widget.message.forwardedFrom}',
                                style: const TextStyle(
                                    fontSize: DesignTokens.fontSizeXs,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white38))
                          ]),
                        ),
                      if (widget.message.replyToText != null &&
                          !widget.message.replyToText!.startsWith('room_id:'))
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(DesignTokens.spacingSm),
                          decoration: BoxDecoration(
                              color: const Color(0x1A000000),
                              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
                              border: const Border(
                                  right: BorderSide(
                                      color: DesignTokens.primaryGold, width: 3))),
                          child: Text(widget.message.replyToText!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: widget.isMe ? Colors.black54 : Colors.white38,
                                  fontSize: DesignTokens.fontSizeXs)),
                        ),
                      
                      if (hasLink)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: LinkPreview(
                            enableAnimation: true,
                            onPreviewDataFetched: (data) {
                              setState(() {
                                _previewData = data;
                              });
                            },
                            previewData: _previewData,
                            text: widget.message.text,
                            width: MediaQuery.of(context).size.width * 0.7,
                            textStyle: TextStyle(color: widget.isMe ? Colors.black87 : Colors.white, fontSize: DesignTokens.fontSizeSm),
                            linkStyle: const TextStyle(color: DesignTokens.primarySapphire, decoration: TextDecoration.underline),
                            metadataTextStyle: const TextStyle(color: Colors.white70, fontSize: DesignTokens.fontSizeXs),
                            metadataTitleStyle: const TextStyle(color: Colors.white, fontWeight: DesignTokens.fontWeightBold, fontSize: DesignTokens.fontSizeSm),
                            padding: const EdgeInsets.all(0),
                          ),
                        ),

                      if (widget.message.type == MessageType.image)
                        GestureDetector(
                          onTap: () => (widget.message.imageUrl != null && widget.message.imageUrl!.isNotEmpty && Uri.tryParse(widget.message.imageUrl!)?.host.isNotEmpty == true) ? widget.onImageTap?.call(widget.message.imageUrl!) : null,
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
                              child: Hero(
                                tag: widget.message.imageUrl ?? widget.message.id,
                                child: CachedNetworkImage(
                                    imageUrl: (widget.message.imageUrl != null && widget.message.imageUrl!.isNotEmpty && Uri.tryParse(widget.message.imageUrl!)?.host.isNotEmpty == true) ? widget.message.imageUrl! : '',
                                    placeholder: (c, u) =>
                                        const Center(child: RoyalLoadingIndicator(size: 30))),
                              )),
                        )
                      else if (widget.message.type == MessageType.audio)
                        _buildVoiceWaveform(widget.isMe)
                      else if (widget.message.type == MessageType.video)
                        GestureDetector(
                          onTap: () => (widget.message.videoUrl != null && widget.message.videoUrl!.isNotEmpty && Uri.tryParse(widget.message.videoUrl!)?.host.isNotEmpty == true) ? widget.onVideoTap(widget.message.videoUrl!) : null,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
                                  child: (widget.message.imageUrl != null &&
                                          widget.message.imageUrl!.isNotEmpty &&
                                          Uri.tryParse(widget.message.imageUrl!)?.host.isNotEmpty == true)
                                      ? CachedNetworkImage(
                                          imageUrl: widget.message.imageUrl!,
                                          placeholder: (c, u) => const Center(
                                              child: RoyalLoadingIndicator(size: 30)))
                                      : Container(
                                          width: 200,
                                          height: 150,
                                          color: Colors.black,
                                          child: const Icon(Icons.videocam,
                                              color: Colors.white54, size: 40))),
                              const Icon(Icons.play_circle_fill_rounded,
                                  color: Colors.white, size: 50),
                            ],
                          ),
                        )
                      else if (widget.message.type == MessageType.file)
                        FileMessageWidget(message: widget.message, isMe: widget.isMe)
                      else if (!hasLink)
                        Text(widget.message.text,
                            style: TextStyle(
                                color: widget.isMe ? Colors.black : Colors.white,
                                fontSize: DesignTokens.fontSizeSm + 0.5,
                                height: 1.3)),
                      if (widget.message.reactions != null && widget.message.reactions!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: widget.message.reactions!.values
                                .toSet()
                                .map((e) => Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSm)),
                                      child: Text(e,
                                          style: const TextStyle(fontSize: 10)),
                                    ))
                                .toList(),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.message.editedAt != null)
                            const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Text('معدلة',
                                    style: TextStyle(
                                        fontSize: 8, color: Colors.white24))),
                          if (widget.message.expiresAt != null)
                            const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.timer_outlined,
                                    size: 8, color: Colors.white24)),
                          Text(intl.DateFormat('hh:mm a').format(widget.message.timestamp),
                              style: TextStyle(
                                  color: widget.isMe ? Colors.black38 : Colors.white24,
                                  fontSize: 9)),
                          if (widget.isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                                widget.message.isRead
                                    ? Icons.done_all_rounded
                                    : Icons.done_rounded,
                                size: 12,
                                color: widget.message.isRead
                                    ? DesignTokens.primarySapphire
                                    : Colors.black26),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceWaveform(bool isMe) {
    final bool isPlaying = widget.isPlaying;
    final int durationSeconds = widget.message.audioDuration ?? 0;
    final double progress = (isPlaying && widget.currentPosition != null && durationSeconds > 0)
        ? widget.currentPosition!.inMilliseconds / (durationSeconds * 1000)
        : 0.0;

    final random = math.Random(widget.message.id.hashCode);
    final List<double> samples = List.generate(20, (i) => 0.3 + random.nextDouble() * 0.7);

    return GestureDetector(
      onTap: widget.onPlayVoice,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacingXs),
              decoration: BoxDecoration(
                color: isMe ? Colors.black.withValues(alpha: 0.1) : DesignTokens.primaryGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isMe ? Colors.black87 : DesignTokens.primaryGold,
                size: 32,
              ),
            ),
            const SizedBox(width: DesignTokens.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 120,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(samples.length, (i) {
                        final bool active = (i / samples.length) < progress;
                        return Container(
                          width: 2.5,
                          height: 10 + (samples[i] * 14),
                          decoration: BoxDecoration(
                            color: active 
                                ? (isMe ? Colors.black : DesignTokens.primaryGold)
                                : (isMe ? Colors.black26 : Colors.white38),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPlaying && widget.currentPosition != null
                        ? _formatDuration(widget.currentPosition!.inSeconds)
                        : _formatDuration(durationSeconds),
                    style: TextStyle(
                      color: isMe ? Colors.black54 : Colors.white54,
                      fontSize: 10,
                      fontWeight: DesignTokens.fontWeightBold
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
