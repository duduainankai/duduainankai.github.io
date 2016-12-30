---
layout: post
title: "阿里云OSS初体验"
date: 2016-08-03 15:27:32 +0800
comments: true
categories: 项目 Java
---

&emsp;&emsp;终于开始放暑假了，这一个学期一边要带着几个学弟一起做实验室项目还要一边上CSDI这种神课真的是身心具疲。不过确实也收获了很多原来不曾有过的体验，也算有所成长了吧。现在放假了也可以有时间来总结总结这个项目里的内容了。

&emsp;&emsp;先记录其中一个最感兴趣也比较新鲜的阿里云对象存储OSS的使用吧。<!--more-->

###OSS是什么
&emsp;&emsp;阿里云对象存储服务（Object Storage Service，简称 OSS），是阿里云提供的海量、安全、低成本、高可靠的云存储服务。简单来说把每一个被存储的文件看作一个对象，可以通过API或者控制台的方式进行上传下载。同时支持流式写入和文件写入，以及流式读取文件。可以与CDN搭配使用，OSS作为源站，提供稳定、高带宽的服务。

###选择OSS的原因
&emsp;&emsp;简单来说这个项目要完成的一个点就是开发的网站上面能够提供上传视频、视频存储以及多人同时观看视频的功能。

&emsp;&emsp;为了保证视频文件的可用性，在最初的设计上我们采用的方式是后端用开源的hdfs来存储文件，同时利用hadoop提供的Java API额外开发一个与文件系统进行上传下载交互的应用服务，使用tomcat作为应用服务器。

&emsp;&emsp;当我们确实这么开发完成后发现其实存在着很多的不足之处，甚至是比较严重的问题:

&emsp;&emsp;1.每一次视频的请求都需要两次的视频传输。第一次是从hdfs到应用服务器的传输，第二次是应用服务器返回给前端页面的传输。

&emsp;&emsp;2.视频的流式传输需要自己实现。

&emsp;&emsp;对于第一点，每一次传输都要占据一定的带宽，特别是当视频比较大的时候，多一次的传输意味着多一倍的等待时间。我们试过在应用服务器下缓存热度高的视频，但这毕竟不能彻底解决这个问题。第二点又更是个大问题了，而且一开始并没有考虑到只是简单的从hdfs读取到文件后写进response的输出流中，于是返回到播放器中的视频必须全部下载完以后才能够拖动进度条，否则的话会继续从头开始播放，极大的影响了用户体验。

&emsp;&emsp;后来网上搜了一圈相应的解决方案，论坛里有人提到可以使用OSS，于是就到阿里云官网简单的了解了一下。在使用OSS的情况下，新增的文件系统的应用服务器完全由阿里云的服务提供，而不用我们维护，同时支持流式读取文件也可以很好的解决视频拖拽播放的需求。于是就要苦逼的把原来上传下载的逻辑都重新写过了。

###OSS的使用

&emsp;&emsp;阿里云OSS提供了许多的SDK，还是很人性化的，但是也看到很多人在论坛吐槽文档不够详细，刚好记录下自己摸索的过程。短时间内解决这个也有着不小的挑战，但是毕竟有着死线在驱动效率也是高了不少。

####准备工作
	
&emsp;&emsp;其实就是要开通OSS服务，选择套餐，实名认证，我们采用的是半年40G的存储包，只要5块钱还是相当划算的。然后需要创建一个存储空间即bucket，获取账号的accessId和accessKey。

####使用OSS

&emsp;&emsp;官网提供了三个教程进阶的介绍了直接在客户端签名、在服务端签名、在服务端签名并设置回调来讲解在一个web应用中使用OSS。对于第一种直接把accessId和accessKey暴露在客户端JS代码中的方式有风险，并不推荐在项目中使用，因此我也就不记录了。

**服务端签名，没有回调**

&emsp;&emsp;在服务器端用accessId、accessKey和有效时长进行签名，客户端通过ajax请求获取的方式是比较安全的。整个流程的示意图是：

