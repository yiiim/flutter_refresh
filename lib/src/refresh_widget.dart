import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:refresh_widget/src/status.dart';
import 'package:refresh_widget/src/indicator_container.dart';

import 'configuration.dart';
import 'status.dart';
import 'indicator.dart';

class RefreshWidget extends StatefulWidget {
  RefreshWidget({
    this.child,
    this.headerExpand,
    this.footerExpand,
    this.initialStartHeaderRefresh = false,
    this.scrollController,
    this.configuration,
    this.onHeaderRefresh,
    this.onFooterRefresh,
    this.footerNoMoreData = false,
    this.headerIndicatorBuilder,
    this.footerIndicatorBuilder,
    this.headerOnTap,
    this.footerOnTap,
  });

  /// header距离顶部距离
  final double headerExpand;

  /// footer距离顶部距离
  final double footerExpand;

  /// 是否开启启动刷新
  final bool initialStartHeaderRefresh;

  /// 刷新控制器，必须将这个属性赋值给scrollView的controller
  final RefreshScrollController scrollController;

  /// 配置
  final RefreshConfiguration configuration;

  /// 下拉刷新事件，返回false表示失败，ture表示成功
  final Future<bool> Function() onHeaderRefresh;

  /// 上拉刷新事件，返回false表示失败，true表示成功
  final Future<bool> Function() onFooterRefresh;

  /// 下拉刷新指示器builder方法，如果不设置将采用configuration的builder
  final Widget Function(RefreshStatus status, RefreshConfiguration configuration, double offset) headerIndicatorBuilder;

  /// 上拉加载指示器builder方法，如果不设置将采用configuration的builder
  final Widget Function(RefreshStatus status, RefreshConfiguration configuration, double offset) footerIndicatorBuilder;

  /// 是否无数据
  final bool footerNoMoreData;

  ///header点击事件
  final void Function(RefreshStatus) headerOnTap;

  ///footer点击事件
  final void Function(RefreshStatus) footerOnTap;

  final Widget child;
  @override
  State<StatefulWidget> createState() => RefreshWidgetState();
}

class RefreshWidgetState extends State<RefreshWidget> {
  ValueNotifier<RefreshStatus> _headerStatusValueNotifier = ValueNotifier<RefreshStatus>(RefreshStatus.none);
  ValueNotifier<RefreshStatus> _footerStatusValueNotifier = ValueNotifier<RefreshStatus>(RefreshStatus.none);
  RefreshScrollController _refreshScrollController;
  PixelsChangeNotifierModel _pixelsChangeNotifierModel = PixelsChangeNotifierModel(0);
  PixelsChangeNotifierModel _headerPixelsChangeNotifierModel = PixelsChangeNotifierModel(0);
  PixelsChangeNotifierModel _footerPixelsChangeNotifierModel = PixelsChangeNotifierModel(0);
  Future _footerNoMoreDataWait;
  void _updateRefreshController() {
    assert(widget.scrollController != null);
    _refreshScrollController = widget.scrollController;
    if (widget.onHeaderRefresh != null) _refreshScrollController.headerStatusValueNotifier = _headerStatusValueNotifier;
    if (widget.onFooterRefresh != null) _refreshScrollController.footerStatusValueNotifier = _footerStatusValueNotifier;
    _refreshScrollController.pixelsChangeNotifierModel = _pixelsChangeNotifierModel;
    _refreshScrollController.configuration = widget.configuration ?? (context.dependOnInheritedWidgetOfExactType<RefreshConfiguration>() ?? RefreshConfiguration.defualt());
  }

