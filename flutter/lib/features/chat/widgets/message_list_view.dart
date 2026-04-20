import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import 'message_bubble.dart';
import 'agent_thinking_indicator.dart';

/// Professional message list with date dividers and smart scrolling
class MessageListView extends StatefulWidget {
  final List<ChatMessage> messages;
  final bool isLoading;
  final Widget? emptyWidget;

  const MessageListView({
    super.key,
    required this.messages,
    this.isLoading = false,
    this.emptyWidget,
  });

  @override
  State<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends State<MessageListView> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  bool _showNewMessageIndicator = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animate: false);
    });
  }

  @override
  void didUpdateWidget(MessageListView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // New messages arrived
    if (widget.messages.length > oldWidget.messages.length) {
      if (_autoScroll) {
        // Auto-scroll is enabled, scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(animate: true);
        });
      } else {
        // User has scrolled up - show new message indicator
        setState(() => _showNewMessageIndicator = true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    if (animate) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ?? const SizedBox.shrink();
    }

    return Stack(
      children: [
        NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            // Disable auto-scroll if user scrolls up
            if (notification.direction == ScrollDirection.reverse) {
              setState(() => _autoScroll = false);
            } else if (notification.direction == ScrollDirection.forward) {
              // Re-enable auto-scroll if user scrolls near bottom
              final atBottom =
                  _scrollController.position.pixels >=
                  _scrollController.position.maxScrollExtent - 100;
              if (atBottom) {
                setState(() {
                  _autoScroll = true;
                  _showNewMessageIndicator = false;
                });
              }
            }
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: _buildItemCount(),
            itemBuilder: (context, index) => _buildItem(context, index),
          ),
        ),
        // New message indicator
        if (_showNewMessageIndicator)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(24),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: InkWell(
                  onTap: () {
                    _scrollToBottom(animate: true);
                    setState(() {
                      _autoScroll = true;
                      _showNewMessageIndicator = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_downward,
                          size: 18,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'New messages',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  int _buildItemCount() {
    int count = 0;
    DateTime? lastDate;

    for (final message in widget.messages) {
      // Skip empty streaming messages - they're shown as the loading indicator
      if (message.status == MessageStatus.streaming &&
          message.text.trim().isEmpty) {
        continue;
      }

      final messageDate = _normalizeDate(message.timestamp);
      if (lastDate == null || !_isSameDay(lastDate, messageDate)) {
        count++; // Date divider
        lastDate = messageDate;
      }
      count++; // Message
    }

    if (widget.isLoading) count++; // Loading indicator
    return count;
  }

  Widget _buildItem(BuildContext context, int index) {
    int currentIndex = 0;
    DateTime? lastDate;

    for (int i = 0; i < widget.messages.length; i++) {
      final message = widget.messages[i];

      // Skip empty streaming messages - they're shown as the loading indicator
      if (message.status == MessageStatus.streaming &&
          message.text.trim().isEmpty) {
        continue;
      }

      final messageDate = _normalizeDate(message.timestamp);

      // Check if we need a date divider
      if (lastDate == null || !_isSameDay(lastDate, messageDate)) {
        if (currentIndex == index) {
          return _buildDateDivider(messageDate);
        }
        currentIndex++;
        lastDate = messageDate;
      }

      // Check if this is the message we want
      if (currentIndex == index) {
        return MessageBubble(
          message: message,
          showTimestamp: true,
          animate: true,
        );
      }
      currentIndex++;
    }

    // Loading indicator at the end
    if (widget.isLoading && currentIndex == index) {
      return _buildLoadingIndicator(context);
    }

    return const SizedBox.shrink();
  }

  Widget _buildDateDivider(DateTime date) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMMM d, y');
    final dateText = _getRelativeDateText(date) ?? dateFormat.format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: colorScheme.outline.withValues(alpha: 0.3)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: colorScheme.outline.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return const AgentThinkingIndicator();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String? _getRelativeDateText(DateTime date) {
    final now = DateTime.now();
    final today = _normalizeDate(now);
    final yesterday = _normalizeDate(now.subtract(const Duration(days: 1)));

    if (_isSameDay(date, today)) {
      return 'Today';
    } else if (_isSameDay(date, yesterday)) {
      return 'Yesterday';
    }
    return null;
  }
}
