import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:refresh_widget/src/configuration.dart';
import 'package:refresh_widget/src/status.dart';

enum RefreshIndicatorContainerMode { header, footer }

class PixelsChangeNotifierModel extends ValueNotifier<double> {
  PixelsChangeNotifierModel(double value) : super(value);
}

class RefreshIndicatorContainer extends StatefulWidget {
  RefreshIndicatorContainer({this.indicatorBuilder, this.sizeNotifier, this.statusNotifier, this.configuration, this.mode});
  final ValueNotifier<double> sizeNotifier;
  final ValueNotifier<RefreshStatus> statusNotifier;
  final RefreshIndicatorContainerMode mode;
  final RefreshConfiguration configuration;
  final Widget Function(RefreshStatus status, RefreshConfiguration configuration, double offset) indicatorBuilder;
  @override
  State<StatefulWidget> createState() => RefreshIndicatorContainerState();
}

class RefreshIndicatorContainerState extends State<RefreshIndicatorContainer> {
  void _notifierListener() {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      this.setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant RefreshIndicatorContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sizeNotifier != widget.sizeNotifier) {
      oldWidget.sizeNotifier?.removeListener(_notifierListener);
      widget.sizeNotifier?.addListener(_notifierListener);
    }
    if (oldWidget.statusNotifier != widget.statusNotifier) {
      oldWidget.statusNotifier?.removeListener(_notifierListener);
      widget.statusNotifier?.addListener(_notifierListener);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.sizeNotifier?.addListener(_notifierListener);
    widget.statusNotifier?.addListener(_notifierListener);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == RefreshIndicatorContainerMode.header)
      return _RefreshHeaderIndicatorContent(
        configuration: widget.configuration,
        sizeNotifier: widget.sizeNotifier,
        statusNotifier: widget.statusNotifier,
        indicatorBuilder: widget.indicatorBuilder,
      );
    if (widget.mode == RefreshIndicatorContainerMode.footer)
      return _RefreshFooterIndicatorContent(
        configuration: widget.configuration,
        sizeNotifier: widget.sizeNotifier,
        statusNotifier: widget.statusNotifier,
        indicatorBuilder: widget.indicatorBuilder,
      );
    return Container();
  }
}

class _RefreshHeaderIndicatorContent extends StatelessWidget {
  _RefreshHeaderIndicatorContent({this.configuration, this.sizeNotifier, this.statusNotifier, this.indicatorBuilder});
  final RefreshConfiguration configuration;
  final ValueNotifier<double> sizeNotifier;
  final ValueNotifier<RefreshStatus> statusNotifier;
  final Widget Function(RefreshStatus status, RefreshConfiguration configuration, double offset) indicatorBuilder;
  @override
  Widget build(BuildContext context) {
    var height = max(this.sizeNotifier?.value ?? 0, this.configuration?.headerMinHeight ?? 0);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: Transform.translate(
          offset: Offset(0, (this.sizeNotifier?.value ?? 0) - height),
          child: SizedBox(
            height: height,
            child: indicatorBuilder(statusNotifier.value, configuration, sizeNotifier.value),
          ),
        ),
      ),
    );
  }
}

class _RefreshFooterIndicatorContent extends StatelessWidget {
  _RefreshFooterIndicatorContent({this.configuration, this.sizeNotifier, this.statusNotifier, this.indicatorBuilder});
  final RefreshConfiguration configuration;
  final ValueNotifier<double> sizeNotifier;
  final ValueNotifier<RefreshStatus> statusNotifier;
  final Widget Function(RefreshStatus status, RefreshConfiguration configuration, double offset) indicatorBuilder;
  @override
  Widget build(BuildContext context) {
    var height = max(this.sizeNotifier?.value ?? 0, this.configuration?.footerMinHeight ?? 0);
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: Transform.translate(
          offset: Offset(0, height - (this.sizeNotifier?.value ?? 0)),
          child: SizedBox(
            height: height,
            child: indicatorBuilder(statusNotifier.value, configuration, sizeNotifier.value),
          ),
        ),
      ),
    );
  }
}
