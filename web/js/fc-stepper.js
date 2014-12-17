$(document).ready(function(){

	function getUrlparameter (strParam) {
      
      var strPageUrl = window.location.search.substring(1);

      var strUrlVars = strPageUrl.split('&');

      for (var i = 0; i < strUrlVars.length; i++) {
        
        var strParamName = strUrlVars[i].split('=');

        if (strParamName[0] ==strParam ) {
          return strParamName[1];
        }
      }

    }

    var param = getUrlparameter("dtype");

    console.log(param);

    //if (param == "CLUBOFFICIAL") {
    	
    //}

    var countFormStep = $("ul.playermenu li").size();
    var playermenuElement = $("ul.playermenu li");
    
    if (countFormStep == 7){
    
    	$(playermenuElement).addClass("sevenStepWidth");
    
    } else if (countFormStep == 8){
    	
    	$(playermenuElement).addClass("eightStepWidth");

    } else if (countFormStep == 6) {

    	$(playermenuElement).addClass("sixStepWidth");
    
    } else if (countFormStep == 5) {

      $(playermenuElement).addClass("fiveStepWidth");

    }

});