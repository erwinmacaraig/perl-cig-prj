package PageMain;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(pageMain printReport pageForm regoPageForm printBasePage ccPageForm getHomeClient getPageCustomization);
@EXPORT_OK = qw(pageMain printReport pageForm regoPageForm printBasePage ccPageForm getHomeClient getPageCustomization);

use strict;
use DBI;

use lib '.', '..';
use Reg_common;
use Defs;
use Utils;
use CGI;
use AddToPage;
use TTTemplate;
use Log;
use Data::Dumper;
use LanguageChooser;
use HelpLink;;

sub ccPageForm  {
    my($title, $body, $clientValues_ref,$client, $Data) = @_;
    $title ||= '';
    $body ||= textMessage("Oops !<br> This shouldn't be happening!<br> Please contact <a href=\"mailto:info\@sportingpulse.com\">info\@sportingpulse.com</a>");

    if($Data->{'WriteCookies'}) {
        my $cookies_string = '';
        my @cookie_array = ();
        my $output = new CGI;
        for my $i (@{$Data->{'WriteCookies'}}) {
                push @cookie_array, $output->cookie(
                        -name=>$i->[0],
                        -value=>$i->[1],
                        -domain=>$Defs::cookie_domain,
                        -secure=>0,
                        -expires=> $i->[2] || '',
                        -path=>"/"
                );
                $cookies_string = join(',', @cookie_array);
        }

        print $output->header(-cookie=>[$cookies_string]); # -charset=>'UTF-8');
    } else {
        print "Content-type: text/html\n\n";
    }

    my ($html_head, $page_header, $page_navigator, $paypal, $powered) = getPageCustomization($Data);
                #Payments
    $paypal = qq[<div id="spfooter"> <img width="870" height="55" border="0" src="images/payment_footer.jpg"> </div>];

    my $meta = {};
    $meta->{'title'} = $title;
    $meta->{'head'} = qq[
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
                $html_head
        <script type="text/javascript" src="//ajax.aspnetcdn.com/ajax/jquery.validate/1.8.1/jquery.validate.min.js"></script>
        
        <script type="text/javascript">
            jQuery().ready(function () {
                // validate the comment form when it is submitted
                jQuery("#cc-form").validate({
                    rules: {
                        EPS_CCV: "required",
                        EPS_CARDTYPE: "required",
                        EPS_EXPIRYMONTH: "required",
                        EPS_EXPIRYYEAR: "required",
                        EPS_CARDNUMBER: {
                            required: true,
                            creditcard: true
                        }
                    },
                    messages: {
                        EPS_CARDTYPE: {
                            required: "Card Type required"
                        },
                        EPS_CCV: {
                            required: "CCV required"
                        },
                        EPS_EXPIRYMONTH: {
                            required: ""
                        },
                        EPS_EXPIRYYEAR: {
                            required: "Expiry required"
                        },
                        EPS_CARDNUMBER: {
                            required: "Credit Card Number required",
                            minlength: "Your credit card number must be 16 digits",
                            maxlength: "Your credit card number must be 16 digits",
                            number: "Your credit card number must be digits only"
                        }
                    },
                    submitHandler: function (form) {
                        jQuery("#cc-form").hide();
                        jQuery(".spinner-wrap").show();
                        form.submit();
                    }
                });
            });
        </script>
    ];
    $meta->{'page_begin'} = qq[
    ];
    $meta->{'page_header'} = $page_header;
    $meta->{'page_content'} = $body;
    $meta->{'page_footer'} = qq [
        $powered
    ];

    print runTemplate($Data, $meta, 'main.templ');
}

