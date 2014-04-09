var MHGJavascriptBridge = (function(){
	var scheme = "mhgjavascriptbridge";
	var host = "mhgjavascriptbridge.herkuang.info";
	var action = "call_native_block";
	var makeURL = function(funcName, arguments) {
		var URL = scheme+"://"+host+"/"+action+"/"+funcName+"/";
		var argsArray = Array.prototype.slice.call(arguments);
		var argsString = encodeURIComponent(JSON.stringify(argsArray));
		URL += "?params="+argsString;
		return URL;
	};

	return {
		callNativeBlock: function(funcName, arguments) {
			return makeURL(funcName, arguments);
		}
	};

})();


var test = MHGJavascriptBridge.callNativeBlock("hahaha",[1,2,3,4,5,{"aaa":"dddd"}]);

console.log(test);
