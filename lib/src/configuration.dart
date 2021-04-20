import 'package:flutter/material.dart';

import 'status.dart';

class RefreshConfiguration extends InheritedWidget {
  RefreshConfiguration({
    this.headerIndicatorBuilder,
    this.headerExpand = 0,
    this.headerMinHeight = 44,
    this.headerRuningHeight = 88,
    this.noMoreDataHeight = 88,
    this.headerFailHeight = 0,
    this.headerSuccessHeight = 0,
    this.headerSuccessDuration = Duration.zero,
    this.footerIndicatorBuilder,
    this.footerExpand = 0,
    this.footerMinHeight = 44,
    this.footerRuningHeight = 88,
    this.footerFailHeight = 0,
    this.footerSuccessHeight = 0,
    this.footerSuccessDuration = Duration.zero,
    Widget child,
  }) : super(child: child);

  /// 下拉刷新控件默认的builder
  final Widget Function(RefreshStatus status, RefreshConfiguration configuration, double offset) headerIndicatorBuilder;

  /// header容器的最小高度，最小高度是为了下拉的时候，能够看得出来控件是从上面拉下来的，而不是从小变大，如果要从小变大的效果可以将此高度设置为0
  final double headerMinHeight;

  /// header距离顶部距离
  final double headerExpand;

  /// 下拉运行的高度，当拉到这个高度时松开即可刷新
  final double headerRuningHeight;

  /// 下拉失败的高度，如果需要失败后仍然保持一个下拉距离可以设置
  final double headerFailHeight;

  ///下拉成功停留高度，如果需要上拉成功之后浏览一段时间，这个是停留那一段时间的高度
  final double headerSuccessHeight;

  /// 下拉成功之后停留时长，如果需要下拉之后展示一个成功的动画可以设置
  final Duration headerSuccessDuration;

  /// 下拉加载默认的builder
  final Widget Function(RefreshStatus status, RefreshConfiguration configuration, double offset) footerIndicatorBuilder;

  /// footer距离顶部距离
  final double footerExpand;

  /// 上拉最小高度
  final double footerMinHeight;

  /// 上拉运行高度
  final double footerRuningHeight;

  /// 上拉失败高度
  final double footerFailHeight;

  /// 无数据高度
  final double noMoreDataHeight;

  /// 上拉成功之后停留高度
  final double footerSuccessHeight;

  /// 下拉成功停留时长
  final Duration footerSuccessDuration;

  factory RefreshConfiguration.defualt() {
    return RefreshConfiguration(
      headerFailHeight: 0,
      headerMinHeight: 44,
      headerRuningHeight: 88,
      headerSuccessHeight: 88,
      headerSuccessDuration: Duration(seconds: 1),
      footerFailHeight: 0,
      footerRuningHeight: 88,
      footerMinHeight: 44,
      noMoreDataHeight: 88,
      headerExpand: 0,
      footerSuccessHeight: 88,
      footerExpand: 0,
      footerSuccessDuration: Duration(seconds: 1),
    );
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    if (oldWidget is RefreshConfiguration) {
      return oldWidget.headerIndicatorBuilder != this.headerIndicatorBuilder || oldWidget.footerIndicatorBuilder != this.footerIndicatorBuilder || oldWidget.headerFailHeight != this.headerFailHeight || oldWidget.headerMinHeight != this.headerMinHeight || oldWidget.headerRuningHeight != this.headerRuningHeight || oldWidget.headerSuccessHeight != this.headerSuccessHeight || oldWidget.headerSuccessHeight != this.headerSuccessHeight || oldWidget.headerSuccessDuration != this.headerSuccessDuration || oldWidget.footerFailHeight != this.footerFailHeight || oldWidget.footerRuningHeight != this.footerRuningHeight || oldWidget.footerMinHeight != this.footerMinHeight || oldWidget.footerMinHeight != this.footerMinHeight || oldWidget.noMoreDataHeight != this.noMoreDataHeight || oldWidget.footerSuccessHeight != this.footerSuccessHeight || oldWidget.footerSuccessDuration != this.footerSuccessDuration;
    }
    return true;
  }
}