sub pageMain {
    my(
        $title, 
        $navbar, 
        $body, 
        $clientValues_ref,
        $client, 
        $Data
    ) = @_;

    $title ||= '';
    $navbar||='';
    $body ||= textMessage($Data->{'lang'}->txt('NO_BODY'));


    $Data->{'AddToPage'} ||= new AddToPage;
    if($Data->{'SystemConfig'}{'HeaderBG'})    {
        $Data->{'AddToPage'}->add( 
            'css',
            'inline',
            $Data->{'SystemConfig'}{'HeaderBG'},
        );
    }
    $Data->{'TagManager'}=''; #getTagManager($Data);
    $Data->{'AddToPage'}->add(
    'js_bottom',
    'inline',
    $Data->{'TagManager'},
    );
    $Data->{'AddToPage'}->add(
        'js_bottom',
        'inline',
        'jQuery(".chzn-select").chosen({ disable_search_threshold: 32 });',
    );

    $Data->{'AddToPage'}->add(
        'js_bottom',
        'inline',
        'jQuery(".fcToggleGroup").fcToggle({ test:1 });',
    );
    my $search_js = qq[
    jQuery.widget( "custom.catcomplete", jQuery.ui.autocomplete, {
        _renderMenu: function( ul, items ) {
            var self = this,
                currentCategory = "";
            var lastnumnotshown = 0;
            jQuery.each( items, function( index, item ) {
                if ( item.category != currentCategory ) {
                    if(lastnumnotshown)    {
                        ul.append( "<li class='ui-autocomplete-notshown'>" + lastnumnotshown + " items not shown</li>" );
                    }
                    ul.append( "<li class='ui-autocomplete-category'>" + item.category + "</li>" );
                    currentCategory = item.category;
                }
                lastnumnotshown = item.numnotshown;
                self._renderItem( ul, item );
            });
            if(lastnumnotshown)    {
                ul.append( "<li class='ui-autocomplete-notshown'>" + lastnumnotshown + " items not shown</li>" );
            }
        }
    });
        jQuery( "#search" ).catcomplete({
            delay: 0,
            source: 'ajax/aj_search.cgi?client=$client',
            position : {my : "right top", at : "right bottom"},
            select: function( event, ui ) {
                document.location = ui.item.link;
            }
        });

        jQuery("#fullscreen-btn").click(function() {
            SetCookie('SP_SWM_FULLSCREEN',].(!($Data->{'FullScreen'} || 0) || 0).qq[,30);
            document.location.reload();
        });
    ];
    $Data->{'AddToPage'}->add('js_bottom','file','js/jscookie.js');
    $Data->{'AddToPage'}->add('js_bottom','file','js/bootstrap-tabcollapse/bootstrap-tabcollapse.js');
    $Data->{'AddToPage'}->add(
        'js_bottom',
        'inline',
        "jQuery('.nav.nav-tabs').tabCollapse({
            tabsClass: 'hidden-xs',
            accordionClass: 'visible-xs autoAccordian'
        })",

    );

   if($Defs::DisableResponsiveLayout)    {
        #$Data->{'AddToPage'}->add( 
            #'css',
            #'file',
            #'css/noresponsive.css',
        #);
    }
 
    my $helpURL=$Data->{'SystemConfig'}{'HELP'} 
        ? "$Data->{'target'}?client=$client&amp;a=HELP"
        : $Defs::helpurl;
    my $homeClient = getHomeClient($Data);
        
    my $statscounter = $Defs::NoStats ? '' : getStatsCounterCode();

    my %HomeAction = (
        $Defs::LEVEL_INTERNATIONAL =>  'E_HOME',
        $Defs::LEVEL_INTREGION =>  'E_HOME',
        $Defs::LEVEL_INTZONE =>  'E_HOME',
        $Defs::LEVEL_NATIONAL =>  'E_HOME',
        $Defs::LEVEL_STATE =>  'E_HOME',
        $Defs::LEVEL_REGION =>  'E_HOME',
        $Defs::LEVEL_ZONE =>  'E_HOME',
        $Defs::LEVEL_CLUB =>  'C_HOME',
        $Defs::LEVEL_PERSON =>  'P_HOME',
    );

    my ($navTree, $navObjects) = Navbar::GenerateTree($Data, $clientValues_ref);

    my $atloginlevel = 1;
    my $currentLevel = $clientValues_ref->{'currentLevel'} || 0;
    my $authLevel = $clientValues_ref->{'authLevel'} || 0;
    if($currentLevel != $authLevel) {
        my $cID = getID($clientValues_ref,$Defs::LEVEL_CLUB);
        $cID = 0 if $cID < 0;
        my $rID = getID($clientValues_ref,$Defs::LEVEL_REGION);
        $rID = 0 if $rID < 0;
        if(
            $cID
            and (
                $authLevel == $Defs::LEVEL_NATIONAL
                or $authLevel == $Defs::LEVEL_REGION
            )   
        )   {
                $atloginlevel = 0;
        }
        if(
            $rID
            and $authLevel == $Defs::LEVEL_NATIONAL
        )   {
                $atloginlevel = 0;
        }
    }

    my %NavData= (
        NavTree => $navTree,
        Menu => '',
        HomeURL => "$Data->{'target'}?client=$homeClient&amp;a=".$HomeAction{$Data->{'clientValues'}{'authLevel'}},
        AtLoginLevel => $atloginlevel,
        LanguageChooser => genLanguageChooser($Data),
        HeaderLogo => $Data->{'SystemConfig'}{'MA_logo'},
        HeaderSystemName => $Data->{'SystemConfig'}{'HeaderSystemName'},
        HelpLink => retrieveHelpLink($Data),
    );

  my $globalnav = runTemplate(
    $Data,
    #{PassportLink => ''},
    \%NavData,
    'user/globalnav.templ',
  );

    $navbar = '' if $Data->{'ClearNavBar'};

    my %TemplateData = (
        HelpURL => $helpURL,
        NoSPLogo => $Data->{'SystemConfig'}{'NoSPLogo'} || 0,
        BlogURL => 'http://blog.sportingpulse.com',
        HomeURL => "$Data->{'target'}?client=$homeClient&amp;a=HOME",
        StatsCounter =>  $statscounter || '',
        Content => $body || '',
        Title => $title || '',
        MemListName => uc($Data->{'lang'}->txt('Persons')),
        ClubListName => uc($Data->{'lang'}->txt('Clubs')),
        GlobalNav => $globalnav || '',
        Header => $Data->{'SystemConfig'}{'Header'} || '',
        NavBar => $navbar || '',
        CSSFiles => $Data->{'AddToPage'}->get('css','file') || '',
        CSSInline => $Data->{'AddToPage'}->get('css','inline') || '',
        TopJSFiles => $Data->{'AddToPage'}->get('js_top','file') || '',
        TopJSInline => $Data->{'AddToPage'}->get('js_top','inline') || '',
        BottomJSFiles => $Data->{'AddToPage'}->get('js_bottom','file') || '',
        BottomJSInline => $Data->{'AddToPage'}->get('js_bottom','inline') || '',
        DisableResponsiveLayout => $Defs::DisableResponsiveLayout || 0,
        HeaderLogo => $Data->{'SystemConfig'}{'MA_logo'},
        HeaderSystemName => $Data->{'SystemConfig'}{'HeaderSystemName'},
        NavTree => $navTree,
        LanguageChooser => genLanguageChooser($Data,2),
        #FullScreen => $Data->{'FullScreen'} || 0,
    );

    $authLevel = $clientValues_ref->{'authLevel'} || 0;
    #if($authLevel == $Defs::LEVEL_ASSOC)    {
        #$TemplateData{'MemListURL'} = "$Data->{'target'}?client=$homeClient&amp;a=M_L&amp;l=1";
        #$TemplateData{'CompListURL'} = "$Data->{'target'}?client=$homeClient&amp;a=CO_L&amp;l=4" if(!$Data->{'SystemConfig'}{'NoComps'});
        #$TemplateData{'ClubListURL'} = "$Data->{'target'}?client=$homeClient&amp;a=C_L&amp;l=3" if($Data->{'Permissions'}{'OtherOptions'}{'ShowClubs'} or !$Data->{'SystemConfig'}{'NoClubs'});
        #$TemplateData{'TeamListURL'} = "$Data->{'target'}?client=$homeClient&amp;a=T_L&amp;l=2" if(!$Data->{'SystemConfig'}{'NoTeams'});
    #}
    if($authLevel == $Defs::LEVEL_CLUB)    {
        #$TemplateData{'MemListURL'} = "$Data->{'target'}?client=$homeClient&amp;a=M_L&amp;l=1";
        #$TemplateData{'TeamListURL'} = "$Data->{'target'}?client=$homeClient&amp;a=T_L&amp;l=2" if(!$Data->{'SystemConfig'}{'NoTeams'});
    }

    my $templateFile = 'page_wrapper/main_wrapper.templ';
    my $page = runTemplate(
        $Data, 
        \%TemplateData, 
        $templateFile
    );
    my $header = '';
    my $output = new CGI;
    if($Data->{'WriteCookies'})    {
        my $cookies_string = '';
        my @cookie_array = ();
        for my $i (@{$Data->{'WriteCookies'}})    {
            push @cookie_array, $output->cookie(
                -name=>$i->[0], 
                -value=>$i->[1], 
                -domain=>$Defs::cookie_domain, 
                -secure=>0, 
                -expires=> $i->[2] || '',
                -path=>"/"
            );
            $cookies_string = join(',', @cookie_array);
        }
        my $p3p=q[policyref="/w3c/p3p.xml", CP="ALL DSP COR CURa ADMa DEVa TAIi PSAa PSDa IVAi IVDi CONi OTPi OUR BUS IND PHY ONL UNI COM NAV DEM STA"];

        if($Data->{'RedirectTo'})   {
            $header = $output->redirect (-uri => $Data->{'RedirectTo'},-cookie=>[$cookies_string], -P3P => $p3p);
        }
        else    {
            $header = $output->header(-cookie=>[$cookies_string], -P3P => $p3p, -charset=>'UTF-8');
        }
    }
    elsif($Data->{'RedirectTo'})    {
        $header = $output->redirect ($Data->{'RedirectTo'});
    }
    else    {
        $header = "Content-type: text/html\n\n";
    }
    print $header;
    print $page;
}

