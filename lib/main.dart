import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterGemma.initialize(inferenceEngines: const [LiteRtLmEngine()]);

  runApp(const GemmaChatApp());
}

class GemmaChatApp extends StatelessWidget {
  const GemmaChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gemma Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();

  final List<(bool, String)> _messages = [];
  bool _loading = true;
  String _status = 'Initializing...';
  double _progress = 0;
  dynamic _session;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      setState(() {
        _status = 'Installing Gemma 4...';
      });

      await FlutterGemma.installModel(
            modelType: ModelType.gemma4,
            fileType: ModelFileType.litertlm,
          )
          .fromNetwork(
            'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
            token: const String.fromEnvironment('HUGGINGFACE_TOKEN'),
            foreground: true,
          )
          .withProgress((progress) {
            if (mounted) {
              setState(() {
                _progress = progress / 100;
                _status =
                    'Downloading Gemma 4... ${progress.toStringAsFixed(1)}%';
              });
            }
          })
          .install();

      setState(() {
        _status = 'Loading Gemma 4...';
      });

      final model = await FlutterGemma.getActiveModel(
        maxTokens: 2048,
        preferredBackend: PreferredBackend.gpu,
      );

      _session = await model.createSession();

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gemma 4 Local Chat')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(_status, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Gemma 4 Local Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final (isUser, message) = _messages[index];

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isUser
                        ? Text(message)
                        : MarkdownBody(data: message, selectable: true),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Ask Gemma something...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _session == null) {
      return;
    }

    _controller.clear();

    // Add user's message
    setState(() {
      _messages.add((true, text));

      // Add an empty assistant message that we'll progressively fill
      _messages.add((false, ''));
    });

    try {
      await _session.addQueryChunk(Message(text: text, isUser: true));

      var response = '';

      await for (final chunk in _session.getResponseAsync()) {
        response += chunk;

        if (!mounted) {
          return;
        }

        setState(() {
          // Replace the empty/in-progress assistant message
          _messages[_messages.length - 1] = (false, response);
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _messages[_messages.length - 1] = (false, 'Error: $e');
      });
    }
  }
}
