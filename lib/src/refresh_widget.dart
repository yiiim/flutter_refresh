import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:refresh_widget/src/indicator_container.dart';

import 'configuration.dart';
import 'status.dart';
import 'indicator.dart';

class RefreshWidget extends StatefulWidget {
  RefreshWidget({this.child, this.initialStartHeaderRefresh = false, this.scrollController, this.configuration, this.onHeaderRefresh, this.onFooterRefresh, this.footerNoMoreData, this.headerIndicatorBuilder, this.footerIndicatorBuilder});

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
    if (_refreshScrollController != widget.scrollController) {
      _refreshScrollController = widget.scrollController;
      if (widget.onHeaderRefresh != null) {
        _refreshScrollController.headerStatusValueNotifier = _headerStatusValueNotifier;
        if (_refreshScrollController.hasClients) _refreshScrollController.position.headerStatusValueNotifier = _headerStatusValueNotifier;
      }
      if (widget.onFooterRefresh != null) {
        _refreshScrollController.footerStatusValueNotifier = _footerStatusValueNotifier;
        if (_refreshScrollController.hasClients) _refreshScrollController.position.footerStatusValueNotifier = _footerStatusValueNotifier;
      }
      _refreshScrollController.pixelsChangeNotifierModel = _pixelsChangeNotifierModel;
      if (_refreshScrollController.hasClients) _refreshScrollController.position.pixelsChangeNotifierModel = _pixelsChangeNotifierModel;
    }
    _refreshScrollController.configuration = widget.configuration ?? (context.dependOnInheritedWidgetOfExactType<RefreshConfiguration>() ?? RefreshConfiguration.defualt());
    if (_refreshScrollController.hasClients) _refreshScrollController.position.configuration = _refreshScrollController.configuration;
  }

  void _footerStatusListener() {
    if (widget.onFooterRefresh == null) return;
    if (_footerStatusValueNotifier.value == RefreshStatus.refresh) {
      Future.delayed(Duration.zero, () async {
        if (await widget.onFooterRefresh()) {
          _footerStatusValueNotifier.value = RefreshStatus.success;
          _footerNoMoreDataWait = Future.delayed(_refreshScrollController.configuration.headerSuccessDuration);
          await _footerNoMoreDataWait;
          _footerStatusValueNotifier.value = widget.footerNoMoreData ? RefreshStatus.nomoredata : RefreshStatus.done;
          Future.delayed(Duration.zero, () => _footerNoMoreDataWait = null);
        } else {
          _footerStatusValueNotifier.value = RefreshStatus.faildone;
        }
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          _pixelsChangeNotifierModelListener();
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
          await Future.delayed(_refreshScrollController.configuration.headerSuccessDuration);
          _headerStatusValueNotifier.value = RefreshStatus.done;
        } else {
          _headerStatusValueNotifier.value = RefreshStatus.faildone;
        }
      });
    }
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _pixelsChangeNotifierModelListener();
    });
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
    if (widget.initialStartHeaderRefresh)
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (_refreshScrollController.hasClients) _refreshScrollController.position.startHeaderRefresh();
      });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        widget.onHeaderRefresh != null
            ? RefreshIndicatorContainer(
                sizeNotifier: _headerPixelsChangeNotifierModel,
                statusNotifier: _headerStatusValueNotifier,
                configuration: _refreshScrollController?.configuration,
                mode: RefreshIndicatorContainerMode.header,
                indicatorBuilder: (status, configuration, offset) {
                  if (widget.headerIndicatorBuilder != null) return widget.headerIndicatorBuilder(status, configuration, offset);
                  if (_refreshScrollController.configuration.headerIndicatorBuilder != null) return _refreshScrollController.configuration.headerIndicatorBuilder(status, configuration, offset);
                  return BasisHeaderRefreshIndicator(status: status, configuration: configuration, offest: offset);
                },
              )
            : Container(),
        widget.onFooterRefresh != null
            ? RefreshIndicatorContainer(
                sizeNotifier: _footerPixelsChangeNotifierModel,
                statusNotifier: _footerStatusValueNotifier,
                configuration: _refreshScrollController?.configuration,
                mode: RefreshIndicatorContainerMode.footer,
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
  RefreshScrollController({double initialScrollOffset = 0.0}) : super(initialScrollOffset: initialScrollOffset);
  ValueNotifier<RefreshStatus> headerStatusValueNotifier;
  ValueNotifier<RefreshStatus> footerStatusValueNotifier;
  PixelsChangeNotifierModel pixelsChangeNotifierModel;
  RefreshConfiguration configuration;

  void startHeaderRefresh() async {
    await this.animateTo(-this.configuration.headerRuningHeight, duration: Duration(milliseconds: 333), curve: Curves.easeIn);
    headerStatusValueNotifier.value = RefreshStatus.refresh;
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
    if (footerStatusValueNotifier.value == RefreshStatus.success || footerStatusValueNotifier.value == RefreshStatus.faildone || footerStatusValueNotifier.value == RefreshStatus.nomoredata) {
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
    if (this.pixels <= -configuration.headerRuningHeight && headerStatusValueNotifier?.value == RefreshStatus.drag) headerStatusValueNotifier.value = RefreshStatus.armed;
    if (this.pixels > -configuration.headerRuningHeight && headerStatusValueNotifier?.value == RefreshStatus.armed) headerStatusValueNotifier.value = RefreshStatus.drag;
    if (this.pixels >= this.originalMaxScrollExtent + configuration.footerRuningHeight && footerStatusValueNotifier?.value == RefreshStatus.drag) footerStatusValueNotifier.value = RefreshStatus.armed;
    if (this.pixels < this.originalMaxScrollExtent + configuration.footerRuningHeight && footerStatusValueNotifier?.value == RefreshStatus.armed) footerStatusValueNotifier.value = RefreshStatus.drag;
    if (headerStatusValueNotifier?.value == RefreshStatus.none || headerStatusValueNotifier?.value == RefreshStatus.done) headerStatusValueNotifier.value = RefreshStatus.drag;
    if (footerStatusValueNotifier?.value == RefreshStatus.none || footerStatusValueNotifier?.value == RefreshStatus.done) footerStatusValueNotifier.value = RefreshStatus.drag;
    super.applyUserOffset(delta);
  }

  @override
  void goBallistic(double velocity) {
    if (headerStatusValueNotifier?.value == RefreshStatus.armed) headerStatusValueNotifier.value = RefreshStatus.refresh;
    if (footerStatusValueNotifier?.value == RefreshStatus.armed) footerStatusValueNotifier.value = RefreshStatus.refresh;
    super.goBallistic(velocity);
  }

  @override
  void goIdle() {
    if (headerStatusValueNotifier?.value == RefreshStatus.done) headerStatusValueNotifier?.value = RefreshStatus.none;
    if (footerStatusValueNotifier?.value == RefreshStatus.done) footerStatusValueNotifier?.value = RefreshStatus.none;
    super.goIdle();
  }
}