sub printReport    {

    my($body, $lang) = @_;

        my $title=$lang->txt('Reports');
    print qq[Content-type: text/html\n\n];
    print qq[
  <html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
      <title>$title</title>
            <link rel="stylesheet" type="text/css" href="$Defs::base_url/css/style.css">
    </head>
    <body class="report">
      $body
    </body>
  </html>
    ];
}

sub printBasePage {

    my($body, $title, $Data) = @_;

    print qq[Content-type: text/html\n\n];
    $Data->{'AddToPage'} ||= new AddToPage;
    my $CSSFiles = $Data->{'AddToPage'}->get('css','file') || '';
    my $CSSInline = $Data->{'AddToPage'}->get('css','inline') || '';
    my $TopJSFiles = $Data->{'AddToPage'}->get('js_top','file') || '';
    my $TopJSInline = $Data->{'AddToPage'}->get('js_top','inline') || '';
    my $BottomJSFiles = $Data->{'AddToPage'}->get('js_bottom','file') || '';
    my $BottomJSInline = $Data->{'AddToPage'}->get('js_bottom','inline') || '';
  print qq[
  <html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
      <title>$title</title>
            <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
            <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.21/jquery-ui.min.js"></script>
            <link rel="stylesheet" type="text/css" href="js/jquery-ui/css/theme/jquery-ui-1.8.22.custom.css">
            <script type="text/javascript" src="$Defs::base_url/js/jquery.ui.touch-punch.min.js"></script>
      <link rel="stylesheet" type="text/css" href="$Defs::base_url/css/style.css">
      <link rel="stylesheet" type="text/css" href="$Defs::base_url/css/fc_styles.css">
      <link href="//maxcdn.bootstrapcdn.com/font-awesome/4.2.0/css/font-awesome.min.css" rel="stylesheet" />

      <link rel="stylesheet" type="text/css" href="$Defs::base_url/css/custom.css">

$CSSFiles
$CSSInline
$TopJSFiles
$TopJSInline
    </head>
    <body style = " background:none;">
      $body
$BottomJSFiles
$BottomJSInline
    </body>
  </html>
    ];
}


