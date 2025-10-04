import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:confetti/confetti.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personalized Greeting App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const GreetingFlowPage(),
    );
  }
}

class GreetingFlowPage extends StatefulWidget {
  const GreetingFlowPage({super.key});
  @override
  State<GreetingFlowPage> createState() => _GreetingFlowPageState();
}

class _GreetingFlowPageState extends State<GreetingFlowPage>
    with TickerProviderStateMixin {
  // Video
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;

  // Popup animation controllers
  late AnimationController _popupAnimController;
  late Animation<double> _popupFade;
  late Animation<double> _popupScale;
  bool _isPopupVisible = true;
  Timer? _autoDismissTimer;

  // Input / validation
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  bool _showInput = false;

  // Confetti
  late ConfettiController _confettiController;
  bool _showWelcome = false; // triggers animated welcome text

  @override
  void initState() {
    super.initState();

    // --- Video setup (muted, looping) ---
    // Make sure you put a video at assets/videos/bg.mp4 (see pubspec)
    _videoController = VideoPlayerController.asset('assets/videos/Animated.mp4')
      ..initialize().then((_) {
        // autoplay, loop, muted
        _videoController.setLooping(true);
        _videoController.setVolume(0.0);
        _videoController.play();
        setState(() => _videoInitialized = true);
      });

    // --- Popup animations (fade-in + scale-up) ---
    _popupAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _popupFade = CurvedAnimation(
      parent: _popupAnimController,
      curve: Curves.easeOut,
    );

    _popupScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _popupAnimController, curve: Curves.elasticOut),
    );

    // start popup entrance
    _popupAnimController.forward();

    // auto-dismiss after 10 seconds (non-blocking)
    _autoDismissTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isPopupVisible) {
        _dismissPopup();
      }
    });

    // Confetti controller (short burst)
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _popupAnimController.dispose();
    _autoDismissTimer?.cancel();
    _nameController.dispose();
    _nameFocus.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _dismissPopup() {
    // animate popup out (fade + scale), then show input area
    _popupAnimController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _isPopupVisible = false;
        _showInput = true;
      });
      // give frame time, then request focus to the TextField
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _nameFocus.requestFocus();
        }
      });
    });
  }

  void _onSubmitName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name to continue.')),
      );
      return;
    }

    // success -> show confetti and welcome text
    setState(() => _showWelcome = true);
    _confettiController.play();

    // optionally clear focus
    _nameFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Transparent background so video shows full-screen
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ===== Background video layer (fills screen) =====
          Positioned.fill(
            child: _videoInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  )
                : Container(color: Colors.black),
          ),

          // ===== A subtle dark overlay so UI is readable =====
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),

          // ===== Main UI column centered vertically =====
          Positioned.fill(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 36,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App title (small, visible above)
                      Text(
                        'Personalized Greeting App',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Image.asset(
                        "assets/GW.png", // 👈 CHANGE HERE
                        height: 120,
                      ),
                      // Card with Icon + description (always visible)
                      Card(
                        color: Colors.white.withOpacity(0.9),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.account_circle,
                                size: 44,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Enter your name to receive a personalized greeting.',
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Input area — only shown after popup dismiss; uses autofocus
                      if (_showInput) ...[
                        TextField(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          autofocus: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.92),
                            labelText: 'Enter your name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: size.width * 0.6,
                          child: ElevatedButton(
                            onPressed: _onSubmitName,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Submit',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ] else
                        // placeholder hint while popup is visible (non-blocking)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28.0),
                          child: Text(
                            'Please wait for the welcome popup (or close it) to proceed.',
                            style: GoogleFonts.poppins(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Animated Welcome message + confetti overlays on top area
                      if (_showWelcome)
                        Column(
                          children: [
                            // Confetti (explosion from top center)
                            SizedBox(
                              height: 120,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child: ConfettiWidget(
                                      confettiController: _confettiController,
                                      blastDirectionality:
                                          BlastDirectionality.explosive,
                                      shouldLoop: false,
                                      emissionFrequency: 0.02,
                                      numberOfParticles: 30,
                                      maxBlastForce: 25,
                                      minBlastForce: 8,
                                      gravity: 0.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Animated large welcome text
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.6, end: 1.0),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.elasticOut,
                              builder: (context, scale, child) {
                                return Transform.scale(
                                  scale: scale,
                                  child: child,
                                );
                              },
                              child: Text(
                                'Welcome, ${_nameController.text.trim()}!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    const Shadow(
                                      offset: Offset(2, 2),
                                      blurRadius: 6,
                                      color: Colors.black45,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ===== Popup modal (centered) with fade+scale entrance =====
          if (_isPopupVisible)
            Positioned.fill(
              child: Center(
                child: FadeTransition(
                  opacity: _popupFade,
                  child: ScaleTransition(
                    scale: _popupScale,
                    child: _buildPopupCard(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPopupCard() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Card
            Card(
              elevation: 14,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Welcome to the Personalized Greeting App!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You can close this message or it will automatically disappear after 10 seconds.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _dismissPopup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Get started',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Close icon at top-right of the card
            Positioned(
              top: -10,
              right: -10,
              child: IconButton(
                onPressed: _dismissPopup,
                icon: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 6),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.black87,
                  ),
                ),
                tooltip: 'Close',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
