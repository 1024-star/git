import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../utils/app_logger.dart';
import 'ai_api_client.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  bool showWelcome = true;

  final TextEditingController _inputController = TextEditingController();

  /// 小灵语音输入：真实录音器（WAV / 16kHz / 单声道），音频交给 PC 端离线识别
  final AudioRecorder _recorder = AudioRecorder();
  final ScrollController _scrollController = ScrollController();

  bool isTyping = false;
  bool isThinking = false;

  bool isRecording = false;

  /// 【核心输出变量】打字机流式文本通知器：
  /// AI 回复逐字输出时只通知气泡内的小组件刷新，
  /// 不再每字符 setState 重建整页（旧实现约 60 次/秒整页重建，是卡顿主因之一）
  final ValueNotifier<String> _streamingText = ValueNotifier<String>('');

  final List<_ChatMessage> messages = [];

  // Streaming pacing (smaller = faster)
  // 当前值使完整固定输出约 30 秒；调大则更慢、调小则更快
  static const double _speedFactor = 2.4;

  late final AiApiClient _aiApi;

  VideoPlayerController? _videoController;
  bool welcomeVideoError = false;
  bool isVideoLoading = true;

  static const String _hasSeenWelcomeKey = 'ai_assistant_has_seen_welcome';
  static const String _chatHistoryKey = 'ai_assistant_chat_history';

  // Public method to clear all AI assistant data (for testing or reset)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSeenWelcomeKey);
    await prefs.remove(_chatHistoryKey);
    print('AI Assistant: All data cleared');
  }

  @override
  void initState() {
    super.initState();
    _aiApi = AiApiClient();
    print('AI Assistant Page: initState called');
    _loadState();
  }

  Future<void> _loadState() async {
    print('AI Assistant Page: _loadState started');
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool(_hasSeenWelcomeKey) ?? false;
    print('AI Assistant Page: hasSeenWelcome = $hasSeenWelcome');

    if (hasSeenWelcome) {
      // Load chat history
      final chatHistoryJson = prefs.getString(_chatHistoryKey);
      print('AI Assistant Page: chatHistoryJson exists = ${chatHistoryJson != null}');
      if (chatHistoryJson != null && mounted) {
        try {
          final List<dynamic> decoded = jsonDecode(chatHistoryJson);
          print('AI Assistant Page: decoded ${decoded.length} messages');
          final loadedMessages = decoded.map((e) => _ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
          print('AI Assistant Page: loaded ${loadedMessages.length} messages');

          // Validate loaded messages before applying
          if (loadedMessages.isNotEmpty) {
            print('AI Assistant Page: applying loaded messages');
            setState(() {
              showWelcome = false;
              messages.clear();
              messages.addAll(loadedMessages);
            });
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
            return;
          } else {
            // Empty data but has seen welcome, reset welcome state to show video again
            print('AI Assistant Page: loaded messages empty, resetting welcome state');
            await prefs.remove(_hasSeenWelcomeKey);
            setState(() {
              showWelcome = true;
            });
            _initWelcomeVideo();
            return;
          }
        } catch (e, st) {
          AppLogger.e('AI助手', e, st);
          print('AI Assistant Page: error loading chat history - $e');
          // If loading fails, clear corrupted data and show welcome video
          await prefs.remove(_chatHistoryKey);
          await prefs.remove(_hasSeenWelcomeKey);
          setState(() {
            showWelcome = true;
          });
          _initWelcomeVideo();
          return;
        }
      } else {
        print('AI Assistant Page: no chat history found, resetting welcome state');
        // Has seen welcome but no chat history, reset welcome state to show video again
        await prefs.remove(_hasSeenWelcomeKey);
        setState(() {
          showWelcome = true;
        });
        _initWelcomeVideo();
        return;
      }
    }

    // Show welcome video
    print('AI Assistant Page: showing welcome video');
    _initWelcomeVideo();
  }

  /// 右上角历史图标：恢复本地保存的最近一次对话（历史记录仅存本地）
  void _restoreHistory() {
    _loadState();
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Limit message count to prevent storage issues
      final messagesToSave = messages.length > 50 ? messages.sublist(messages.length - 50) : messages;
      final messagesJson = jsonEncode(messagesToSave.map((e) => e.toJson()).toList());
      await prefs.setString(_chatHistoryKey, messagesJson);
      print('AI Assistant Page: Chat history saved: ${messagesToSave.length} messages');

      // Verify save was successful
      final saved = prefs.getString(_chatHistoryKey);
      print('AI Assistant Page: Verification - saved data exists: ${saved != null}');
    } catch (e, st) {
      AppLogger.e('AI助手', e, st);
      print('AI Assistant Page: Error saving chat history - $e');
    }
  }

  @override
  void dispose() {
    _streamingText.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    _videoController?.removeListener(_onVideoPositionUpdate);
    _videoController?.dispose();
    // Save chat history when page is disposed as final backup
    _saveChatHistory();
    super.dispose();
  }

  void _onVideoPositionUpdate() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    final position = controller.value.position;
    final duration = controller.value.duration;
    if (duration.inMilliseconds <= 0) return;

    // Stop 100ms before natural end to avoid system beep
    final remaining = duration - position;
    if (remaining <= const Duration(milliseconds: 100) && remaining > Duration.zero) {
      controller.setVolume(0);
      controller.pause();
      controller.seekTo(duration);
    }
  }

  Future<void> _initWelcomeVideo() async {
    try {
      print('AI Assistant Page: Initializing welcome video from assets/images/hello2.mov');
      final controller = VideoPlayerController.asset(
        'assets/images/hello2.mov',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _videoController = controller;

      await controller.initialize();
      print('AI Assistant Page: Video initialized successfully');
      print('AI Assistant Page: Video size: ${controller.value.size}');
      print('AI Assistant Page: Video duration: ${controller.value.duration}');
      
      controller.setLooping(false);
      controller.setVolume(1);

      controller.addListener(_onVideoPositionUpdate);

      await controller.play();
      print('AI Assistant Page: Video started playing');

      if (!mounted) return;
      setState(() {
        isVideoLoading = false;
        welcomeVideoError = false;
      });
    } catch (e, st) {
      AppLogger.e('AI助手', e, st);
      print('AI Assistant Page: Error initializing welcome video - $e');
      print('AI Assistant Page: Error type: ${e.runtimeType}');
      if (!mounted) return;
      setState(() {
        welcomeVideoError = true;
        isVideoLoading = false;
      });
    }
  }

  void _enterChat() {
    if (!showWelcome) return;
    print('AI Assistant Page: _enterChat called');

    // 离开欢迎页时停掉小灵动画/声音，避免后台继续播放
    _pauseWelcomeVideo();

    setState(() {
      showWelcome = false;
    });

    // Mark welcome as seen when entering chat
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(_hasSeenWelcomeKey, true);
      print('AI Assistant Page: Welcome state marked as seen');
      // Also save empty chat history when first entering
      _saveChatHistory();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  /// 暂停小灵欢迎动画（离开欢迎页时调用，防止声音/视频在后台继续播放）
  void _pauseWelcomeVideo() {
    final c = _videoController;
    if (c != null && c.value.isInitialized && c.value.isPlaying) {
      c.pause();
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty || isTyping) return;

    if (showWelcome) {
      _enterChat();
    }

    setState(() {
      messages.add(_ChatMessage.user(text));
      _inputController.clear();
      isTyping = true;
      isThinking = true;
    });

    // Save chat history after user message is added
    _saveChatHistory();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // 改为真实问答：把用户问题交给后端规则引擎
    _askAndReply(text);
  }

  /// 小灵问答：请求后端规则引擎并按打字机效果渲染回答。
  /// 后端 /api/ai/chat/ask 为本地规则匹配（离线可用），后续换大模型只改后端。
  Future<void> _askAndReply(String question) async {
    final assistantIndex = messages.length;
    setState(() {
      messages.add(_ChatMessage.ai(blocks: const [], isStreaming: true));
    });

    try {
      final answer = await _aiApi.ask(question);
      if (!mounted) return;
      final script = AiScript(
        id: 'rule',
        generatedAtMs: DateTime.now().millisecondsSinceEpoch,
        blocks: [
          AiBlock(type: 'paragraph', delayMs: 100, data: {'text': answer}),
        ],
      );
      await _playScript(script, assistantIndex: assistantIndex);
    } on AiApiException catch (e, st) {
      AppLogger.e('AI助手', e, st);
      if (!mounted) return;
      setState(() {
        isThinking = false;
        isTyping = false;
        messages[assistantIndex] = messages[assistantIndex].copyWith(
          isStreaming: false,
          blocks: [_AiBlock.paragraph('小灵没能回答：${e.message}')],
        );
      });
    } catch (e, st) {
      AppLogger.e('AI助手', e, st);
      if (!mounted) return;
      setState(() {
        isThinking = false;
        isTyping = false;
        messages[assistantIndex] = messages[assistantIndex].copyWith(
          isStreaming: false,
          blocks: [_AiBlock.paragraph('网络异常，请稍后再试')],
        );
      });
    }
  }

  Future<void> _fetchAndPlayScript() async {
    final assistantIndex = messages.length;
    setState(() {
      messages.add(_ChatMessage.ai(blocks: const [], isStreaming: true));
    });

    try {
      final script = await _aiApi.fetchScript();
      if (!mounted) return;

      await _playScript(script, assistantIndex: assistantIndex);
    } on AiApiException catch (e, st) {
      AppLogger.e('AI助手', e, st);
      if (!mounted) return;
      setState(() {
        isThinking = false;
        isTyping = false;
        messages[assistantIndex] = messages[assistantIndex].copyWith(
          isStreaming: false,
          blocks: [
            _AiBlock.paragraph('获取脚本失败：${e.message}'),
          ],
        );
      });
    } catch (e, st) {
      AppLogger.e('AI助手', e, st);
      if (!mounted) return;
      setState(() {
        isThinking = false;
        isTyping = false;
        messages[assistantIndex] = messages[assistantIndex].copyWith(
          isStreaming: false,
          blocks: [
            _AiBlock.paragraph('网络异常，请稍后再试'),
          ],
        );
      });
    }
  }

  Future<void> _playScript(AiScript script, {required int assistantIndex}) async {
    for (final b in script.blocks) {
      if (!mounted) return;

      final jitter = 120 + math.Random().nextInt(220);
      final d = ((math.max(0, b.delayMs) + jitter) * _speedFactor).round();
      await Future<void>.delayed(Duration(milliseconds: d));
      if (!mounted) return;

      if (b.type == 'thinking') {
        setState(() {
          isThinking = true;
        });
        final title = (b.data['title'] as String?) ?? '完成思考';
        final text = (b.data['text'] as String?) ?? '';
        final collapsed = (b.data['collapsed'] as bool?) ?? true;
        setState(() {
          final msg = messages[assistantIndex];
          messages[assistantIndex] = msg.copyWith(
            blocks: [...msg.blocks, _AiBlock.thinking(title: title, text: text, collapsed: collapsed)],
          );
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        continue;
      }

      if (b.type == 'heading') {
        setState(() {
          isThinking = false;
          final msg = messages[assistantIndex];
          messages[assistantIndex] = msg.copyWith(
            blocks: [...msg.blocks, _AiBlock.heading((b.data['text'] as String?) ?? '')],
          );
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        continue;
      }

      if (b.type == 'table') {
        setState(() {
          isThinking = false;
        });
        final colsRaw = b.data['columns'];
        final rowsRaw = b.data['rows'];
        final cols = <String>[];
        if (colsRaw is List) {
          for (final c in colsRaw) {
            cols.add(c?.toString() ?? '');
          }
        }
        final rows = <Map<String, String>>[];
        if (rowsRaw is List) {
          for (final r in rowsRaw) {
            if (r is Map) {
              final m = <String, String>{};
              for (final entry in r.entries) {
                m[entry.key.toString()] = entry.value?.toString() ?? '';
              }
              rows.add(m);
            }
          }
        }
        setState(() {
          final msg = messages[assistantIndex];
          messages[assistantIndex] = msg.copyWith(
            blocks: [...msg.blocks, _AiBlock.table(columns: cols, rows: rows)],
          );
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        continue;
      }

      if (b.type == 'chart') {
        setState(() {
          isThinking = false;
        });
        final title = (b.data['title'] as String?) ?? '';
        final itemsRaw = b.data['items'];
        final items = <_ChartItem>[];
        if (itemsRaw is List) {
          for (final it in itemsRaw) {
            if (it is Map) {
              items.add(
                _ChartItem(
                  day: (it['day'] as String?) ?? '',
                  name: (it['name'] as String?) ?? '',
                  intensity: (it['intensity'] as String?) ?? '',
                  minutes: ((it['minutes'] as num?) ?? 0).toInt(),
                ),
              );
            }
          }
        }
        setState(() {
          final msg = messages[assistantIndex];
          messages[assistantIndex] = msg.copyWith(
            blocks: [...msg.blocks, _AiBlock.chart(title: title, items: items)],
          );
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        continue;
      }

      if (b.type == 'citations') {
        setState(() {
          isThinking = false;
        });
        final title = (b.data['title'] as String?) ?? '全部引用';
        final collapsed = (b.data['collapsed'] as bool?) ?? true;
        final itemsRaw = b.data['items'];
        final items = <_CitationItem>[];
        if (itemsRaw is List) {
          for (final it in itemsRaw) {
            if (it is Map) {
              items.add(
                _CitationItem(
                  index: ((it['index'] as num?) ?? 0).toInt(),
                  tag: (it['tag'] as String?) ?? '',
                  text: (it['text'] as String?) ?? '',
                ),
              );
            }
          }
        }
        setState(() {
          final msg = messages[assistantIndex];
          messages[assistantIndex] = msg.copyWith(
            blocks: [...msg.blocks, _AiBlock.citations(title: title, items: items, collapsed: collapsed)],
          );
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        continue;
      }

      if (b.type == 'paragraph') {
        setState(() {
          isThinking = false;
          isTyping = true;
        });
        final full = (b.data['text'] as String?) ?? '';

        // 先挂一个空段落占位，流式期间由 _streamingText 驱动气泡内小组件逐字刷新
        setState(() {
          final msg = messages[assistantIndex];
          messages[assistantIndex] = msg.copyWith(
            blocks: [...msg.blocks, _AiBlock.paragraph('')],
          );
        });

        await _runTypewriter(full);
        if (!mounted) return;

        // 流式结束后一次性把完整文本写入消息（此时才需要整页刷新一次）
        setState(() {
          final msg = messages[assistantIndex];
          final out = [...msg.blocks];
          out[out.length - 1] = out.last.copyWith(text: full);
          messages[assistantIndex] = msg.copyWith(blocks: out);
        });
        _streamingText.value = '';
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    }

    if (!mounted) return;
    setState(() {
      isThinking = false;
      isTyping = false;
      messages[assistantIndex] = messages[assistantIndex].copyWith(isStreaming: false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    
    // Save chat history after AI response is complete
    _saveChatHistory();
  }

  /// 【核心输出变量】打字机逐字输出驱动：
  /// 节奏公式与旧实现完全一致（base 4~10ms，每 42 字符额外 60ms，统一乘 _speedFactor），
  /// 仅把刷新范围从"整页 setState"缩小为"气泡内 Text"，避免逐字符整页重建造成掉帧
  Future<void> _runTypewriter(String full) async {
    for (var i = 0; i < full.length; i++) {
      if (!mounted) return;
      _streamingText.value = full.substring(0, i + 1);

      final base = (4 + math.Random().nextInt(7)); // faster typewriter delays
      final extra = (i % 42 == 0) ? 60 : 0;
      final stepDelay = ((base + extra) * _speedFactor).round();
      await Future<void>.delayed(Duration(milliseconds: stepDelay));
      if (i % 16 == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    }
  }

  /// 按住麦克风：开始真实录音（WAV / 16kHz / 单声道）
  Future<void> _onVoiceStart() async {
    try {
      if (!await _recorder.hasPermission()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要麦克风权限，请在系统设置中允许录音')),
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/ling_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      if (!mounted) return;
      setState(() => isRecording = true);
    } catch (e, st) {
      AppLogger.e('AI助手', e, st);
      if (!mounted) return;
      setState(() => isRecording = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('录音启动失败：$e')));
    }
  }

  /// 松开麦克风：停止录音 -> 上传 PC 端离线识别 -> 用识别文字向小灵提问
  Future<void> _onVoiceEnd() async {
    if (!isRecording) return;
    setState(() => isRecording = false);

    String? path;
    try {
      path = await _recorder.stop();
    } catch (e, st) {
      AppLogger.e('AI助手', e, st);
    }
    if (path == null || path.isEmpty || !mounted) return;

    if (showWelcome) _enterChat();
    setState(() {
      isTyping = true;
      isThinking = true;
    });
    _inputController.text = '正在识别语音…';

    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      if (bytes.length < 2000) {
        throw Exception('录音太短，请按住多说一会儿');
      }
      final resp = await http
          .post(Uri.parse(kSttUrl), headers: const {'Content-Type': 'audio/wav'}, body: bytes)
          .timeout(const Duration(seconds: 90));
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final text = (decoded['text'] as String?)?.trim() ?? '';
      if (!mounted) return;
      _inputController.clear();
      setState(() {
        isTyping = false;
        isThinking = false;
      });
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('没听清，请再说一次${decoded['error'] == null ? '' : '（${decoded['error']}）'}')),
        );
        return;
      }
      // 把识别出来的话作为用户消息显示，再走正常问答
      setState(() => messages.add(_ChatMessage.user(text)));
      _saveChatHistory();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      await _askAndReply(text);
    } catch (e, st) {
      AppLogger.e('AI助手', e, st);
      if (!mounted) return;
      _inputController.clear();
      setState(() {
        isTyping = false;
        isThinking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('语音识别失败：$e')));
    } finally {
      try {
        await File(path).delete();
      } catch (_) {}
    }
  }

  Future<void> _typeAndSend(String script) async {
    _enterChat();

    // 输入框文字变化由 TextEditingController 自行通知 TextField 刷新，
    // 无需 setState 重建整页；逐字 28ms 节奏保持不变
    for (var i = 0; i < script.length; i++) {
      if (!mounted) return;
      _inputController.text = script.substring(0, i + 1);
      _inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: _inputController.text.length),
      );
      await Future<void>.delayed(const Duration(milliseconds: 28));
    }

    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI助教'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: '最近对话',
            onPressed: _restoreHistory,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  Expanded(
                    child: showWelcome ? _buildWelcome() : _buildChat(),
                  ),
                  _InputArea(
                    controller: _inputController,
                    isTyping: isTyping,
                    onSend: _sendMessage,
                    onMore: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('更多（占位）')));
                    },
                    onVoiceStart: _onVoiceStart,
                    onVoiceEnd: _onVoiceEnd,
                  ),
                ],
              ),
            ),
            if (isRecording)
              Positioned(
                left: 0,
                right: 0,
                bottom: 92,
                child: const _VoiceWave(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Container(
      color: const Color(0xFFFCFCF7),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              // Vue 里点击头像触发播放/交互，这里做进入聊天
              _enterChat();
            },
            child: _WelcomeRobot(
              controller: _videoController,
              isLoading: isVideoLoading,
              hasError: welcomeVideoError,
            ),
          ),
          const SizedBox(height: 22),
          const Text('Hi，我是小灵', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
          const SizedBox(height: 14),
          const Text(
            '我升级了哦！快来体验为你特别定制的矫正计划和更多精彩内容吧！',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.55, color: Color(0xFF7F8C8D)),
          ),
        ],
      ),
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            itemCount: messages.length + (isThinking ? 1 : 0) + (!isTyping && !isThinking ? 0 : 0),
            itemBuilder: (context, index) {
              if (isThinking && index == messages.length) {
                return const _ThinkingMessage();
              }

              final msg = messages[index];
              return _MessageRow(message: msg, streamingText: _streamingText);
            },
          ),
        ),
        if (isTyping && !isThinking && !(messages.isNotEmpty && messages.last.isStreaming))
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: _TypingIndicatorRow(),
          ),
      ],
    );
  }
}

