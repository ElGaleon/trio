import 'dart:math' as math;

import 'package:flutter/material.dart';

class InfiniteScrollList<T> extends StatefulWidget {
  const InfiniteScrollList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.separatorBuilder,
    this.batchSize = 20,
    this.preloadExtent = 360,
    this.padding = EdgeInsets.zero,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final WidgetBuilder? separatorBuilder;
  final int batchSize;
  final double preloadExtent;
  final EdgeInsetsGeometry padding;

  @override
  State<InfiniteScrollList<T>> createState() => _InfiniteScrollListState<T>();
}

class _InfiniteScrollListState<T> extends State<InfiniteScrollList<T>> {
  late final ScrollController _controller;
  late int _visibleCount;

  @override
  void initState() {
    super.initState();
    _visibleCount = _nextVisibleCount(0);
    _controller = ScrollController()..addListener(_loadMoreNearEnd);
  }

  @override
  void didUpdateWidget(covariant InfiniteScrollList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items ||
        oldWidget.batchSize != widget.batchSize) {
      _visibleCount = _nextVisibleCount(0);
    } else if (_visibleCount > widget.items.length) {
      _visibleCount = widget.items.length;
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_loadMoreNearEnd)
      ..dispose();
    super.dispose();
  }

  int _nextVisibleCount(int current) {
    return math.min(widget.items.length, current + widget.batchSize);
  }

  void _loadMoreNearEnd() {
    if (!_controller.hasClients ||
        _controller.position.extentAfter > widget.preloadExtent ||
        _visibleCount >= widget.items.length) {
      return;
    }

    setState(() => _visibleCount = _nextVisibleCount(_visibleCount));
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: _controller,
      primary: false,
      padding: widget.padding,
      itemCount: _visibleCount,
      itemBuilder: (context, index) {
        return widget.itemBuilder(context, widget.items[index], index);
      },
      separatorBuilder: (context, index) {
        return widget.separatorBuilder?.call(context) ??
            const SizedBox(height: 10);
      },
    );
  }
}
