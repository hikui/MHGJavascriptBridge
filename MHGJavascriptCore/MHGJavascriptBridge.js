var MHGJavascriptBridge = (function(){
	var scheme = "mhgjavascriptbridge";
	var action = "call_native_block";
	var makeURL = function(funcName, argsDict) {
		var URL = scheme+"://"+action+"/"+funcName+"/";
		var argsString = encodeURIComponent(JSON.stringify(argsDict));
		URL += "?params="+argsString;
		return URL;
	};

	return {
		callNativeBlock: function(funcName, argsDict) {
			window.location.href = makeURL(funcName, argsDict);
		}
	};

})();