class _WelcomeRobot extends StatelessWidget {
  const _WelcomeRobot({
    required this.controller,
    required this.isLoading,
    required this.hasError,
  });

  final VideoPlayerController? controller;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x80FCFCF7), Color(0x80E6F0FA)],
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2196F3).withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 14)),
          BoxShadow(color: const Color(0xFF2196F3).withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipOval(
        child: hasError
            ? const _RobotFaceFallback()
            : Stack(
                fit: StackFit.expand,
                children: [
                  if (controller != null && controller!.value.isInitialized)
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller!.value.size.width,
                        height: controller!.value.size.height,
                        child: Opacity(
                          opacity: 0.95,
                          child: VideoPlayer(controller!),
                        ),
                      ),
                    )
                  else
                    const ColoredBox(color: Color(0x40BBDEFB)),
                  if (isLoading)
                    Container(
                      color: Colors.white.withValues(alpha: 0.92),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                          SizedBox(height: 10),
                          Text('视频加载中...', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _RobotFaceFallback extends StatelessWidget {
  const _RobotFaceFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF34495E)]),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RobotEye(),
          SizedBox(width: 18),
          _RobotEye(),
        ],
      ),
    );
  }
}

class _RobotEye extends StatelessWidget {
  const _RobotEye();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF00FF88),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00FF88).withValues(alpha: 0.45), blurRadius: 12),
        ],
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message, required this.streamingText});

  final _ChatMessage message;
  final ValueListenable<String> streamingText;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _Role.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) const _RobotMiniAvatar(),
          if (!isUser) const SizedBox(width: 10),
          Flexible(
            child: Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: _MessageBubble(message: message, streamingText: streamingText),
            ),
          ),
          if (isUser) const SizedBox(width: 10),
          if (isUser) const _UserAvatar(),
        ],
      ),
    );
  }
}

