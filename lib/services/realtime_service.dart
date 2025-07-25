import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class RealtimeService {
  static Timer? _updateTimer;
  static bool _isRunning = false;
  static final List<Function> _listeners = [];

  /// Start real-time updates
  static void startRealtimeUpdates() {
    if (_isRunning) return;
    
    _isRunning = true;
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _notifyListeners();
    });
  }

  /// Stop real-time updates
  static void stopRealtimeUpdates() {
    _isRunning = false;
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// Add a listener for real-time updates
  static void addListener(Function callback) {
    if (!_listeners.contains(callback)) {
      _listeners.add(callback);
    }
  }

  /// Remove a listener
  static void removeListener(Function callback) {
    _listeners.remove(callback);
  }

  /// Notify all listeners
  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Force an immediate update
  static void forceUpdate() {
    _notifyListeners();
  }
}

/// Mixin for widgets that need real-time updates
mixin RealtimeUpdatesMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    RealtimeService.addListener(_onRealtimeUpdate);
  }

  @override
  void dispose() {
    RealtimeService.removeListener(_onRealtimeUpdate);
    super.dispose();
  }

  void _onRealtimeUpdate() {
    if (mounted) {
      setState(() {});
    }
  }
}

/// Widget that provides animated transitions for data updates
class AnimatedDataWidget extends StatefulWidget {
  final Widget child;
  final Duration animationDuration;
  final Curve animationCurve;

  const AnimatedDataWidget({
    super.key,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
  });

  @override
  State<AnimatedDataWidget> createState() => _AnimatedDataWidgetState();
}

class _AnimatedDataWidgetState extends State<AnimatedDataWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Widget that provides smooth transitions when data changes
class SmoothTransitionWidget extends StatefulWidget {
  final Widget child;
  final Duration transitionDuration;
  final Curve transitionCurve;

  const SmoothTransitionWidget({
    super.key,
    required this.child,
    this.transitionDuration = const Duration(milliseconds: 200),
    this.transitionCurve = Curves.easeInOut,
  });

  @override
  State<SmoothTransitionWidget> createState() => _SmoothTransitionWidgetState();
}

class _SmoothTransitionWidgetState extends State<SmoothTransitionWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Widget? _currentChild;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.transitionCurve,
    ));
    _currentChild = widget.child;
  }

  @override
  void didUpdateWidget(SmoothTransitionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      _animateTransition();
    }
  }

  void _animateTransition() async {
    // Fade out
    await _controller.reverse();
    
    // Update child
    setState(() {
      _currentChild = widget.child;
    });
    
    // Fade in
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: _currentChild,
        );
      },
    );
  }
}

/// Hook for real-time data updates
class RealtimeDataHook {
  static void useRealtimeUpdates(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Start real-time updates if not already running
    RealtimeService.startRealtimeUpdates();
    
    // Add listener for app state changes
    appState.addListener(() {
      if (context.mounted) {
        // Trigger rebuild when app state changes
        (context as Element).markNeedsBuild();
      }
    });
  }
}

/// Extension for easier real-time updates
extension RealtimeExtensions on Widget {
  Widget withRealtimeUpdates() {
    return AnimatedDataWidget(child: this);
  }

  Widget withSmoothTransitions() {
    return SmoothTransitionWidget(child: this);
  }
} 