sub pageForm    {
    my($title, $body, $clientValues_ref,$client, $Data, $templatefile) = @_;
    $title ||= '';
    $templatefile ||= 'main.templ';
    $body||= textMessage("Oops !<br> This shouldn't be happening!<br> Please contact <a href=\"mailto:info\@sportingpulse.com\">info\@sportingpulse.com</a>");
 $Data->{'TagManager'}='';#getTagManager($Data);

    my ($html_head, $page_header, $page_navigator, $paypal, $powered) = getPageCustomization($Data);
    my $meta = {};
    $meta->{'title'} = $title;
    $meta->{'head'} = $html_head;
    $meta->{'page_begin'} = qq[
        $page_navigator
    ];
    $meta->{'page_header'} = $page_header;
    $meta->{'page_content'} = $body;
    $meta->{'page_footer'} = qq [
        $paypal
        $powered
    ];
    $meta->{'page_end'} = qq [
        <script type="text/javascript">
        $Data->{'TagManager'}
        </script>
    ];

    my $output = new CGI;
    my $header = '';
    if($Data->{'WriteCookies'})    {
        my $cookies_string = '';
        my @cookie_array = ();
        for my $i (@{$Data->{'WriteCookies'}})    {
            push @cookie_array, $output->cookie(
                -name=>$i->[0],
                -value=>$i->[1],
                -domain=>$Defs::cookie_domain,
                -secure=>0,
                -expires=> $i->[2] || '',
                -path=>"/"
            );
            $cookies_string = join(',', @cookie_array);
        }
        my $p3p=q[policyref="/w3c/p3p.xml", CP="ALL DSP COR CURa ADMa DEVa TAIi PSAa PSDa IVAi IVDi CONi OTPi OUR BUS IND PHY ONL UNI COM NAV DEM STA"];

        if($Data->{'RedirectTo'})   {
            #$header = $output->redirect (-uri => $Data->{'RedirectTo'},-cookie=>[$cookies_string], -P3P => $p3p);
            $header = $output->redirect (-uri => $Data->{'RedirectTo'},-cookie=>\@cookie_array, -P3P => $p3p);
my $o = new CGI; #Don't know why this and next line are need - but it works
my $h3eader = $o->header();
        }
        else    {
            $header = $output->header(-cookie=>[$cookies_string], -P3P => $p3p, -charset=>'UTF-8');
        }
    }
    elsif($Data->{'RedirectTo'})    {
        $header = $output->redirect ($Data->{'RedirectTo'});
    }
    else    {
        $header = "Content-type: text/html\n\n";
    }
    print $header;
    print runTemplate($Data, $meta, $templatefile);
}