class _RobotMiniAvatar extends StatelessWidget {
  const _RobotMiniAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF34495E)]),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MiniEye(),
          SizedBox(width: 6),
          _MiniEye(),
        ],
      ),
    );
  }
}

class _MiniEye extends StatelessWidget {
  const _MiniEye();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFF00FF88),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00FF88).withValues(alpha: 0.30), blurRadius: 6),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFFFF5E62), Color(0xFFFF9966)]),
      ),
      alignment: Alignment.center,
      child: const Text('我', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.streamingText});

  final _ChatMessage message;
  final ValueListenable<String> streamingText;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _Role.user;

    final screenW = MediaQuery.sizeOf(context).width;
    final maxBubbleW = (screenW * 0.86).clamp(320.0, 520.0);

    final bg = isUser ? const Color(0xFFF8F8F8) : Colors.white;
    final border = isUser ? const Color(0xFFECECEC) : const Color(0xFFF0F0F0);

    return Container(
      constraints: BoxConstraints(maxWidth: maxBubbleW),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 6),
          bottomRight: Radius.circular(isUser ? 6 : 18),
        ),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: isUser
          ? Text(
              message.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Color(0xFF262626),
              ),
            )
          : _AiBubbleContent(blocks: message.blocks, streamingText: streamingText, isStreaming: message.isStreaming),
    );
  }
}

