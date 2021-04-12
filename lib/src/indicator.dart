import 'package:flutter/material.dart';
import 'package:refresh/src/configuration.dart';
import 'package:refresh/src/status.dart';

class BasisHeaderRefreshIndicator extends StatelessWidget {
  BasisHeaderRefreshIndicator({this.status, this.configuration, this.offest});
  final RefreshStatus status;
  final RefreshConfiguration configuration;
  final double offest;
  @override
  Widget build(BuildContext context) {
    switch (status) {
      case RefreshStatus.drag:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_downward),
            SizedBox(width: 8),
            Text("下拉刷新"),
          ],
        );
      case RefreshStatus.armed:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_upward),
            SizedBox(width: 8),
            Text("松手即可刷新"),
          ],
        );
      case RefreshStatus.success:
        return Center(
          child: Text("刷新成功"),
        );
      case RefreshStatus.done:
        return Center(
          child: Text("刷新完成"),
        );
      case RefreshStatus.refresh:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            SizedBox(width: 8),
            Text("正在刷新"),
          ],
        );
      default:
        return Container();
    }
  }
}

class BasisFooterRefreshIndicator extends StatelessWidget {
  BasisFooterRefreshIndicator({this.status, this.configuration, this.offest});
  final RefreshConfiguration configuration;
  final RefreshStatus status;
  final double offest;
  @override
  Widget build(BuildContext context) {
    switch (status) {
      case RefreshStatus.drag:
        return Center(
          child: Text("上拉加载更多"),
        );
      case RefreshStatus.armed:
        return Center(
          child: Text("松手即可加载数据"),
        );
      case RefreshStatus.success:
        return Center(
          child: Text("刷新成功"),
        );
      case RefreshStatus.done:
        return Center(
          child: Text("刷新完成"),
        );
      case RefreshStatus.nomoredata:
        return Center(
          child: Text("没有更多数据了"),
        );
      case RefreshStatus.refresh:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            SizedBox(width: 8),
            Text("正在加载数据"),
          ],
        );
      default:
        return Container();
    }
  }
}
