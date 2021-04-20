import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:refresh_widget/refresh_widget.dart';
import 'package:refresh_widget/src/status.dart';
import 'package:refresh_widget/src/configuration.dart';

enum RefreshIndicatorContainerMode { header, footer }

class PixelsChangeNotifierModel extends ValueNotifier<double> {
  PixelsChangeNotifierModel(double value) : super(value);
}

class RefreshIndicatorContainer extends StatefulWidget {
  RefreshIndicatorContainer({this.indicatorBuilder, this.sizeNotifier, this.statusNotifier, this.configuration, this.expand = 0, this.mode, this.onTap});
  final ValueNotifier<double> sizeNotifier;
  final ValueNotifier<RefreshStatus> statusNotifier;
  final RefreshIndicatorContainerMode mode;
  final RefreshConfiguration configuration;
  final Function onTap;
  final double expand;
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
        expand: widget.expand,
        onTap: widget.onTap,
      );
    if (widget.mode == RefreshIndicatorContainerMode.footer)
      return _RefreshFooterIndicatorContent(
        configuration: widget.configuration,
        sizeNotifier: widget.sizeNotifier,
        statusNotifier: widget.statusNotifier,
        indicatorBuilder: widget.indicatorBuilder,
        expand: widget.expand,
        onTap: widget.onTap,
      );
    return Container();
  }
}

class _RefreshHeaderIndicatorContent extends StatelessWidget {
  _RefreshHeaderIndicatorContent({this.configuration, this.sizeNotifier, this.statusNotifier, this.expand, this.indicatorBuilder, this.onTap});
  final RefreshConfiguration configuration;
  final ValueNotifier<double> sizeNotifier;
  final ValueNotifier<RefreshStatus> statusNotifier;
  final double expand;
  final Function onTap;
  final Widget Function(RefreshStatus status, RefreshConfiguration configuration, double offset) indicatorBuilder;
  @override
  Widget build(BuildContext context) {
    var height = 0.0;
    var offset = 0.0;
    if (sizeNotifier?.value != null) {
      height = max(this.sizeNotifier?.value ?? 0, this.configuration?.headerMinHeight ?? 0);
      offset = (this.sizeNotifier?.value ?? 0) - height;
    } else {
      switch (statusNotifier.value) {
        case RefreshStatus.refresh:
        case RefreshStatus.success:
          height = this.configuration.headerRuningHeight;
          break;
        case RefreshStatus.faildone:
          height = this.configuration.headerFailHeight;
          break;
        default:
      }
    }
    return Positioned(
      top: expand,
      left: 0,
      right: 0,
      child: ClipRect(
        child: Transform.translate(
          offset: Offset(0, offset),
          child: SizedBox(
            height: height,
            child: GestureDetector(
              onTap: onTap,
              child: indicatorBuilder(statusNotifier.value, configuration, sizeNotifier.value),
            ),
          ),
        ),
      ),
    );
  }
}

class _RefreshFooterIndicatorContent extends StatelessWidget {
  _RefreshFooterIndicatorContent({this.configuration, this.sizeNotifier, this.statusNotifier, this.expand, this.indicatorBuilder, this.onTap});
  final RefreshConfiguration configuration;
  final ValueNotifier<double> sizeNotifier;
  final ValueNotifier<RefreshStatus> statusNotifier;
  final double expand;
  final Function onTap;
  final Widget Function(RefreshStatus status, RefreshConfiguration configuration, double offset) indicatorBuilder;
  @override
  Widget build(BuildContext context) {
    var height = 0.0;
    var offset = 0.0;
    if (sizeNotifier?.value != null) {
      height = max(this.sizeNotifier.value ?? 0, this.configuration?.footerMinHeight ?? 0);
      offset = height - (this.sizeNotifier?.value ?? 0);
    } else {
      switch (statusNotifier.value) {
        case RefreshStatus.refresh:
        case RefreshStatus.success:
          height = this.configuration?.footerRuningHeight ?? 0;
          break;
        case RefreshStatus.faildone:
          height = this.configuration?.footerFailHeight ?? 0;
          break;
        case RefreshStatus.nomoredata:
          height = this.configuration?.noMoreDataHeight ?? 0;
          break;
        default:
      }
    }
    return Positioned(
      bottom: expand,
      left: 0,
      right: 0,
      child: ClipRect(
        child: Transform.translate(
          offset: Offset(0, offset),
          child: SizedBox(
            height: height,
            child: GestureDetector(
              onTap: onTap,
              child: indicatorBuilder(statusNotifier.value, configuration, sizeNotifier.value),
            ),
          ),
        ),
      ),
    );
  }
}
