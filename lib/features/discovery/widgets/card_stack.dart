import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../data/models/movie.dart';
import '../../../shared/widgets/shimmer_card.dart';
import '../../detail/widgets/movie_detail_sheet.dart';
import '../../unwatched/providers/unwatched_provider.dart';
import '../../watched/providers/watched_provider.dart';
import '../../watchlist/providers/watchlist_provider.dart';
import '../providers/movies_provider.dart';
import '../providers/search_provider.dart';
import '../providers/seen_provider.dart';
import 'action_buttons.dart';
import 'swipe_card.dart';

enum _AnimMode { none, snapBack, flyOff }

/// What a completed swipe does with the front card.
enum _SwipeAction { skip, watchlist, watched, unwatched }

/// Manages the swipeable deck: the gesture-driven front card, the scaled
/// back card, swipe-off / snap-back animations, and the action buttons.
class CardStack extends ConsumerStatefulWidget {
  const CardStack({super.key});

  @override
  ConsumerState<CardStack> createState() => _CardStackState();
}

class _CardStackState extends ConsumerState<CardStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  Offset _drag = Offset.zero;
  Offset _releaseOffset = Offset.zero;
  Offset _flyTarget = Offset.zero;
  _AnimMode _mode = _AnimMode.none;
  bool _dragging = false;
  bool _showHints = false;
  Movie? _swipingMovie;
  _SwipeAction _swipingAction = _SwipeAction.skip;

  static const _swipeThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this)
      ..addListener(_onTick)
      ..addStatusListener(_onStatus);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onTick() => setState(() {});

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_mode == _AnimMode.flyOff) {
      _completeSwipe();
    } else if (_mode == _AnimMode.snapBack) {
      setState(() {
        _mode = _AnimMode.none;
        _drag = Offset.zero;
      });
    }
  }

  /// The card's rendered offset for the current frame.
  Offset get _currentOffset {
    switch (_mode) {
      case _AnimMode.none:
        return _drag;
      case _AnimMode.snapBack:
        return _releaseOffset * _anim.value;
      case _AnimMode.flyOff:
        return Offset.lerp(_releaseOffset, _flyTarget, _anim.value)!;
    }
  }

  void _onPanStart(DragStartDetails _) {
    if (_mode != _AnimMode.none) return;
    _dragging = true;
    // Reveal the direction guide while swiping (mobile has no hover).
    if (!_showHints) setState(() => _showHints = true);
  }

  void _setHints(bool value) {
    if (_showHints == value || (_mode != _AnimMode.none && value)) return;
    setState(() => _showHints = value);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    setState(() => _drag += d.delta);
  }

  void _onPanEnd(DragEndDetails d) {
    if (!_dragging) return;
    _dragging = false;
    _showHints = false;
    final dx = _drag.dx;
    final dy = _drag.dy;
    if (dy.abs() > dx.abs() && dy.abs() > _swipeThreshold) {
      // Vertical swipe: up = watched, down = unwatched.
      _flyOff(action: dy < 0 ? _SwipeAction.watched : _SwipeAction.unwatched);
    } else if (dx.abs() > _swipeThreshold) {
      _flyOff(action: dx > 0 ? _SwipeAction.watchlist : _SwipeAction.skip);
    } else {
      _snapBack();
    }
  }

  void _snapBack() {
    _releaseOffset = _drag;
    _mode = _AnimMode.snapBack;
    final sim = SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 200, damping: 20),
      1.0, // start
      0.0, // end
      0.0, // velocity
    );
    _anim.animateWith(sim);
  }

  void _flyOff({required _SwipeAction action, Movie? movie}) {
    final deck = ref.read(moviesProvider).valueOrNull;
    final top = movie ?? (deck != null && deck.isNotEmpty ? deck.first : null);
    if (top == null) return;

    _swipingMovie = top;
    _swipingAction = action;
    final size = MediaQuery.of(context).size;

    if (_drag != Offset.zero) {
      _releaseOffset = _drag;
    } else {
      // Programmatic (button): give the card a starting nudge in its direction.
      _releaseOffset = switch (action) {
        _SwipeAction.watchlist => const Offset(1, 0),
        _SwipeAction.skip => const Offset(-1, 0),
        _SwipeAction.watched => const Offset(0, -1),
        _SwipeAction.unwatched => const Offset(0, 1),
      };
    }

    _flyTarget = switch (action) {
      _SwipeAction.watchlist =>
        Offset(size.width * 1.6, _releaseOffset.dy - 40),
      _SwipeAction.skip =>
        Offset(-size.width * 1.6, _releaseOffset.dy - 40),
      _SwipeAction.watched =>
        Offset(_releaseOffset.dx, -size.height * 1.4),
      _SwipeAction.unwatched =>
        Offset(_releaseOffset.dx, size.height * 1.4),
    };
    _mode = _AnimMode.flyOff;
    _anim.duration = const Duration(milliseconds: 250);
    _anim.value = 0;
    _anim.animateTo(1.0, curve: Curves.easeInCubic);
  }

  void _completeSwipe() {
    HapticFeedback.lightImpact();
    final movie = _swipingMovie;
    final action = _swipingAction;

    // Reset transform state before the deck shifts.
    setState(() {
      _mode = _AnimMode.none;
      _drag = Offset.zero;
      _swipingMovie = null;
    });

    if (movie != null) {
      // The list providers each enforce mutual exclusivity and mark the movie
      // seen, so it never resurfaces in the deck.
      switch (action) {
        case _SwipeAction.watchlist:
          ref.read(watchlistProvider.notifier).add(movie);
        case _SwipeAction.watched:
          ref.read(watchedProvider.notifier).add(movie);
        case _SwipeAction.unwatched:
          ref.read(unwatchedProvider.notifier).add(movie);
        case _SwipeAction.skip:
          // Record the skip so it never resurfaces.
          ref.read(seenMoviesProvider.notifier).markSeen(movie.id);
      }
    }
    ref.read(moviesProvider.notifier).removeTop();
  }

  // ---- Programmatic actions (action buttons) -----------------------------

  void _programmaticSwipe(_SwipeAction action) {
    if (_mode != _AnimMode.none) return;
    _drag = Offset.zero;
    _flyOff(action: action);
  }

  void _openInfo(Movie movie) {
    showMovieDetailSheet(context, ref, movie, heroTag: 'poster-${movie.id}');
  }

  // ------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(moviesProvider);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return async.when(
                  loading: () => _cardFrame(constraints,
                      child: const ShimmerCard()),
                  error: (e, _) => _ErrorState(
                    message: e.toString(),
                    onRetry: () =>
                        ref.read(moviesProvider.notifier).refresh(),
                  ),
                  data: (deck) {
                    if (deck.isEmpty) {
                      final notifier = ref.read(moviesProvider.notifier);
                      if (notifier.isFetchingMore) {
                        return _cardFrame(constraints,
                            child: const ShimmerCard());
                      }
                      return _EmptyState(
                        searching: ref.watch(isSearchingProvider),
                        onRefresh: () => notifier.refresh(),
                      );
                    }
                    return _buildDeck(constraints, deck);
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 18),
        Builder(builder: (context) {
          final deck = async.valueOrNull ?? const [];
          final hasCard = deck.isNotEmpty && _mode != _AnimMode.flyOff;
          return ActionButtons(
            enabled: hasCard,
            onSkip: () => _programmaticSwipe(_SwipeAction.skip),
            onWatched: () => _programmaticSwipe(_SwipeAction.watched),
            onUnwatched: () => _programmaticSwipe(_SwipeAction.unwatched),
            onSave: () => _programmaticSwipe(_SwipeAction.watchlist),
            onInfo: () {
              if (deck.isNotEmpty) _openInfo(deck.first);
            },
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Target card size: ~85% width / ~58% height, capped to the available area.
  Size _frameSize(BoxConstraints constraints) {
    final size = MediaQuery.of(context).size;
    final w = (size.width * 0.85).clamp(0.0, constraints.maxWidth);
    final maxH = constraints.maxHeight.isFinite
        ? constraints.maxHeight - 12
        : size.height * 0.58;
    final h = (size.height * 0.58).clamp(0.0, maxH);
    return Size(w, h);
  }

  /// Sizes a card to the frame, centered.
  Widget _cardFrame(BoxConstraints constraints, {required Widget child}) {
    final frame = _frameSize(constraints);
    return SizedBox(width: frame.width, height: frame.height, child: child);
  }

  Widget _buildDeck(BoxConstraints constraints, List<Movie> deck) {
    final offset = _currentOffset;
    final screen = MediaQuery.of(context).size;
    final distance = offset.distance;
    final maxDist = screen.width * 0.5;
    final frontProgress = (distance / maxDist).clamp(0.0, 1.0);

    final front = deck[0];
    final back = deck.length > 1 ? deck[1] : null;
    final backScale = 0.95 + 0.05 * frontProgress;
    final backTranslateY = 12.0 * (1 - frontProgress);

    // The guide follows the card a little, but its translation is clamped
    // (symmetrically, so the top/bottom cues stay visible just like the
    // left/right ones) and never slides a cue out of the frame.
    const maxShift = 30.0;
    final hintOffset = Offset(
      offset.dx.clamp(-maxShift, maxShift),
      offset.dy.clamp(-maxShift, maxShift),
    );

    return _cardFrame(
      constraints,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back card
          if (back != null)
            Transform.translate(
              offset: Offset(0, backTranslateY),
              child: Transform.scale(
                scale: backScale,
                child: SwipeCard(
                  key: ValueKey('back-${back.id}'),
                  movie: back,
                ),
              ),
            ),

          // Front card
          MouseRegion(
            onEnter: (_) => _setHints(true),
            onExit: (_) => _setHints(false),
            child: GestureDetector(
              onTap: _mode == _AnimMode.none ? () => _openInfo(front) : null,
              onLongPressStart: (_) => _setHints(true),
              onLongPressEnd: (_) => _setHints(false),
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Transform.translate(
                offset: offset,
                child: Transform.rotate(
                  angle: offset.dx / 300,
                  child: SwipeCard(
                    key: ValueKey('front-${front.id}'),
                    movie: front,
                    heroTag: 'poster-${front.id}',
                  ),
                ),
              ),
            ),
          ),

          // Swipe-direction guide: follows the card but stays on screen.
          if (_showHints)
            Positioned.fill(
              child: IgnorePointer(
                child: Transform.translate(
                  offset: hintOffset,
                  child: _SwipeHints(dragX: offset.dx, dragY: offset.dy),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh, this.searching = false});
  final VoidCallback onRefresh;
  final bool searching;

  @override
  Widget build(BuildContext context) {
    if (searching) {
      return _CenteredState(
        icon: Icons.search_off,
        title: 'No matches found',
        subtitle: 'Try a different title or clear the search.',
        buttonLabel: 'Refresh',
        onPressed: onRefresh,
      );
    }
    return _CenteredState(
      icon: Icons.movie_filter_outlined,
      title: "You've seen it all!",
      subtitle: 'Refresh to start the deck over.',
      buttonLabel: 'Refresh',
      onPressed: onRefresh,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.error_outline,
      title: 'Something went wrong',
      subtitle: message,
      buttonLabel: 'Retry',
      onPressed: onRetry,
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 18),
          Text(title,
              textAlign: TextAlign.center, style: AppText.sectionTitle),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// The swipe-direction guide. At rest (peek) all four cues show over a dim
/// scrim; once a drag commits to a direction only that one remains.
class _SwipeHints extends StatelessWidget {
  const _SwipeHints({required this.dragX, required this.dragY});

  final double dragX;
  final double dragY;

  @override
  Widget build(BuildContext context) {
    const threshold = 14.0;
    String? active;
    if (dragX.abs() >= threshold || dragY.abs() >= threshold) {
      if (dragX.abs() >= dragY.abs()) {
        active = dragX > 0 ? 'watchlist' : 'skip';
      } else {
        active = dragY < 0 ? 'watched' : 'unwatched';
      }
    }
    final showAll = active == null;
    bool show(String key) => showAll || active == key;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        // Dim only during the all-directions peek; keep the poster clear while
        // actively swiping toward one side.
        color:
            showAll ? Colors.black.withValues(alpha: 0.45) : Colors.transparent,
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            if (show('watched'))
              const Align(
                alignment: Alignment.topCenter,
                child: _HintCue(
                  axis: Axis.vertical,
                  arrow: Icons.keyboard_double_arrow_up_rounded,
                  label: 'Watched',
                  color: AppColors.watchedBlue,
                  arrowFirst: true,
                ),
              ),
            if (show('unwatched'))
              const Align(
                alignment: Alignment.bottomCenter,
                child: _HintCue(
                  axis: Axis.vertical,
                  arrow: Icons.keyboard_double_arrow_down_rounded,
                  label: 'Unwatched',
                  color: AppColors.unwatchedPurple,
                  arrowFirst: false,
                ),
              ),
            if (show('skip'))
              const Align(
                alignment: Alignment.centerLeft,
                child: _HintCue(
                  axis: Axis.horizontal,
                  arrow: Icons.keyboard_double_arrow_left_rounded,
                  label: 'Skip',
                  color: AppColors.accent,
                  arrowFirst: true,
                ),
              ),
            if (show('watchlist'))
              const Align(
                alignment: Alignment.centerRight,
                child: _HintCue(
                  axis: Axis.horizontal,
                  arrow: Icons.keyboard_double_arrow_right_rounded,
                  label: 'Watchlist',
                  color: AppColors.saveGreen,
                  arrowFirst: false,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One arrow + label swipe cue.
class _HintCue extends StatelessWidget {
  const _HintCue({
    required this.axis,
    required this.arrow,
    required this.label,
    required this.color,
    required this.arrowFirst,
  });

  final Axis axis;
  final IconData arrow;
  final String label;
  final Color color;
  final bool arrowFirst;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(arrow, color: color, size: 30);
    final text = Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
    );

    final children = arrowFirst
        ? [icon, const SizedBox(width: 4, height: 2), text]
        : [text, const SizedBox(width: 4, height: 2), icon];

    final content = axis == Axis.vertical
        ? Column(mainAxisSize: MainAxisSize.min, children: children)
        : Row(mainAxisSize: MainAxisSize.min, children: children);

    // A dark pill with a colored border so the cue stays readable over any
    // poster background.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.9), width: 1.5),
      ),
      child: content,
    );
  }
}

