# AVFoundationDemo
本项目主要用于调研AVFoundation的视频播放和视频编辑的用法.

## 视频播放
KYMediaPlayerView 封装了AVPlayer的播放功能, 支持系统在线播放以及边下边播功能. 默认为

```
KYMediaPlayerView *view = [[KYMediaPlayerView alloc]initWithFrame:CGRectMake(0,0,100,100)];
view.playWhileDownload = YES;//边下边播(默认为NO, 下载之后播放)
view.systemResourceLoader = NO;//使用自定义下载器
view.autoplay = YES;//加载成功之后自动播放
view.mediaURL = <#URL#>;
[view startLoad];//开始加载

```

## 视频编辑
AVFoundationUtils 封装了一些编辑视频的方法, 比如调整视频大小, 模糊视频, 合并视频, 画中画, 视频转LivePhoto等.