class _ThinkingMessage extends StatelessWidget {
  const _ThinkingMessage();

  @override
  Widget build(BuildContext context) {
    const steps = ['理解问题', '搜索医学文献、指南、药品说明书等', '从知识库获取用户的个性档案', '整理相关信息'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RobotMiniAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final step in steps)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('正在$step', style: const TextStyle(fontSize: 15, color: Color(0xFF495057), height: 1.35)),
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicatorRow extends StatelessWidget {
  const _TypingIndicatorRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RobotMiniAvatar(),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2F5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE9ECEF)),
          ),
          child: const _DotTyping(),
        ),
      ],
    );
  }
}

class _DotTyping extends StatefulWidget {
  const _DotTyping();

  @override
  State<_DotTyping> createState() => _DotTypingState();
}

class _DotTypingState extends State<_DotTyping> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        double scaleAt(double delay) {
          final x = (t - delay) % 1.0;
          final y = math.sin(x * math.pi);
          return 0.8 + y * 0.4;
        }

        Widget dot(double delay) {
          return Transform.translate(
            offset: Offset(0, -4 * (scaleAt(delay) - 0.8)),
            child: Transform.scale(
              scale: scaleAt(delay),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Color(0xFF00C6FF), shape: BoxShape.circle),
              ),
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(0.0),
            const SizedBox(width: 6),
            dot(0.2),
            const SizedBox(width: 6),
            dot(0.4),
          ],
        );
      },
    );
  }
}