sub regoPageForm {
    my($title, $body, $clientValues_ref, $client, $Data) = @_;

    $title ||= '';
    $body||= textMessage("Oops !<br> This shouldn't be happening!<br> Please contact <a href=\"mailto:info\@sportingpulse.com\">info\@sportingpulse.com</a>");
    $Data->{'TagManager'}=''; #getTagManager($Data);

    if($Data->{'WriteCookies'}) {
        my $cookies_string = '';
        my @cookie_array = ();
        my $output = new CGI;
        for my $i (@{$Data->{'WriteCookies'}}) {
            push @cookie_array, $output->cookie(
                -name=>$i->[0], 
                -value=>$i->[1], 
                -domain=>$Defs::cookie_domain, 
                -secure=>0, 
                -expires=> $i->[2] || '',
                -path=>"/"
            );
            $cookies_string = join(',', @cookie_array);
        }

        if($Data->{'RedirectTo'})   {
            print $output->redirect (-uri => $Data->{'RedirectTo'},-cookie=>[$cookies_string]);
        }
        else    {
            print $output->header(-cookie=>[$cookies_string]); # -charset=>'UTF-8');
            #$header = $output->header(-cookie=>[$cookies_string], -P3P => $p3p, -charset=>'UTF-8');
        }

    } elsif($Data->{'RedirectTo'}) {
        my $output = new CGI;
        print $output->redirect ($Data->{'RedirectTo'});
    } else {
        print "Content-type: text/html\n\n";
    }

    my $globalnav = runTemplate(
      $Data,
      {
        AtLoginLevel => 1,
        HeaderLogo => "$Defs::base_url/$Data->{'SystemConfig'}{'MA_logo'}",
        HeaderSystemName => $Data->{'SystemConfig'}{'HeaderSystemName'},
        DefaultSystemConfig => $Data->{'SystemConfig'},
        LanguageChooser => genLanguageChooser($Data),
        HelpLink => retrieveHelpLink($Data),
      },
      'user/globalnav.templ',
    );
    $Data->{'AddToPage'}->add(
        'js_bottom',
        'inline',
        'jQuery(".fcToggleGroup").fcToggle({ test:1 });',
    );
    $Data->{'AddToPage'}->add(
        'js_bottom',
        'inline',
        'jQuery(".chzn-select").chosen({ disable_search_threshold: 32 });',
    );

    $Data->{'AddToPage'}->add('js_bottom','file',"$Defs::base_url/js/jscookie.js");
    $Data->{'AddToPage'}->add('js_bottom','file',"$Defs::base_url/js/bootstrap-tabcollapse/bootstrap-tabcollapse.js");
    $Data->{'AddToPage'}->add(
        'js_bottom',
        'inline',
        "jQuery('.nav.nav-tabs').tabCollapse({
            tabsClass: 'hidden-xs',
            accordionClass: 'visible-xs autoAccordian'
        })",

    );

    print runTemplate(
        $Data,      
        {
            Content => $body,
            GlobalNav => $globalnav,
            Header => $Data->{'SystemConfig'}{'Header'} || '',
            CSSFiles => $Data->{'AddToPage'}->get('css','file') || '',
            CSSInline => $Data->{'AddToPage'}->get('css','inline') || '',
            TopJSFiles => $Data->{'AddToPage'}->get('js_top','file') || '',
            TopJSInline => $Data->{'AddToPage'}->get('js_top','inline') || '',
            BottomJSFiles => $Data->{'AddToPage'}->get('js_bottom','file') || '',
            BottomJSInline => $Data->{'AddToPage'}->get('js_bottom','inline') || '',
            DisableResponsiveLayout => $Defs::DisableResponsiveLayout || 0,
        },
       'selfrego/wrapper.templ'
    );
}

