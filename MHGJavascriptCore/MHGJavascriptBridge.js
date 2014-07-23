var MHGJavascriptBridge = (function(){
	var scheme = "mhgjavascriptbridge";
	var action = "call_native_block";
	var messagingIframe;
	var makeURL = function(funcName, argsDict) {
		var URL = scheme+"://"+action+"/"+funcName;
		if(argsDict!=null){
			var argsString = encodeURIComponent(JSON.stringify(argsDict));
		    URL += "?params="+argsString;
		}
		return URL;
	};
	var init = function() {
		messagingIframe = document.createElement('iframe');
		messagingIframe.style.display = 'none';
		document.documentElement.appendChild(messagingIframe);
	};
	init();

	var _callNativeBlock = function(funcName, argsDict){
		messagingIframe.src = makeURL(funcName,argsDict)
	};

	return {
		callNativeBlock: _callNativeBlock
	};

})();