class _InputArea extends StatelessWidget {
  const _InputArea({
    required this.controller,
    required this.isTyping,
    required this.onSend,
    required this.onMore,
    required this.onVoiceStart,
    required this.onVoiceEnd,
  });

  final TextEditingController controller;
  final bool isTyping;
  final VoidCallback onSend;
  final VoidCallback onMore;
  final VoidCallback onVoiceStart;
  final VoidCallback onVoiceEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFE9ECEF).withValues(alpha: 0.9))),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      // 监听输入框内容：仅重建本输入区（麦克风/发送按钮切换），
      // 逐字输入不再依赖整页 setState
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final text = controller.text;
          return Row(
            children: [
              InkWell(
                onTap: onMore,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFDEE2E6)),
                  ),
                  child: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF666666)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFDEE2E6)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: controller,
                    enabled: !isTyping,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '请输入您的问题...',
                      hintStyle: TextStyle(color: Color(0xFF9AA0A6), fontSize: 15),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (text.trim().isEmpty)
                GestureDetector(
                  onLongPressStart: (_) => onVoiceStart(),
                  onLongPressEnd: (_) => onVoiceEnd(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [Color(0xFFFF5E62), Color(0xFFFF9966)]),
                    ),
                    child: const Icon(Icons.mic_rounded, color: Colors.white),
                  ),
                )
              else
                InkWell(
                  onTap: isTyping ? null : onSend,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isTyping ? [const Color(0xFFA0A0A0), const Color(0xFFC0C0C0)] : [const Color(0xFFFF5E62), const Color(0xFFFF9966)],
                      ),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _VoiceWave extends StatefulWidget {
  const _VoiceWave();

  @override
  State<_VoiceWave> createState() => _VoiceWaveState();
}

