---
layout: post
title: "终端版知乎客户端"
date: 2016-07-17 10:03:05 +0800
comments: true
categories: 项目 爬虫 python
---

&emsp;&emsp;搭完博客也过去大半年都有了却什么都还没写过，虽然不能用太忙来做借口(其实就是懒)，不过过去的一个学期确实感觉有够忙的。

&emsp;&emsp;但是好歹也学了点东西，特别是开始写python了感觉真的很爽，于是就有了这个用爬虫做的终端版的知乎客户端。可以用命令行来刷知乎，用命令来点赞，感觉还挺有意思的。

&emsp;&emsp;直接上Github咯：[终端版知乎客户端](https://github.com/duduainankai/zhihu-terminal)<!--more-->

### 准备

&emsp;&emsp;记得很早之前有天在刷知乎的时候TL里出现了一个很有趣的问题：[能利用爬虫技术做到哪些很酷很有趣很有用的事情？](https://www.zhihu.com/question/27621722)，看着各种高票回答感觉自己也心动了，也想做些有意思的事情。而且一直也想好好的学一下python，以前虽然看过一遍教程跟过公开课不过就算都拿了证书也只是在各种print，没做过什么有用的东西很快也就都忘了。

&emsp;&emsp;于是就先找了一遍知乎上关于python入门的回答，大致看了一遍learn python the hard way，感觉基本语法差不多了也就开始重点找爬虫的资料了，感觉一边写一边学效果会更好。

### 爬虫

**我所认为的爬虫可以概括为任何用代码、机器模拟人为浏览器访问网站及其操作的过程。**

&emsp;&emsp;知乎上有许多关于爬虫入门的回答，想来也挺有趣的：我在知乎上学爬虫然后来爬知乎。首先当然是要有一些计算机网络的知识了，至少了解到什么是get方法、什么是post方法，两者之间的区别这样；然后就可以动手开始写啦。一开始也是用urllib和urllib2写过一两个小爬虫的，但是自从后来一接触到了[requests](https://github.com/kennethreitz/requests)之后就被折服了，因为实在太方便了，有人评价说是一键安装的效果，感觉很到位。

&emsp;&emsp;然后就可以开始着手爬一些东西了，比如网上各种教程说的豆瓣、贴吧和糗事百科之类的。有天发现了别人说的爬虫闯关网站：[黑板客爬虫闯关](http://www.heibanke.com/lesson/crawler_ex00/)，用来学爬虫应该是非常合适的，由易到难，也包括了以后要用到的模拟登录和多线程等，值得推荐。

### 终端版知乎

&emsp;&emsp;在找爬虫资料的时候看到别人做的终端版的豆瓣FM和Twitter，于是就开了个脑洞想着自己能不能做一个终端版的知乎客户端出来，以后用命令行来刷知乎是不是会感觉更酷一点。

&emsp;&emsp;在Github上搜了一圈也发现了许多爬知乎的项目，找了一两个学习了一下就开始动手写了。

####登录

&emsp;&emsp;首先面对的问题就是登录，登录过后才能查看属于自己的Time Line，才能给别人点赞、关注问题，在早期开始写的时候登录并不需要验证码，所以一个post把账号密码传到服务器就搞定了，但是我发现一边在爬的时候知乎也一边在增加反爬虫的机制了。比如登录的过程中开始增加验证码了，而且获取验证码的url也改了：http://www.zhihu.com/captcha.gif?r=1468727020613&type=login，参数r表示的是当前时间的时间戳，重点是一定要带上type＝login这个参数，否则取到的验证码是无效的！也不知那天怎么就偷懒没加这个参数，结果试了半天也不对。

####cookie

&emsp;&emsp;cookie是网站为了辨别用户身份、进行session跟踪而存储在用户本地的数据，也就是说网站用cookie来识别你是谁，在完成了登录之后服务器就会返回cookie.在这接下来的点赞、关注等操作我们的请求都要带上这个cookie才行，否则服务器都不知道你是谁怎么给你增加关注的问题呢？ 所以如果爬知乎请求返回的错误码是403，那基本就是因为你没表明身份了，这个可是我的血汗经验，：）。

&emsp;&emsp;requests也提供了很方便的管理cookie的方式。

``` python
	session = requests.Session()
	
	data = {
        "email": email,
        "password": password,
        "remember_me": "true",
        "_xsrf": _xsrf,
        "captcha": captcha
    }
    
	session.post(url="https://www.zhihu.com/login/email", data=data)
```

&emsp;&emsp;就这么简单cookie就被保存在session中了，接下来所有的请求只要通过session来处理就可以咯。

``` python
	# 可以查看cookie有哪些
	for cookie in session.cookies:
		print cookie
```

####获取html源码中的内容

&emsp;&emsp;有了以上的准备之后向"https://www.zhihu.com"发请求就可以得到首页的TL了(未登录用户的话会被重定向的)，这时候获得的是html页面的源码，我们要做的就是从中解析出相应的内容，这时候就要用上另一个神器[Beautiful Soup 4](http://www.crummy.com/software/BeautifulSoup/)了。它可以将html文本转换成DOM树模型，提供各种各样的选择器来简化获取数据的难度，比起用正则表达式来匹配数据的方式高到不知道哪里去了。但我也还是建议掌握正则表达式的用法，在一些获取简单数据如_xsrf上还是很方便的，而且感觉还是写正则比较帅。

####解决JS中的请求

&emsp;&emsp;很多时候数据是通过在JavaScript脚本中触发请求去获取的，就像上文请求到的Time Line只包括了首页的20条动态，而在往后知乎就是通过JS动态请求数据的，显然在终端中是无法触发到那段JS的。

&emsp;&emsp;而要解决这个问题，最核心的在于确定请求数据的API，Chrome的开发者模式就提供来很大便利了。打开console，查看network，就很容易发现请求的url了。

![](http://7xqncq.com1.z0.glb.clouddn.com/console.png)

&emsp;&emsp;很容易发现上图中HomeFeedListV2就是获取下一页Time Line的请求啦，于是就又能愉快的继续下去了，包括后来所有的点赞、关注问题等等也都是这样来处理的。

&emsp;&emsp;PS. console里会发布招聘信息的，好像很多互联网都喜欢这么搞了。

####多线程提升体验

&emsp;&emsp;如果在刷TL的时候总是等到用户已经看到这一页的时候在去请求就会感觉到明显的卡顿，因为网络请求总是需要耗时的，感觉这样体验就不太好，于是为了提升响应速度我采用了多线程的方式。

&emsp;&emsp;当前一个主线程在监听用户的输入并作相应的处理，然后再开一个线程在后台请求TL的数据，为了良心的爬知乎，不给服务器造成过大的压力我设定了一个阈值：保证有十页的内容给用户看，否则才让线程取数据，并且一秒只发一个请求。这也是在学爬虫的时候看到的建议：我们是在获取数据，而不是在给别人的服务器做压力测试。而只开一个线程是为了保证获取到的数据在时间上是保证连续的，如果有多个线程返回的话就需要额外的开销来维护，所以没有选择这么做。这样一来客户端响应的时间确实快了很多，刷起TL来也更开心了：）。

####效果图

&emsp;&emsp;一起看看效果吧:

![登录](http://7xqncq.com1.z0.glb.clouddn.com/login.png)
![Time Line](http://7xqncq.com1.z0.glb.clouddn.com/TimeLine.png)
![help](http://7xqncq.com1.z0.glb.clouddn.com/help.png)
![用命令点赞](http://7xqncq.com1.z0.glb.clouddn.com/zan.png)
![知乎动态更新](http://7xqncq.com1.z0.glb.clouddn.com/zhihu.png)

####TODO

&emsp;&emsp;现在的功能还比较基本，主要是我一般也就看看不太爱答题或者评论，不过以后应该会接着扩展的，包括导出答案备份、增加评论等等的功能，反正会一直维护下去的吧，因为这算是我目前为止自己最喜欢的一个项目了。

&emsp;&emsp;加油。
