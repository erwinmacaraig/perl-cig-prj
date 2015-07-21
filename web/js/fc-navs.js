$(document).ready(function(){

  //function to highlight each nav link - we check each action parameter
  //and add class to each active link
  //either we check the href that contains the action parameter or
  //we check the exact string inside the anchor tag

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

    var param = getUrlparameter("a");
    if(!param) { param = ''; }
    var pageHeading = $(".pageHeading").text();

    console.log(param);

    if (param == "E_HOME" || param == "C_HOME" || param == "P_HOME") {
      
      $("header nav ul li a[href*='E_HOME']").addClass("active");
      $("header nav ul li a[href*='C_HOME']").addClass("active");
      $("header nav ul li a[href*='P_HOME']").addClass("active");
    
    } 

    else if (param == "LOGIN") {
      
      $("header nav ul li a[href*='E_HOME']").addClass("active");
    
    }

    else if (param == "E_L") {
      
      $("header nav ul li a:contains(Regions)").addClass("active");
    
    }

    else if (param == "C_L" || param == "C_DTA") {
     
      $("header nav ul li a:contains('Clubs')").addClass("active")

    }
    
    else if (param == "EE_D") {

      $("header nav ul li a:contains(My Club)").addClass("active")

    }

    else if (param == "VENUE_L" || param == "VENUE_DTA") {
      
      $("header nav ul li.subnav a:contains(Venues)").addClass("active");
    
    }

    else if (param == "INITSRCH_P" || param == "PF_" || param == "DUPL_L" || param == "PRA_T" || param == "PRA_R" || param == "PREGFB_T" ||  pageHeading == "Search") {
     
      $("header nav ul li.subnav a:contains(People)").addClass("active")

    }

    else if (param == "TXN_PAY_INV" ) {
     
      $("header nav ul li.subnav a:contains(Payments)").addClass("active")

    }

    else if (param == "WF_" || param == "PENDPR_") {
     
      $("header nav ul li.subnav a:contains(Work Tasks)").addClass("active")

    }

    else if (param.match(/^REP_/))  {
      
      $("header nav ul li a[href*='REP_SETUP']").addClass("active");
    
    }

    else if (param == "P_PASS") {
      
      $("header nav ul li a[href*='P_PASS']").addClass("active");
    
    }

    else if (param == "P_TXNLog_list") {
      
      $("header nav ul li a[href*='P_TXNLog_list']").addClass("active");
    
    }

    else if (param == "P_CLR") {
      
      $("header nav ul li a[href*='P_CLR']").addClass("active");
    
    }

    else if (param == "P_CERT") {
      
      $("header nav ul li a[href*='P_CERT']").addClass("active");
    
    }

    else if (param == "P_REGOS") {
      
      $("header nav ul li a[href*='P_REGOS']").addClass("active");
    
    }

    else if (param == "P_DOCS") {
      
      $("header nav ul li a[href*='P_DOCS']").addClass("active");
    
    }

    else if (param == "C_TXNLog_list") {
      
      $("header nav ul li a[href*='C_TXNLog_list']").addClass("active");
    
    }

    else if (param == "C_DOCS") {
      
      $("header nav ul li a[href*='C_DOCS']").addClass("active");
    
    }

    else {

      $("header nav ul li a[href*='E_HOME']").addClass("active");

    }

});