  void _footerStatusListener() {
    if (widget.onFooterRefresh == null) return;
    if (_footerStatusValueNotifier.value == RefreshStatus.refresh) {
      Future.delayed(Duration.zero, () async {
        if (await widget.onFooterRefresh()) {
          _footerStatusValueNotifier.value = RefreshStatus.success;
          if (_refreshScrollController.configuration.headerSuccessDuration != Duration.zero) {
            _footerNoMoreDataWait = Future.delayed(_refreshScrollController.configuration.headerSuccessDuration);
            await _footerNoMoreDataWait;
            Future.delayed(Duration.zero, () => _footerNoMoreDataWait = null);
          }
          _footerStatusValueNotifier.value = widget.footerNoMoreData ? RefreshStatus.nomoredata : RefreshStatus.done;
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            if (_refreshScrollController.hasClients) _refreshScrollController.position.goIdle();
          });
        } else {
          _footerStatusValueNotifier.value = RefreshStatus.faildone;
        }
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          _noScrollPixelsChange();
        });
      });
    }
  }

  void _headerStatusListener() {
    if (widget.onHeaderRefresh == null) return;
    if (_headerStatusValueNotifier.value == RefreshStatus.refresh) {
      Future.delayed(Duration.zero, () async {
        if (await widget.onHeaderRefresh()) {
          _headerStatusValueNotifier.value = RefreshStatus.success;
          if (_refreshScrollController.configuration.headerSuccessDuration != Duration.zero) await Future.delayed(_refreshScrollController.configuration.headerSuccessDuration);
          _headerStatusValueNotifier.value = RefreshStatus.done;
        } else {
          _headerStatusValueNotifier.value = RefreshStatus.faildone;
        }
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          _noScrollPixelsChange();
        });
      });
    }
  }

  void _noScrollPixelsChange() {
    _headerPixelsChangeNotifierModel.value = null;
    _footerPixelsChangeNotifierModel.value = null;
  }

  void _pixelsChangeNotifierModelListener() {
    _headerPixelsChangeNotifierModel.value = _pixelsChangeNotifierModel.value < 0 ? -_pixelsChangeNotifierModel.value : 0;
    _footerPixelsChangeNotifierModel.value = _refreshScrollController.hasClients && _pixelsChangeNotifierModel.value > _refreshScrollController.position.originalMaxScrollExtent ? _pixelsChangeNotifierModel.value - _refreshScrollController.position.originalMaxScrollExtent : 0;
  }

  @override
  void didUpdateWidget(covariant RefreshWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onFooterRefresh != null) {
      if (_footerStatusValueNotifier.value == RefreshStatus.nomoredata && !widget.footerNoMoreData) {
        _footerStatusValueNotifier.value = RefreshStatus.none;
      }
      if (_footerStatusValueNotifier.value != RefreshStatus.nomoredata && widget.footerNoMoreData) {
        if (_footerNoMoreDataWait != null) {
          _footerNoMoreDataWait.then((value) => _footerStatusValueNotifier.value = RefreshStatus.nomoredata);
        } else {
          _footerStatusValueNotifier.value = RefreshStatus.nomoredata;
        }
      }
    }
    if (oldWidget.scrollController != widget.scrollController) _updateRefreshController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateRefreshController();
  }

  @override
  void initState() {
    super.initState();
    _headerStatusValueNotifier.addListener(_headerStatusListener);
    _footerStatusValueNotifier.addListener(_footerStatusListener);
    _pixelsChangeNotifierModel.addListener(_pixelsChangeNotifierModelListener);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.initialStartHeaderRefresh && _refreshScrollController.hasClients) _refreshScrollController.position.startHeaderRefresh();
      if (widget.footerNoMoreData) _footerStatusValueNotifier.value = RefreshStatus.nomoredata;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        widget.onHeaderRefresh != null
            ? RefreshIndicatorContainer(
                onTap: () {
                  if (widget.headerOnTap != null) widget.headerOnTap(_headerStatusValueNotifier.value);
                },
                sizeNotifier: _headerPixelsChangeNotifierModel,
                statusNotifier: _headerStatusValueNotifier,
                configuration: _refreshScrollController?.configuration,
                mode: RefreshIndicatorContainerMode.header,
                expand: widget.headerExpand ?? (_refreshScrollController.configuration.headerExpand ?? 0),
                indicatorBuilder: (status, configuration, offset) {
                  if (widget.headerIndicatorBuilder != null) return widget.headerIndicatorBuilder(status, configuration, offset);
                  if (_refreshScrollController.configuration.headerIndicatorBuilder != null) return _refreshScrollController.configuration.headerIndicatorBuilder(status, configuration, offset);
                  return BasisHeaderRefreshIndicator(status: status, configuration: configuration, offest: offset);
                },
              )
            : Container(),
        widget.onFooterRefresh != null
            ? RefreshIndicatorContainer(
                onTap: () {
                  if (widget.footerOnTap != null) widget.footerOnTap(_footerStatusValueNotifier.value);
                },
                sizeNotifier: _footerPixelsChangeNotifierModel,
                statusNotifier: _footerStatusValueNotifier,
                configuration: _refreshScrollController?.configuration,
                mode: RefreshIndicatorContainerMode.footer,
                expand: widget.footerExpand ?? (_refreshScrollController.configuration.footerExpand ?? 0),
                indicatorBuilder: (status, configuration, offset) {
                  if (widget.footerIndicatorBuilder != null) return widget.footerIndicatorBuilder(status, configuration, offset);
                  if (_refreshScrollController.configuration.footerIndicatorBuilder != null) return _refreshScrollController.configuration.footerIndicatorBuilder(status, configuration, offset);
                  return BasisFooterRefreshIndicator(status: status, configuration: configuration, offest: offset);
                },
              )
            : Container(),
      ],
    );
  }
}