sub getPageCustomization{
    my ($Data) = @_;

    my $nav = runTemplate(
        $Data,
        {
            PassportLink => '',
            DefaultSystemConfig => $Data->{'SystemConfig'},
            HeaderLogo => "$Defs::base_url/$Data->{'SystemConfig'}{'MA_logo'}",
        },
        'user/globalnav.templ'
    );

    my $html_head = $Data->{'HTMLHead'} || '';
    my $html_head_style = '';
    $html_head_style .= $Data->{'SystemConfig'}{'OtherStyle'} if $Data->{'SystemConfig'}{'OtherStyle'};
    $html_head_style .= $Data->{'SystemConfig'}{'HeaderBG'} if $Data->{'SystemConfig'}{'HeaderBG'};
    $html_head_style = qq[<style type="text/css">$html_head_style</style>] if $html_head_style;

    $html_head = qq[
        $html_head
        $html_head_style
    ];

    my $page_header = qq[<img src="images/sp_membership_web_lrg.png" ></img>];
    $page_header = $Data->{'SystemConfig'}{'Header'} if $Data->{'SystemConfig'}{'Header'};
    $page_header = $Data->{'SystemConfig'}{'AssocConfig'}{'Header'} if $Data->{'SystemConfig'}{'AssocConfig'}{'Header'};

    my $paypal = $Data->{'PAYPAL'} ? qq[<img src="images/PP-CC.jpg" alt="PayPal" border="0"></img>] : '';

    #my $powered = qq[<span class="footerline">].$Data->{'lang'}->txt('COPYRIGHT').qq[</span>];
		my $powered = qq[];

    return ($html_head, $page_header, $nav, $paypal, $powered);
}

sub getHomeClient {

    my ($Data) = @_;


    my %clientValues=%{$Data->{'clientValues'}};
    $clientValues{'currentLevel'} = $clientValues{'authLevel'};
    $clientValues{'currentLevel'} = $clientValues{'authLevel'};

    {
        $clientValues{interID} =0;
        $clientValues{intregID} =0;
        $clientValues{intzonID} =0;
        $clientValues{natID} =0;
        $clientValues{stateID} =0;
        $clientValues{regionID} =0;
        $clientValues{zoneID} =0;
        $clientValues{clubID} =0;
        $clientValues{memberID} =0;
        $clientValues{eventID} =0;
    }
    if ($clientValues{'currentLevel'} == $Defs::LEVEL_INTERNATIONAL)    {
        $clientValues{interID} = $Data->{'clientValues'}{'interID'} || 0;
    }
    if ($clientValues{'currentLevel'} == $Defs::LEVEL_INTREGION)    {
        $clientValues{intregID} = $Data->{'clientValues'}{'intregID'} || 0;
    }
    if ($clientValues{'currentLevel'} == $Defs::LEVEL_INTZONE)    {
        $clientValues{intzonID} = $Data->{'clientValues'}{'intzonID'} || 0;
    }
    if ($clientValues{'currentLevel'} == $Defs::LEVEL_NATIONAL)    {
        $clientValues{natID} = $Data->{'clientValues'}{'natID'} || 0;
    }
    if ($clientValues{'currentLevel'} == $Defs::LEVEL_STATE)    {
        $clientValues{stateID} = $Data->{'clientValues'}{'stateID'} || 0;
    }
    if ($clientValues{'currentLevel'} == $Defs::LEVEL_REGION)    {
        $clientValues{regionID} = $Data->{'clientValues'}{'regionID'} || 0;
    }
    if ($clientValues{'currentLevel'} == $Defs::LEVEL_ZONE)    {
        $clientValues{zoneID} = $Data->{'clientValues'}{'zoneID'} || 0;
    }
    if ($clientValues{'currentLevel'} == $Defs::LEVEL_CLUB)    {
        $clientValues{assocID} = $Data->{'clientValues'}{'assocID'} || 0;
        $clientValues{clubID} = $Data->{'clientValues'}{'clubID'} || 0;
    }
    my $client = setClient(\%clientValues);
    return $client; 
}

sub getStatsCounterCode {
    return q[
    ];    
}

1;
