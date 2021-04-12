enum RefreshStatus {
  none, //默认状态
  drag, // 拖拽状态
  armed, // 拖拽状态，但位置已经达到可以刷新的时候了
  refresh, // 正在刷新
  success, //刷新成功，执行一次刷新成功的动画。
  done, // 刷新完成
  faildone, //刷新完成，但是失败了，此时不恢复下拉状态，点击可以重新刷新
  nomoredata //上拉加载使用，没有更多数据了
}