class RefreshScrollController extends ScrollController {
  RefreshScrollController({
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    String debugLabel,
  }) : super(initialScrollOffset: initialScrollOffset, keepScrollOffset: keepScrollOffset, debugLabel: debugLabel);
  ValueNotifier<RefreshStatus> _headerStatusValueNotifier;
  ValueNotifier<RefreshStatus> _footerStatusValueNotifier;
  PixelsChangeNotifierModel _pixelsChangeNotifierModel;
  RefreshConfiguration _configuration;
  ValueNotifier<RefreshStatus> get headerStatusValueNotifier => _headerStatusValueNotifier;
  ValueNotifier<RefreshStatus> get footerStatusValueNotifier => _footerStatusValueNotifier;
  PixelsChangeNotifierModel get pixelsChangeNotifierModel => _pixelsChangeNotifierModel;
  RefreshConfiguration get configuration => _configuration;
  set headerStatusValueNotifier(ValueNotifier<RefreshStatus> value) {
    _headerStatusValueNotifier = value;
    if (this.hasClients) this.position.headerStatusValueNotifier = value;
  }

  set footerStatusValueNotifier(ValueNotifier<RefreshStatus> value) {
    _footerStatusValueNotifier = value;
    if (this.hasClients) this.position.footerStatusValueNotifier = value;
  }

  set pixelsChangeNotifierModel(PixelsChangeNotifierModel value) {
    _pixelsChangeNotifierModel = value;
    if (this.hasClients) this.position.pixelsChangeNotifierModel = value;
  }

  set configuration(RefreshConfiguration value) {
    _configuration = value;
    if (this.hasClients) this.position.configuration = value;
  }

  bool get headerRefreshing => headerStatusValueNotifier?.value == RefreshStatus.refresh;
  bool get headerIsIdleing => headerStatusValueNotifier?.value == RefreshStatus.none || headerStatusValueNotifier?.value == RefreshStatus.done;
  bool get footerRefreshing => footerStatusValueNotifier?.value == RefreshStatus.refresh;
  bool get footerIsIdleing => footerStatusValueNotifier?.value == RefreshStatus.none || footerStatusValueNotifier?.value == RefreshStatus.done;

  void startHeaderRefresh() async {
    if (this.hasClients) await this.animateTo(-this.configuration.headerRuningHeight, duration: Duration(milliseconds: 222), curve: Curves.easeIn);
    headerStatusValueNotifier.value = RefreshStatus.refresh;
  }

