## ScrollView

`ScrollView`比较重要的属性为：slivers，即滚动视图中所有的子小部件

从`ScrollView`的build方法中可以看出，ScrollView通过创建一个`Scrollable`,并且在`Scrollable`的参数viewportBuilder中返回一个`Viewport`，然后把从`Scrollable`来的`ViewportOffset`和自身的属性slivers传递给`Viewport`，`Viewport`再通过`RenderViewport`来绘制具体需要显示在屏幕上的内容。

先来看看`ViewportOffset`，官方文档的说明说的是：确定哪一部分应该是可见的。属性pixels表示滚动偏移量，同时继承自`ChangeNotifier`表示这个类是可监听的，ScrollView的实现方式即为依靠这个类。

两个比较重要的方法：applyViewportDimension、applyContentDimensions

applyViewportDimension是建立可视范围，参数是在主轴上的尺寸，即垂直滚动为高度，水平滚动为宽度。

applyContentDimensions是建立内容的范围，minScrollExtent表示内容的最小滚动位置，maxScrollExtent表示内容的最大滚动位置。

`RenderViewport`继承自`RenderBox`，`RenderBox`是具有大小的，所以`RenderViewport`会调用上述两个方法来确定完整的`ViewportOffset`，同时`RenderViewport`会使用`ViewportOffset`pixels值来获得滚动偏移量，从而绘制屏幕类容

总结就是`Scrollable`负责获得`ViewportOffset`，`RenderViewport`负责通过`ViewportOffset`和slivers绘制内容。

## Scrollable

Flutter中最终负责滚动的widget叫做 `Scrollable`

`Scrollable` 中比较重要的几个属性

controller、physics、viewportBuilder.这几个属性均由`ScrollView`传递而来

`Scrollable`继承自`StatefulWidget`,它是一个有状态的小部件，他的状态类为`ScrollableState`

有一个静态方法`Scrollable.of(BuildContext context)`。可以获取小部件树中最近的`ScrollableState`

## ScrollableState

`ScrollableState`中比较重要的属性position、physics，类型分别为`ScrollPosition` `ScrollPhysics`

`ScrollPosition`确定哪一部分在滚动视图中可见，`ScrollPhysics`确定如何滚动。

在didChangeDependencies中，`ScrollableState`会更新或创建position和physics，didChangeDependencies在initState和一些其他情况下会调用。
其中position从`ScrollController`的createScrollPosition方法中创建，在创建position时，会传递一个`ScrollContext`类型的实例给position，实例为`this`本身。
`ScrollPhysics`是从上层传参而来

从`ScrollableState`的build方法中可以看出，`ScrollableState`处理了滚动相关的手势事件，手势事件的设置是在setCanDrag方法中，方法的参数为一个bool类型，从方法的名字可以看出该方法时设置是否可以拖拽。
这个方法做了什么?
如果参数为false，则取消所有事件，并且调用一次_handleDragCancel().
如果参数为true，会根据滚动方向设置onDown、onStart、onUpdate、onEnd、onCancel等一些事件.

下面进入手势处理环节

`ScrollableState`中实际并不处理手势的细节，而是通过两个属性_drag、_hold将事件传递给position中处理。_drag和_hold通过position创建，然后通过相应的事件回调调用不同的方法告诉position。

## ScrollPosition
`ScrollPosition`是一个抽象类，继承自`ViewportOffset`->`ChangeNotifier`

是不是很熟悉，`ScrollPosition`就是一个`ViewportOffset`，也就是会传递给`RenderViewport`的东西，它负责管理滚动的偏移量以及内容区域

`ScrollPosition`使用`ScrollActivity`来处理任何滚动活动。

`ScrollActivity`通过`ScrollActivityDelegate`来回调告诉`ScrollPosition`应该如何做，`ScrollActivityDelegate`有4个方法：

setPixels：设置偏移量
applyUserOffset：应用用户偏移量
goIdle:终止当前活动并开始一个空闲活动
goBallistic:终止当前活动并以给定速度开始弹道活动。

`ScrollActivity`的子类：

`DragScrollActivity`，用于管理拖拽滚动活动



前面说过`ScrollPosition`，是在`ScrollableState`中由`ScrollController`创建，默认创建的是它的子类`ScrollPositionWithSingleContext`。

关于滚动的大部分工作都是在这个类里面处理的，它通过`Drag`和 `ScrollHoldController`从`ScrollableState`中接管了手势事件，同时前文中`ScrollableState`的setCanDrag方法由它调用，所以它同时具有管理是否响应手势的能力。

`RenderViewport`在绘制时会调用applyViewportDimension，applyContentDimensions（前文有提），然后`ScrollPosition`调用`ScrollContext`（`ScrollableState`）的setCanDrag接管事件。




