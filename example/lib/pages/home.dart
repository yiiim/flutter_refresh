import 'package:flutter/material.dart';

import 'package:refresh_widget/refresh_widget.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  bool _footerNoMoreData = false;
  int _itemCount = 10;
  RefreshScrollController _refreshScrollController = RefreshScrollController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: RefreshConfiguration(
        headerSuccessDuration: Duration.zero,
        child: RefreshWidget(
          footerNoMoreData: _footerNoMoreData,
          scrollController: _refreshScrollController,
          onHeaderRefresh: () async {
            await Future.delayed(Duration(seconds: 3));
            setState(() {
              _itemCount = 10;
              _footerNoMoreData = false;
            });
            return true;
          },
          onFooterRefresh: () async {
            await Future.delayed(Duration(seconds: 3));
            setState(() {
              _itemCount += 10;
              if (_itemCount > 30) _footerNoMoreData = true;
            });
            return true;
          },
          child: ListView.builder(
            controller: _refreshScrollController,
            physics: AlwaysScrollableScrollPhysics(),
            itemCount: _itemCount,
            itemBuilder: (context, index) {
              return ListTile(title: Text("$index"));
            },
          ),
        ),
      ),
    );
  }
}