  void startFooterRefresh() async {
    if (this.hasClients) await this.animateTo(this.position.originalMaxScrollExtent + this.configuration.footerRuningHeight, duration: Duration(milliseconds: 222), curve: Curves.easeIn);
    footerStatusValueNotifier.value = RefreshStatus.refresh;
  }

  @override
  RefreshScrollPositionWithSingleContext get position => super.position;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition oldPosition,
  ) {
    return RefreshScrollPositionWithSingleContext(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
      configuration: configuration,
      pixelsChangeNotifierModel: pixelsChangeNotifierModel,
      headerStatusValueNotifier: headerStatusValueNotifier,
      footerStatusValueNotifier: footerStatusValueNotifier,
    );
  }
}

class RefreshScrollPositionWithSingleContext extends ScrollPositionWithSingleContext {
  RefreshConfiguration configuration;
  PixelsChangeNotifierModel pixelsChangeNotifierModel;
  ValueNotifier<RefreshStatus> _headerStatusValueNotifier;
  ValueNotifier<RefreshStatus> _footerStatusValueNotifier;
  ValueNotifier<RefreshStatus> get headerStatusValueNotifier => _headerStatusValueNotifier;
  ValueNotifier<RefreshStatus> get footerStatusValueNotifier => _footerStatusValueNotifier;

  void publichForcePixels(double value) => this.forcePixels(value);

  void startHeaderRefresh() async {
    await this.animateTo(-this.configuration.headerRuningHeight, duration: Duration(milliseconds: 222), curve: Curves.easeIn);
    headerStatusValueNotifier.value = RefreshStatus.refresh;
    this.goBallistic(0);
  }

  void startFooterRefresh() async {
    await this.animateTo(this.originalMaxScrollExtent + this.configuration.footerRuningHeight, duration: Duration(milliseconds: 222), curve: Curves.easeIn);
    _footerStatusValueNotifier.value = RefreshStatus.refresh;
    this.goBallistic(0);
  }

  set headerStatusValueNotifier(ValueNotifier<RefreshStatus> value) {
    if (_headerStatusValueNotifier != value) {
      _headerStatusValueNotifier?.removeListener(_headerStatusListener);
      _headerStatusValueNotifier = value;
      _headerStatusValueNotifier?.addListener(_headerStatusListener);
    }
  }

  set footerStatusValueNotifier(ValueNotifier<RefreshStatus> value) {
    if (_footerStatusValueNotifier != value) {
      _footerStatusValueNotifier?.removeListener(_footerStatusListener);
      _footerStatusValueNotifier = value;
      _footerStatusValueNotifier?.addListener(_footerStatusListener);
    }
  }

  void _footerStatusListener() {
    if (footerStatusValueNotifier.value == RefreshStatus.faildone || footerStatusValueNotifier.value == RefreshStatus.nomoredata) {
      this.goBallistic(0);
    }
  }

  void _headerStatusListener() {
    if (headerStatusValueNotifier.value == RefreshStatus.success || headerStatusValueNotifier.value == RefreshStatus.done || headerStatusValueNotifier.value == RefreshStatus.faildone) {
      this.goBallistic(0);
    }
  }

  double get _headerExpansionValue {
    if (headerStatusValueNotifier?.value == RefreshStatus.refresh) return configuration?.headerRuningHeight;
    if (headerStatusValueNotifier?.value == RefreshStatus.success) return configuration?.headerSuccessHeight;
    if (headerStatusValueNotifier?.value == RefreshStatus.faildone) return configuration?.headerFailHeight;
    return 0;
  }

  double get _footerExpansionValue {
    if (footerStatusValueNotifier?.value == RefreshStatus.refresh) return configuration?.footerRuningHeight;
    if (footerStatusValueNotifier?.value == RefreshStatus.faildone) return configuration?.footerFailHeight;
    if (footerStatusValueNotifier?.value == RefreshStatus.nomoredata) return configuration?.noMoreDataHeight;
    if (footerStatusValueNotifier?.value == RefreshStatus.success) return configuration?.footerSuccessHeight;
    return 0;
  }