class _VoiceWaveState extends State<_VoiceWave> {
  // 【核心输出变量】波形高度由组件内部定时器驱动，
  // 只刷新这 8 根波形条，不再整页 setState（旧实现 150ms 整页重建一次）
  final List<double> bars = [20, 30, 40, 50, 60, 40, 30, 20];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < bars.length; i++) {
          bars[i] = 20 + math.Random().nextInt(60).toDouble();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 18, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final h in bars) ...[
              Container(
                width: 4,
                height: h,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C6FF),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
            ]
          ],
        ),
      ),
    );
  }
}

enum _Role { user, ai }

class _ChatMessage {
  const _ChatMessage({
    required this.role,
    required this.content,
    required this.blocks,
    required this.isStreaming,
  });

  factory _ChatMessage.user(String text) => _ChatMessage(role: _Role.user, content: text, blocks: const [], isStreaming: false);
  factory _ChatMessage.ai({required List<_AiBlock> blocks, required bool isStreaming}) {
    return _ChatMessage(role: _Role.ai, content: '', blocks: blocks, isStreaming: isStreaming);
  }

  final _Role role;
  final String content;
  final List<_AiBlock> blocks;
  final bool isStreaming;

  _ChatMessage copyWith({String? content, List<_AiBlock>? blocks, bool? isStreaming}) {
    return _ChatMessage(
      role: role,
      content: content ?? this.content,
      blocks: blocks ?? this.blocks,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role.name,
      'content': content,
      'blocks': blocks.map((b) => b.toJson()).toList(),
      'isStreaming': isStreaming,
    };
  }

  factory _ChatMessage.fromJson(Map<String, dynamic> json) {
    final role = _Role.values.firstWhere(
      (e) => e.name == json['role'],
      orElse: () => _Role.ai,
    );
    final blocksJson = json['blocks'] as List<dynamic>?;
    final blocks = blocksJson?.map((e) => _AiBlock.fromJson(e as Map<String, dynamic>)).toList() ?? [];
    
    return _ChatMessage(
      role: role,
      content: json['content'] as String? ?? '',
      blocks: blocks,
      isStreaming: json['isStreaming'] as bool? ?? false,
    );
  }
}

class _AiBubbleContent extends StatelessWidget {
  const _AiBubbleContent({
    required this.blocks,
    required this.streamingText,
    this.isStreaming = false,
  });

  final List<_AiBlock> blocks;
  final ValueListenable<String> streamingText;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) {
      return const _DotTyping();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (isStreaming &&
              i == blocks.length - 1 &&
              blocks[i].type == _AiBlockType.paragraph &&
              (blocks[i].text ?? '').isEmpty)
            // 流式进行中的最后一段：由 ValueNotifier 驱动只刷新这一小段文本，
            // 逐字节奏与旧实现一致，但不再整页 setState
            ValueListenableBuilder<String>(
              valueListenable: streamingText,
              builder: (context, value, _) {
                return Text(
                  value,
                  style: const TextStyle(fontSize: 16, height: 1.7, color: Color(0xFF2C3E50), fontWeight: FontWeight.w500),
                );
              },
            )
          else
            blocks[i].build(context),
          const SizedBox(height: 10),
        ]
      ],
    );
  }
}

class _CitationItem {
  const _CitationItem({required this.index, required this.tag, required this.text});

  final int index;
  final String tag;
  final String text;

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'tag': tag,
      'text': text,
    };
  }

  factory _CitationItem.fromJson(Map<String, dynamic> json) {
    return _CitationItem(
      index: json['index'] as int? ?? 0,
      tag: json['tag'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }
}

class _ChartItem {
  const _ChartItem({required this.day, required this.name, required this.intensity, required this.minutes});

  final String day;
  final String name;
  final String intensity;
  final int minutes;

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'name': name,
      'intensity': intensity,
      'minutes': minutes,
    };
  }

  factory _ChartItem.fromJson(Map<String, dynamic> json) {
    return _ChartItem(
      day: json['day'] as String? ?? '',
      name: json['name'] as String? ?? '',
      intensity: json['intensity'] as String? ?? '',
      minutes: json['minutes'] as int? ?? 0,
    );
  }
}

