## 简介

MHGJavascriptBridge是用于iOS开发中，UIWebView中的Javascript和Objective C代码互相调用的简单封装。

## 用法

MHGJavascriptBridge由3个文件组成，`MHGJavascriptBridge.h`, `MHGJavascriptBridge.m`, `MHGJavascriptBridge.js`。将这三个文件加入Xcode工程中。注意，`MHGJavascriptBridge.js`必须加入到资源文件中（在"Building phases" -> "Copy bundle resources"中出现），Xcode默认会将.js文件加入到Compile Sources里面去，这是错误的。

### Objective C设置

首先，我们需要初始化一个bridge，这通常是在一个UIViewController中进行的。这里假设在UIViewController中对bridge进行初始化。在初始化中，需要设定bridge的`webView`属性：

	@interface MHGWebViewController ()<UIWebViewDelegate>

	@property (nonatomic, strong) MHGJavascriptBridge *bridge;
	@property (nonatomic, strong) UIWebView *webView;
	
	@end
	
	...
	
	- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
	{
	    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	    if (self) {
	        _bridge = [[MHGJavascriptBridge alloc]init];
	        _bridge.webView = self.webView;
	    }
	    return self;
	}

在MHGJavascriptBridge中，所有能被Javascript调用的Objective C方法将以block的形式呈现。首先我们需要定义一些blocks，然后对每一个block起名。

	- (void)viewDidLoad
	{
	    [super viewDidLoad];
	    
	    [self.bridge setBlockName:@"button1OnClick" block:^(NSDictionary *dict) {
	        // do stuff
	        NSLog(@"button1 on click with params:%@", dict);
	    }];
	    [self.bridge setBlockName:@"beginSomeTasks" block:^(NSDictionary *dict) {
	        // do stuff
	        NSLog(@"begin some tasks with params:%@", dict);
	    }];
	    ...
	}
	
MHGJavascriptBridge的原理是构造特定的URL，并且用`UIWebViewDelegate`中的`- (BOOL)webView:shouldStartLoadWithRequest:navigationType:`拦截这个URL。所以在这个delegate方法中，我们需要加入拦截语句：

	- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
	{
	    BOOL intercepted = [self.bridge interceptRequest:request]; //必须有
	    // Do other things ...
	    return YES;
	}

其中，`interceptRequest:`方法会返回一个`BOOL`，如果拦截成功，则返回`YES`。

这样，Objective C部分就设置完成了。其中需要注意的是，block被调用时，会传入一个`dict`，这是Javascript部分代码调Objective C代码时所传的参数。

### Javascript设置

Javascript部分设置比较简单，最基本的设置是要保证UIWebView中的HTML引入了`MHGJavascriptBridge.js`：

	<script src="MHGJavascriptBridge.js"></script>

### Javascript调用Objective C代码

一旦设置完成之后，Javascript和Objective C就能互相调用了。代码如下：

	var button1ClickEventHandler = function (){
		// Do stuff ...
		MHGJavascriptBridge.callNativeBlock('button1OnClick',{'url':imageURL});
	};

	<button onClick="button1ClickEventHandler">button 1</button>
	
这时，点击button1时，就能触发Objective C的代码了。`MHGJavascriptBridge.callNativeBlock`有两个参数，第一个参数是在Objective C中注册的block名字，第二个参数是传给block里面的`dict`的额外信息。其中第二个参数必须是一个字典（或者说是一个Javascript Object），或者什么都不传。

### Objective C调用Javascript代码

方法和上述类似：

	...
	
	[self.bridge callJavascriptFunction:@"setImageWithURL" withParams:@[fileURL.absoluteString]];
	
	...
	
其中第一个参数是Javascript函数名。如果你在HTML中定义了`function xxx(){}`或者`var xxx = function(){}`的话，就能被调用。第二个参数是一个数组，传的是Javascript函数要用的参数列。

## 已知问题

* Javascript调用Objective C时，所有的调用都是异步的，暂时无法实现同步调用。