  RefreshScrollPositionWithSingleContext({
    @required ScrollPhysics physics,
    @required ScrollContext context,
    double initialPixels = 0.0,
    bool keepScrollOffset = true,
    ScrollPosition oldPosition,
    String debugLabel,
    this.configuration,
    this.pixelsChangeNotifierModel,
    ValueNotifier<RefreshStatus> headerStatusValueNotifier,
    ValueNotifier<RefreshStatus> footerStatusValueNotifier,
  }) : super(
          physics: physics,
          context: context,
          keepScrollOffset: keepScrollOffset,
          initialPixels: initialPixels,
          oldPosition: oldPosition,
          debugLabel: debugLabel,
        ) {
    this.headerStatusValueNotifier = headerStatusValueNotifier;
    this.footerStatusValueNotifier = footerStatusValueNotifier;
  }
  @override
  double get minScrollExtent => (super.minScrollExtent ?? 0) - _headerExpansionValue;
  double get originalMinScrollExtent => super.minScrollExtent;
  @override
  double get maxScrollExtent => (super.maxScrollExtent ?? 0) + _footerExpansionValue;
  double get originalMaxScrollExtent => super.maxScrollExtent;

  @override
  double setPixels(double newPixels) {
    var result = super.setPixels(newPixels);
    this.pixelsChangeNotifierModel?.value = this.pixels;
    return result;
  }

  @override
  void applyUserOffset(double delta) {
    if (configuration == null) return;
    if (this.pixels <= -configuration.headerRuningHeight && (headerStatusValueNotifier?.value == RefreshStatus.drag || headerStatusValueNotifier?.value == RefreshStatus.faildone)) headerStatusValueNotifier.value = RefreshStatus.armed;
    if (this.pixels > -configuration.headerRuningHeight && (headerStatusValueNotifier?.value == RefreshStatus.armed || headerStatusValueNotifier?.value == RefreshStatus.faildone)) headerStatusValueNotifier.value = RefreshStatus.drag;
    if (this.pixels >= this.originalMaxScrollExtent + configuration.footerRuningHeight && (footerStatusValueNotifier?.value == RefreshStatus.drag || footerStatusValueNotifier?.value == RefreshStatus.faildone)) footerStatusValueNotifier.value = RefreshStatus.armed;
    if (this.pixels < this.originalMaxScrollExtent + configuration.footerRuningHeight && (footerStatusValueNotifier?.value == RefreshStatus.armed || footerStatusValueNotifier?.value == RefreshStatus.faildone)) footerStatusValueNotifier.value = RefreshStatus.drag;
    if (headerStatusValueNotifier?.value == RefreshStatus.none || headerStatusValueNotifier?.value == RefreshStatus.done) headerStatusValueNotifier.value = RefreshStatus.drag;
    if (footerStatusValueNotifier?.value == RefreshStatus.none || footerStatusValueNotifier?.value == RefreshStatus.done) footerStatusValueNotifier.value = RefreshStatus.drag;
    super.applyUserOffset(delta);
  }

  @override
  void dispose() {
    _footerStatusValueNotifier?.removeListener(_footerStatusListener);
    _headerStatusValueNotifier?.removeListener(_headerStatusListener);
    super.dispose();
  }

  @override
  void goBallistic(double velocity) {
    if (headerStatusValueNotifier?.value == RefreshStatus.armed) headerStatusValueNotifier.value = RefreshStatus.refresh;
    if (footerStatusValueNotifier?.value == RefreshStatus.armed) footerStatusValueNotifier.value = RefreshStatus.refresh;
    super.goBallistic(velocity);
  }

  @override
  void goIdle() {
    if (headerStatusValueNotifier?.value == RefreshStatus.done || headerStatusValueNotifier?.value == RefreshStatus.drag) headerStatusValueNotifier?.value = RefreshStatus.none;
    if (footerStatusValueNotifier?.value == RefreshStatus.done || footerStatusValueNotifier?.value == RefreshStatus.drag) footerStatusValueNotifier?.value = RefreshStatus.none;
    super.goIdle();
  }
}