enum _AiBlockType { paragraph, heading, thinking, table, chart, citations }

class _AiBlock {
  const _AiBlock._({
    required this.type,
    this.text,
    this.title,
    this.collapsed,
    this.columns,
    this.rows,
    this.chartItems,
    this.citations,
  });

  factory _AiBlock.paragraph(String text) => _AiBlock._(type: _AiBlockType.paragraph, text: text);

  factory _AiBlock.heading(String text) => _AiBlock._(type: _AiBlockType.heading, text: text);

  factory _AiBlock.thinking({required String title, required String text, required bool collapsed}) {
    return _AiBlock._(type: _AiBlockType.thinking, title: title, text: text, collapsed: collapsed);
  }

  factory _AiBlock.table({required List<String> columns, required List<Map<String, String>> rows}) {
    return _AiBlock._(type: _AiBlockType.table, columns: columns, rows: rows);
  }

  factory _AiBlock.chart({required String title, required List<_ChartItem> items}) {
    return _AiBlock._(type: _AiBlockType.chart, title: title, chartItems: items);
  }

  factory _AiBlock.citations({required String title, required List<_CitationItem> items, required bool collapsed}) {
    return _AiBlock._(type: _AiBlockType.citations, title: title, citations: items, collapsed: collapsed);
  }

  final _AiBlockType type;
  final String? text;
  final String? title;
  final bool? collapsed;
  final List<String>? columns;
  final List<Map<String, String>>? rows;
  final List<_ChartItem>? chartItems;
  final List<_CitationItem>? citations;

  _AiBlock copyWith({String? text}) {
    return _AiBlock._(
      type: type,
      text: text ?? this.text,
      title: title,
      collapsed: collapsed,
      columns: columns,
      rows: rows,
      chartItems: chartItems,
      citations: citations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'text': text,
      'title': title,
      'collapsed': collapsed,
      'columns': columns,
      'rows': rows,
      'chartItems': chartItems?.map((e) => e.toJson()).toList(),
      'citations': citations?.map((e) => e.toJson()).toList(),
    };
  }

  factory _AiBlock.fromJson(Map<String, dynamic> json) {
    final type = _AiBlockType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => _AiBlockType.paragraph,
    );
    
    final chartItemsJson = json['chartItems'] as List<dynamic>?;
    final chartItems = chartItemsJson?.map((e) => _ChartItem.fromJson(e as Map<String, dynamic>)).toList();
    
    final citationsJson = json['citations'] as List<dynamic>?;
    final citations = citationsJson?.map((e) => _CitationItem.fromJson(e as Map<String, dynamic>)).toList();
    
    final rowsJson = json['rows'] as List<dynamic>?;
    final rows = rowsJson?.map((e) {
      if (e is Map<String, dynamic>) {
        return e.map((key, value) => MapEntry(key, value?.toString() ?? ''));
      } else if (e is Map<String, String>) {
        return e;
      }
      return <String, String>{};
    }).toList();
    
    final columnsJson = json['columns'] as List<dynamic>?;
    final columns = columnsJson?.map((e) => e?.toString() ?? '').toList();
    
    return _AiBlock._(
      type: type,
      text: json['text'] as String?,
      title: json['title'] as String?,
      collapsed: json['collapsed'] as bool?,
      columns: columns,
      rows: rows,
      chartItems: chartItems,
      citations: citations,
    );
  }

  Widget build(BuildContext context) {
    switch (type) {
      case _AiBlockType.heading:
        return Text(
          (text ?? '').trim(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827), height: 1.25),
        );
      case _AiBlockType.paragraph:
        return Text(
          (text ?? '').trim(),
          style: const TextStyle(fontSize: 16, height: 1.7, color: Color(0xFF2C3E50), fontWeight: FontWeight.w500),
        );
      case _AiBlockType.thinking:
        return _FoldCard(
          title: title ?? '完成思考',
          collapsed: collapsed ?? true,
          child: Text(
            (text ?? '').trim(),
            style: const TextStyle(fontSize: 15, height: 1.65, color: Color(0xFF334155), fontWeight: FontWeight.w500),
          ),
        );
      case _AiBlockType.table:
        return _TableCard(
          columns: columns ?? const [],
          rows: rows ?? const [],
        );
      case _AiBlockType.chart:
        return _ChartCard(
          title: title ?? '',
          items: chartItems ?? const [],
        );
      case _AiBlockType.citations:
        return _CitationsCard(
          title: title ?? '全部引用',
          collapsed: collapsed ?? true,
          items: citations ?? const [],
        );
    }
  }
}

class _FoldCard extends StatefulWidget {
  const _FoldCard({required this.title, required this.collapsed, required this.child});

  final String title;
  final bool collapsed;
  final Widget child;

  @override
  State<_FoldCard> createState() => _FoldCardState();
}

class _FoldCardState extends State<_FoldCard> {
  late bool _collapsed;

  @override
  void initState() {
    super.initState();
    _collapsed = widget.collapsed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _collapsed = !_collapsed),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Text(widget.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const Spacer(),
                  Transform.rotate(
                    angle: _collapsed ? 0 : math.pi,
                    child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ),
          if (!_collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.columns, required this.rows});

