---
layout: post
title: "铅笔画和图片墙"
date: 2016-10-23 10:03:05 +0800
comments: true
categories: 项目 python
---

&emsp;&emsp;有一天在逛知乎的时候看到了有人推荐了一篇论文: [Combining Sketch and Tone for Pencil Drawing Production](<http://www.cse.cuhk.edu.hk/leojia/projects/pencilsketch/pencil_drawing.htm>)。讲的是一个关于铅笔画算法的实现，看作者贴了一些效果图觉得相当有趣，看着就想着试试看有没可能自己也实现一下。

&emsp;&emsp;刚好中秋前刚从医院回来，国庆也不打算出门了，就用这两个假期看看论文研究一下，然后照着开源的matlab代码用python重新实现了一遍(其实就是翻译了一下。。)。最后在网上找了一个开源的图片墙页面，把处理的结果贴一下，也算是从头到尾做完一整套了吧。

&emsp;&emsp;依旧还是先上GitHub：[python版铅笔画](<https://github.com/duduainankai/pencil-python>)。然后是[图片墙](<http://lizheming.top/blog/pencil>)。<!--more-->

### 铅笔画算法
	
&emsp;&emsp;论文几位作者都来自香港中文大学，12年npar的best paper，还是挺厉害的了。论文的工作就是给定一张正常的比如相机的图片，然后通过一定的处理可以得到同一张图片用✏️画出来的效果，挺有意思的对吧。但是因为原先基本没有接触过图像处理的东西，所以论文看起来还是挺费劲的。

&emsp;&emsp;简单来说算法可以分成两大步: 生成笔画结构和色调渲染，最后的处理结果就是这两步的结合，如下图所示(图片来源于论文)。

![](http://7xqncq.com1.z0.glb.clouddn.com/2.png)

#### 生成笔画结构

&emsp;&emsp;生成笔画结构的过程其实就是把图片的轮廓给画出来，就像用铅笔把一个人的身体给描绘出来一样，需要得到物体的边缘线。

&emsp;&emsp;其实这一步是可以有非常简单的做法的，将图片转换成灰度图片以后，我们只需要计算相邻两个像素点值，也就是做一个差分的结果就是轮廓图了(大二学的数字信号处理留给我的唯一印象。。)。因为在灰度值的区间是[0,255]，也就是说如果两个相邻像素点属于同一块区域那么他们的差值会很小，反应在图片上就是一个很暗的点，而如果是一个明显的分界线那么差值比较大就是一个比较亮的点。

&emsp;&emsp;这么做虽然简单，但最大的缺点就是容易受到噪声的干扰，并且只有对于明显的分界线有比较好的效果，对于细节的纹理就没法处理了。论文针对这个内容提出了改进的方法，分为以下两个步骤: classification和line shaping。

**classification**

&emsp;&emsp;目的是将每一个像素点分类到一个方向上。

&emsp;&emsp;在x和y方向上计算差分或者叫梯度，然后求和的平方根作为这个像素点的梯度值。得到梯度以后，将圆周分成八个方向的方法，分别用一个方向向量来表示。同时将这个方向向量作为卷积核，图像的灰度矩阵分别与这八个卷积核做卷积，每个像素点在八个方向上卷积结果最大的就是这个像素点的方向。

&emsp;&emsp;最后处理得到的结果是一个map set，一个前二维与图片大小相同，第三维是方向数的矩阵，表示每一个方向上所属的像素点的梯度值。对于一个像素点而言就是它只在它所属的方向上有值，其余方向上都是0。

**line shaping**

&emsp;&emsp;这一步就是画线的过程，用上一步得到的map set再次和八个方向向量做卷积，这一步会把同一个方向上的像素点连接起来，这样就能够很有效的避免孤立点的存在，细节的纹理能够有很好的体现。

&emsp;&emsp;以上两步完成之后就得到了第一个输出结果S，完成一半的工作啦，来看看处理的效果吧，点击可以看大图。

<div align="center" style="margin-top:20px">	
	<img src="http://7xqncq.com1.z0.glb.clouddn.com/pencildraw/58.jpg" style="height:230px"/>
	<img src="http://7xqncq.com1.z0.glb.clouddn.com/pencildraw/58_s.jpg" style="height:230px"/>
</div>

<div align="center">	
	<img src="http://7xqncq.com1.z0.glb.clouddn.com/pencildraw/sjtu_xuhui.jpg" style="height:205px"/>
	<img src="http://7xqncq.com1.z0.glb.clouddn.com/pencildraw/sjtu_xuhui_s.jpg" style="height:205px"/>
</div>

#### 色调渲染

&emsp;&emsp;铅笔画在完成了图片的笔画结构后，一般来说作者还会通过在不同的地方重复描笔的次数来控制颜色的深浅来描述不同的物体或者是阴影。因此这第二步的工作就是在模拟这个步骤从而给图片上色。这一步也是分成两小步来完成的。

**直方图匹配**

&emsp;&emsp;作者提出一副铅笔画图像的直方图是有一定pattern的，因为只是由黑色的铅笔和白色的纸张构成的。因此可以简单的分成三种区域：bright、mild和dark，同时可以用三种分布来模拟这三个区域：拉普拉斯分布、均匀分布和高斯分布，而一张铅笔画图像的最终直方图分布是这三种分布的加权和。这些权值和分布的控制参数作者直接给出了得到的结果实现的时候也就直接用了，没有给出具体的过程(不过就算有我应该也看不懂。。)。然后将这个直方图和一个正常图片的直方图进行匹配，匹配就是假设在图片中有一个m、n位置的像素点值为200，而在这个图片模拟出的直方图中像素200的点对应y值为100，正常图片直方图中y值最接近100的像素点值是220，那么就将m、n位置上的像素点修正为220的过程。这一步返回的结果就是修正后的图片灰度矩阵。

**纹理渲染**

&emsp;&emsp;这一步在计算每个像素点需要被重复描绘的次数，然后利用一个先前准备好的用于描绘的texture模板图片进行描笔。利用上一步得到的修正的图片灰度矩阵和模板图片的灰度矩阵，以及一个我看不懂的公式就可以算出需要重复的次数beta啦，然后就能愉快的得到结果T了。

&emsp;&emsp;也来看看这一步获得的T的效果吧。

<div align="center" style="margin-top:20px">	
	<img src="http://7xqncq.com1.z0.glb.clouddn.com/pencildraw/58.jpg" style="height:230px"/>
	<img src="http://7xqncq.com1.z0.glb.clouddn.com/pencildraw/58_t.jpg" style="height:230px"/>
</div>

<div align="center">	
	<img src="http://7xqncq.com1.z0.glb.clouddn.com/pencildraw/sjtu_xuhui.jpg" style="height:205px"/>
	<img src="http://7xqncq.com1.z0.glb.clouddn.com/pencildraw/sjtu_xuhui_t.jpg" style="height:205px"/>
</div>

#### 最后的结果

&emsp;&emsp;最后把两步的结果S和T相乘就能得到一个完成的结果啦，两个操作相互complete的。

<div align="center" style="margin-top:20px">
	<img src="http://7xqncq.com1.z0.glb.clouddn.com/pencildraw/58_pencil.jpg" style="height:205px"/>
	<img src="http://7xqncq.com1.z0.glb.clouddn.com/pencildraw/sjtu_xuhui_pencil.jpg" style="height:205px"/>
	<img src="http://7xqncq.com1.z0.glb.clouddn.com/pencildraw/58_color.jpg" style="height:205px"/>
	<img src="http://7xqncq.com1.z0.glb.clouddn.com/pencildraw/sjtu_xuhui_color.jpg" style="height:205px"/>
</div>

&emsp;&emsp;然后我Google了一个简单的图片墙页面，想看更多的图片处理结果可以点[这里](<http://lizheming.top/blog/pencil>)啦，不过图片太多加载可能会有点慢。

#### 总结

&emsp;&emsp;写这个项目就是觉得挺有趣的，花的时间其实也不短，然后写完了也去知乎上答了个问题:[可以用 Python 编程语言做哪些神奇好玩的事情](<https://www.zhihu.com/question/21395276>)，然而放了两张江学长的铅笔画像就被建议修改了。。问题是我修改完了居然也不给恢复正常是要怎样。

&emsp;&emsp;收获也不算少吧，好歹开始入门numpy、scipy这一系列的科学计算库了，也许哪天有时间能好好学学机器学习的时候用得到呢。

&emsp;&emsp;还有一个就是写获得彩色铅笔画的时候，需要从Ycbcr这个颜色通道转换会RGB这个通道，matlab是自带了这个函数的，但是python没有啊。一路google、stackoverflow下来找到的转换方式都不对，但用同样的输出在matlab里转换一下却是对的。我只好用matlab打着断点一步一步的看处理过程，想着要不自己造个轮子好了。可是最后发现matlab调的是一个C函数的实现，然后又接着一路谷歌爆栈网的搜python怎么调C代码，简单了解了下[ctypes](<https://docs.python.org/2.7/library/ctypes.html>)，发现找不到需要的C函数的so文件。更崩溃的是发现这个C的实现里面又调用了matlab的函数，好吧这条路算是走到头了。。最后无奈的又开始探索opencv了。因为最先开始写的时候我看到的帖子里说安装opencv是个非常麻烦的过程，列出了好多步骤看的我头大因此我原来都想着不要用opencv来。但最后走投无路了我就想说用homebrew装一个试下好了，奇迹的是居然还真能有用，看到最后成功的时候真的是在宿舍大叫了一声，还好舍友不在。。

&emsp;&emsp;看论文确实费脑子啊，虽然最后实现出来了但也还是不少看不懂的地方。。想到这学期就得开题了也只能硬着头皮看了，希望最后能有个好结果吧，加油了！COYG！

&emsp;&emsp;最后的最后，祝自己生日快乐吧。

![](http://7xqncq.com1.z0.glb.clouddn.com/pencildraw/71_color.jpg)