![](http://7xqncq.com1.z0.glb.clouddn.com/oss1.png)

&emsp;&emsp;然后来看看服务器端生成签名的代码吧。记得要先导入阿里云提供的aliyun-sdk-oss-2.0.6.jar、aliyun-java-sdk-sts-2.1.6.jar、aliyun-java-sdk-core-2.1.7.jar这三个包。

``` java
private final static String endpoint = "你的OSSendpoint";
private final static String accessId = "你账号的accessId";
private final static String accessKey = "你账号的accessKey";
private final static String bucket = "文件上传到的bucket";
private String host = "https://" + bucket + "." + endpoint;

/**
 * 生成签名policy的函数
 * @param dir  存储所上传文件的bucket下的文件夹
 */
private void generatePolicy(String dir) {
    // 初始化oss客户端
    OSSClient client = new OSSClient(endpoint, accessId, accessKey);
    try { 	
    	long expireTime = 3000;		// 签名有效时长，单位秒
    	long expireEndTime = System.currentTimeMillis() + expireTime * 1000;
        Date expiration = new Date(expireEndTime);
        PolicyConditions policyConds = new PolicyConditions();
        policyConds.addConditionItem(PolicyConditions.COND_CONTENT_LENGTH_RANGE, 0, 1048576000);
        policyConds.addConditionItem(MatchMode.StartWith, PolicyConditions.COND_KEY, dir);

        // 生成签名
        String postPolicy = client.generatePostPolicy(expiration, policyConds);
        byte[] binaryData = postPolicy.getBytes("utf-8");
        String encodedPolicy = BinaryUtil.toBase64String(binaryData);
        String postSignature = client.calculatePostSignature(postPolicy);
        dataMap.put("accessid", accessId);
        dataMap.put("policy", encodedPolicy);
        dataMap.put("signature", postSignature);
        dataMap.put("dir", dir);
        dataMap.put("host", host);
        dataMap.put("expire", String.valueOf(expireEndTime / 1000));
    
        // 需要在oss控制台设置cros，允许post方法的执行
        response.setHeader("Access-Control-Allow-Origin", "*");
        response.setHeader("Access-Control-Allow-Methods", "GET, POST");
    } catch (Exception e) {
    	e.printStackTrace();
    }
}

``` 
&emsp;&emsp;前端通过ajax等方式发送请求获取到这个policy，然后构造相应的表单数据发送请求给oss，就可以实现文件的上传了。

``` java
url: host, // 后台返回的host
data: { 
    'key' : g_object_name,	// 存储的文件名
    'policy': policyBase64,	// 从后台获取的policy
    'OSSAccessKeyId': accessid, // 从后台获取的accessid
    'success_action_status' : '200', //让服务端返回200,不然，默认会返回204
    'signature': signature, // 从后台获取的签名
    file: $scope.file // 上传的文件，该字段一定要放在最后，否则会报400
}
```

**服务端签名，设置回调**

&emsp;&emsp;很多时候只实现了文件的上传并不够。比如用户上传一个视频后我们往往还需要往数据库里添加一条记录，记录是谁上传了视频，上传的视频在哪个分类下等等。OSS提供了设置回调函数的功能，使得可以在完成文件上传后向我们指定的应用服务器的接口发送一个相应的请求来实现上面的。这时候的流程图和生成policy的代码是这样的:

![](http://7xqncq.com1.z0.glb.clouddn.com/oss2.png)

``` java
private final static String endpoint = "你的OSSendpoint";
private final static String accessId = "你账号的accessId";
private final static String accessKey = "你账号的accessKey";
private final static String bucket = "文件上传到的bucket";
private String host = "https://" + bucket + "." + endpoint;

/**
 * 生成签名policy的函数
 * @param dir  存储所上传文件的bucket下的文件夹
 * @param callback_param  回调函数组成的字符串
 */
private void generatePolicy(String dir, String callback_param) {
    OSSClient client = new OSSClient(endpoint, accessId, accessKey);
    try { 	
    	long expireTime = 3000;		// 签名有效时长，单位秒
    	long expireEndTime = System.currentTimeMillis() + expireTime * 1000;
        Date expiration = new Date(expireEndTime);
        PolicyConditions policyConds = new PolicyConditions();
        policyConds.addConditionItem(PolicyConditions.COND_CONTENT_LENGTH_RANGE, 0, 1048576000);
        policyConds.addConditionItem(MatchMode.StartWith, PolicyConditions.COND_KEY, dir);

        String postPolicy = client.generatePostPolicy(expiration, policyConds);
        byte[] binaryData = postPolicy.getBytes("utf-8");
        String encodedPolicy = BinaryUtil.toBase64String(binaryData);
        String postSignature = client.calculatePostSignature(postPolicy);
        dataMap.put("accessid", accessId);
        dataMap.put("policy", encodedPolicy);
        dataMap.put("signature", postSignature);
        //dataMap.put("expire", formatISO8601Date(expiration));
        dataMap.put("dir", dir);
        dataMap.put("host", host);
        dataMap.put("expire", String.valueOf(expireEndTime / 1000));
        
        // 如果回调函数的字符串不为空则添加，否则即为不需要回调的方法
        if (callback_param != null) {
            byte[] binaryDatas = callback_param.getBytes();
            String callback = BinaryUtil.toBase64String(binaryDatas);
            dataMap.put("callback", callback);
        }
    
	response.setHeader("Access-Control-Allow-Origin", "*");
        response.setHeader("Access-Control-Allow-Methods", "GET, POST");
    } catch (Exception e) {
    	e.printStackTrace();
    }
}
```
&emsp;&emsp;这是callback_param的一个例子：

``` java
String callback_param="{" + 
    "\"callbackUrl\":" +
    "\""+ callbackurl + "\"," + 
    "\"callbackBody\":" +
    "\"bucket=${bucket}&object=${object}&size=${size}&mimeType=${mimeType}" +
    "&imageInfo.height=${imageInfo.height}&imageInfo.width=${imageInfo.width}" +
    "&name=${x:name}&token=" + token + "&videotype=1\"" + 
"}";
// bucket等参数是oss执行回调时会自动加上的参数，而如果我们需要自定义参数并且需要在执行到上传文件的请求时才能确定的，
// 比如这边的name，那么我们需要采用${x:***}的方式，***表示的是变量名
// 而可以在生成policy就知道值的参数比如这边的token那么直接拼接字符串就行了
// callbackurl需要指定相应回调请求的服务器、端口和URL，method为POST
```

&emsp;&emsp;前端构造的上传文件的数据中需要增加回调body和自定义参数的值：

``` java
url: host,
data: { 
  'key' : g_object_name,	// 存储的文件名
  'policy': policyBase64,	// 从后台获取的policy
  'OSSAccessKeyId': accessid, // 从后台获取的accessid
  'success_action_status' : '200', //让服务端返回200,不然，默认会返回204
  'signature': signature, // 从后台获取的签名
  'callback' : callbackbody,	// 从后台获取的回调内容
  'x:name' : $scope.file.name,	// 自定义参数name的值，键一定要是x:***的形式
  file: $scope.file // 上传的文件，该字段一定要放在最后，否则会报400
}
```

&emsp;&emsp;这样就完成了整个OSS上传文件的过程啦，其实做完了来看好像内容也不多，但刚上手的时候还是有很多困惑，特别是自定义参数那一块，好多人都在吐槽文档写的不清楚。

&emsp;&emsp;除此之外，OSS还可以与许多的富文本编辑器结合，比如我们项目中采用的是summernote。原本上传图片的话summernote会直接编码图片成字符串，然后与其他文本内容放在一起存进数据库里，但这样一来图片多的话编码出的字符串会特别大，从数据库取出的耗时会特别长。如果修改成上传的图片存储到OSS中，那么编码之后的内容就只是一个图片的地址，这样就小很多了。

###总结

&emsp;&emsp;其实不止是阿里云，越来越多的云厂商包括腾讯云、七牛云等等都提供了相应的对象存储服务。而越来越多的云服务比如云主机、云数据库等等也越来越方便了开发者，好比利用了OSS省去了自建存储系统的过程，同时自带三备份、与CDN相结合提高访问速率，让开发者可以专注业务逻辑的实现，这确实是造福广大开发者的好事。

&emsp;&emsp;我也相信越来越多的服务都会往云上迁移，越来越多的开发者也会更多的了解到这些云产品的使用甚至是开发。