  final List<String> columns;
  final List<Map<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    final cols = columns.isEmpty ? const ['时间', '训练内容', '时长', '强度', '目标', '注意事项'] : columns;

    Color intensityColor(String v) {
      final s = v.trim();
      if (s.contains('中')) return const Color(0xFFFF8A00);
      if (s.contains('低') || s.contains('轻')) return const Color(0xFF22C55E);
      return const Color(0xFF3B82F6);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: const Color(0xFFFFF2E5),
              child: const Text(
                '专项脊柱侧弯康复训练计划',
                style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827), fontSize: 15),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFFF8A00)),
                headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF111827), height: 1.4, fontWeight: FontWeight.w600),
                columnSpacing: 18,
                columns: [
                  for (final c in cols)
                    DataColumn(
                      label: Text(c),
                    ),
                ],
                rows: [
                  for (final r in rows)
                    DataRow(
                      cells: [
                        DataCell(Text(r['date'] ?? '')),
                        DataCell(Text(r['content'] ?? '')),
                        DataCell(Text(r['duration'] ?? '')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: intensityColor(r['intensity'] ?? '').withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              r['intensity'] ?? '',
                              style: TextStyle(color: intensityColor(r['intensity'] ?? ''), fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        DataCell(Text(r['goal'] ?? '')),
                        DataCell(Text(r['notes'] ?? '')),
                      ],
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

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.items});

  final String title;
  final List<_ChartItem> items;

  static const Color _orange = Color(0xFFFF8A00);
  static const Color _orangeLight = Color(0xFFFFB347);
  static const Color _green = Color(0xFF22C55E);
  static const Color _greenLight = Color(0xFF4ADE80);

  int _maxMinutes() {
    var m = 1;
    for (final it in items) {
      if (it.minutes > m) m = it.minutes;
    }
    return m;
  }

  bool _isMedium(_ChartItem it) => it.intensity.trim().contains('中');

  LinearGradient _barGradient(_ChartItem it) {
    if (_isMedium(it)) {
      return const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [_orange, _orangeLight],
      );
    }
    return const LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [_green, _greenLight],
    );
  }

  Color _barShadow(_ChartItem it) => (_isMedium(it) ? _orange : _green).withValues(alpha: 0.35);

  @override
  Widget build(BuildContext context) {
    final maxM = _maxMinutes();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBF5), Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
        ),
        border: Border.all(color: const Color(0xFFE8ECF1)),
        boxShadow: [
          BoxShadow(color: _orange.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 10)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [_orange.withValues(alpha: 0.15), _green.withValues(alpha: 0.12)],
                    ),
                  ),
                  child: const Icon(Icons.bar_chart_rounded, color: _orange, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                          height: 1.25,
                        ),
                      ),
                      ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendChip(color: _orange, label: '中等强度'),
                const SizedBox(width: 16),
                _legendChip(color: _green, label: '低强度'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: SizedBox(
              height: 188,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const chartH = 118.0;
                  final slotW = constraints.maxWidth / (items.isEmpty ? 1 : items.length);

                  return Stack(
                    children: [
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 36,
                        height: chartH,
                        child: CustomPaint(
                          painter: _ChartGridPainter(lineCount: 4),
                          size: Size.infinite,
                        ),
                      ),
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 35,
                        child: Container(height: 1.5, color: const Color(0xFFE2E8F0)),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final it in items) Expanded(child: _barColumn(it, maxM, chartH, slotW)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _legendChip({required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color.withValues(alpha: 0.95))),
        ],
      ),
    );
  }

  Widget _barColumn(_ChartItem it, int maxM, double chartH, double slotW) {
    final ratio = maxM <= 0 ? 0.0 : (it.minutes / maxM).clamp(0.0, 1.0);
    final barH = it.minutes <= 0 ? 6.0 : (14 + chartH * ratio);
    final barW = (slotW * 0.42).clamp(14.0, 28.0);
    final accent = _isMedium(it) ? _orange : _green;

    return SizedBox(
      height: 188,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${it.minutes} min',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: accent, height: 1.0),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: barW,
            height: barH,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              gradient: _barGradient(it),
              boxShadow: [
                BoxShadow(color: _barShadow(it), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              it.day,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartGridPainter extends CustomPainter {
  const _ChartGridPainter({required this.lineCount});

  final int lineCount;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 1; i <= lineCount; i++) {
      final y = size.height * (1 - i / (lineCount + 1));
      final path = Path();
      const dash = 5.0;
      const gap = 4.0;
      var x = 0.0;
      while (x < size.width) {
        path.moveTo(x, y);
        path.lineTo((x + dash).clamp(0, size.width), y);
        x += dash + gap;
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CitationsCard extends StatelessWidget {
  const _CitationsCard({required this.title, required this.collapsed, required this.items});

  final String title;
  final List<_CitationItem> items;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return _FoldCard(
      title: title,
      collapsed: collapsed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${it.index}. ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (it.tag.trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(it.tag, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                          ),
                        const SizedBox(height: 6),
                        Text(it.text, style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
                      ],
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
