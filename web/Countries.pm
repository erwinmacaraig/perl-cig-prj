package Countries;
require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(getISOCountriesHash getISOCountriesArray isEuropean);
#@EXPORT = qw(getISOCountriesHash getCountriesHash getCountriesArray getISOCountriesArray );
@EXPORT_OK = qw(getISOCountriesHash getISOCountriesArray getCountriesNameToData isEuropean);
#@EXPORT_OK = qw(getISOCountriesHash getCountriesHash getCountriesArray getISOCountriesArray getCountriesNameToData );

    my $noCountryDisclosedID = 20000;

	my %countries	=	(
# ISO Number, Name, 3 Letter Code, 2 Letter Code, 1 = Former Country
4   => ['Afghanistan','AFG','AF',  0   ],
248 => ['Åland Islands','ALA','AX',  0   ],
8   => ['Albania','ALB','AL',  0   ],
12  => ['Algeria','DZA','DZ',  0   ],
16  => ['American Samoa','ASM','AS',  0   ],
20  => ['Andorra','AND','AD',  0   ],
24  => ['Angola','AGO','AO',  0   ],
660 => ['Anguilla','AIA','AI',  0   ],
10  => ['Antarctica','ATA','AQ',  0   ],
28  => ['Antigua and Barbuda','ATG','AG',  0   ],
32  => ['Argentina','ARG','AR',  0   ],
51  => ['Armenia','ARM','AM',  0   ],
533 => ['Aruba','ABW','AW',  0   ],
36  => ['Australia','AUS','AU',  0   ],
40  => ['Austria','AUT','AT',  0   ],
31  => ['Azerbaijan','AZE','AZ',  0   ],
44  => ['Bahamas','BHS','BS',  0   ],
48  => ['Bahrain','BHR','BH',  0   ],
50  => ['Bangladesh','BGD','BD',  0   ],
52  => ['Barbados','BRB','BB',  0   ],
112 => ['Belarus','BLR','BY',  0   ],
56  => ['Belgium','BEL','BE',  0   ],
84  => ['Belize','BLZ','BZ',  0   ],
204 => ['Benin','BEN','BJ',  0   ],
60  => ['Bermuda','BMU','BM',  0   ],
64  => ['Bhutan','BTN','BT',  0   ],
68  => ['Bolivia, Plurinational State of','BOL','BO',  0   ],
535 => ['Bonaire, Sint Eustatius and Saba','BES','BQ',  0   ],
70  => ['Bosnia and Herzegovina','BIH','BA',  0   ],
72  => ['Botswana','BWA','BW',  0   ],
74  => ['Bouvet Island','BVT','BV',  0   ],
76  => ['Brazil','BRA','BR',  0   ],
86  => ['British Indian Ocean Territory','IOT','IO',  0   ],
96  => ['Brunei Darussalam','BRN','BN',  0   ],
100 => ['Bulgaria','BGR','BG',  0   ],
854 => ['Burkina Faso','BFA','BF',  0   ],
108 => ['Burundi','BDI','BI',  0   ],
116 => ['Cambodia','KHM','KH',  0   ],
120 => ['Cameroon','CMR','CM',  0   ],
124 => ['Canada','CAN','CA',  0   ],
132 => ['Cabo Verde','CPV','CV',  0   ],
136 => ['Cayman Islands','CYM','KY',  0   ],
140 => ['Central African Republic','CAF','CF',  0   ],
148 => ['Chad','TCD','TD',  0   ],
152 => ['Chile','CHL','CL',  0   ],
156 => ['China','CHN','CN',  0   ],
162 => ['Christmas Island','CXR','CX',  0   ],
166 => ['Cocos (Keeling) Islands','CCK','CC',  0   ],
170 => ['Colombia','COL','CO',  0   ],
174 => ['Comoros','COM','KM',  0   ],
178 => ['Congo','COG','CG',  0   ],
180 => ['Congo, the Democratic Republic of the','COD','CD',  0   ],
184 => ['Cook Islands','COK','CK',  0   ],
188 => ['Costa Rica','CRI','CR',  0   ],
384 => ["Côte d'Ivoire",'CIV','CI',  0   ],
191 => ['Croatia','HRV','HR',  0   ],
192 => ['Cuba','CUB','CU',  0   ],
531 => ['Curaçao','CUW','CW',  0   ],
196 => ['Cyprus','CYP','CY',  0   ],
203 => ['Czech Republic','CZE','CZ',  0   ],
208 => ['Denmark','DNK','DK',  0   ],
262 => ['Djibouti','DJI','DJ',  0   ],
212 => ['Dominica','DMA','DM',  0   ],
214 => ['Dominican Republic','DOM','DO',  0   ],
218 => ['Ecuador','ECU','EC',  0   ],
818 => ['Egypt','EGY','EG',  0   ],
222 => ['El Salvador','SLV','SV',  0   ],
226 => ['Equatorial Guinea','GNQ','GQ',  0   ],
232 => ['Eritrea','ERI','ER',  0   ],
233 => ['Estonia','EST','EE',  0   ],
231 => ['Ethiopia','ETH','ET',  0   ],
238 => ['Falkland Islands (Malvinas)','FLK','FK',  0   ],
234 => ['Faroe Islands','FRO','FO',  0   ],
242 => ['Fiji','FJI','FJ',  0   ],
246 => ['Finland','FIN','FI',  0   ],
250 => ['France','FRA','FR',  0   ],
254 => ['French Guiana','GUF','GF',  0   ],
258 => ['French Polynesia','PYF','PF',  0   ],
260 => ['French Southern Territories','ATF','TF',  0   ],
266 => ['Gabon','GAB','GA',  0   ],
270 => ['Gambia','GMB','GM',  0   ],
268 => ['Georgia','GEO','GE',  0   ],
276 => ['Germany','DEU','DE',  0   ],
288 => ['Ghana','GHA','GH',  0   ],
292 => ['Gibraltar','GIB','GI',  0   ],
300 => ['Greece','GRC','GR',  0   ],
304 => ['Greenland','GRL','GL',  0   ],
308 => ['Grenada','GRD','GD',  0   ],
312 => ['Guadeloupe','GLP','GP',  0   ],
316 => ['Guam','GUM','GU',  0   ],
320 => ['Guatemala','GTM','GT',  0   ],
831 => ['Guernsey','GGY','GG',  0   ],
324 => ['Guinea','GIN','GN',  0   ],
624 => ['Guinea-Bissau','GNB','GW',  0   ],
328 => ['Guyana','GUY','GY',  0   ],
332 => ['Haiti','HTI','HT',  0   ],
334 => ['Heard Island and McDonald Islands','HMD','HM',  0   ],
336 => ['Holy See (Vatican City State)','VAT','VA',  0   ],
340 => ['Honduras','HND','HN',  0   ],
344 => ['Hong Kong','HKG','HK',  0   ],
348 => ['Hungary','HUN','HU',  0   ],
352 => ['Iceland','ISL','IS',  0   ],
356 => ['India','IND','IN',  0   ],
360 => ['Indonesia','IDN','ID',  0   ],
364 => ['Iran, Islamic Republic of','IRN','IR',  0   ],
368 => ['Iraq','IRQ','IQ',  0   ],
372 => ['Ireland','IRL','IE',  0   ],
833 => ['Isle of Man','IMN','IM',  0   ],
376 => ['Israel','ISR','IL',  0   ],
380 => ['Italy','ITA','IT',  0   ],
388 => ['Jamaica','JAM','JM',  0   ],
392 => ['Japan','JPN','JP',  0   ],
832 => ['Jersey','JEY','JE',  0   ],
400 => ['Jordan','JOR','JO',  0   ],
398 => ['Kazakhstan','KAZ','KZ',  0   ],
404 => ['Kenya','KEN','KE',  0   ],
296 => ['Kiribati','KIR','KI',  0   ],
408 => ["Korea, Democratic People's Republic of",'PRK','KP',  0   ],
410 => ['Korea, Republic of','KOR','KR',  0   ],
414 => ['Kuwait','KWT','KW',  0   ],
417 => ['Kyrgyzstan','KGZ','KG',  0   ],
418 => ["Lao People's Democratic Republic",'LAO','LA',  0   ],
428 => ['Latvia','LVA','LV',  0   ],
422 => ['Lebanon','LBN','LB',  0   ],
426 => ['Lesotho','LSO','LS',  0   ],
430 => ['Liberia','LBR','LR',  0   ],
434 => ['Libya','LBY','LY',  0   ],
438 => ['Liechtenstein','LIE','LI',  0   ],
440 => ['Lithuania','LTU','LT',  0   ],
442 => ['Luxembourg','LUX','LU',  0   ],
446 => ['Macao','MAC','MO',  0   ],
807 => ['Macedonia, the former Yugoslav Republic of','MKD','MK',  0   ],
450 => ['Madagascar','MDG','MG',  0   ],
454 => ['Malawi','MWI','MW',  0   ],
458 => ['Malaysia','MYS','MY',  0   ],
462 => ['Maldives','MDV','MV',  0   ],
466 => ['Mali','MLI','ML',  0   ],
470 => ['Malta','MLT','MT',  0   ],
584 => ['Marshall Islands','MHL','MH',  0   ],
474 => ['Martinique','MTQ','MQ',  0   ],
478 => ['Mauritania','MRT','MR',  0   ],
480 => ['Mauritius','MUS','MU',  0   ],
175 => ['Mayotte','MYT','YT',  0   ],
484 => ['Mexico','MEX','MX',  0   ],
583 => ['Micronesia, Federated States of','FSM','FM',  0   ],
498 => ['Moldova, Republic of','MDA','MD',  0   ],
492 => ['Monaco','MCO','MC',  0   ],
496 => ['Mongolia','MNG','MN',  0   ],
499 => ['Montenegro','MNE','ME',  0   ],
500 => ['Montserrat','MSR','MS',  0   ],
504 => ['Morocco','MAR','MA',  0   ],
508 => ['Mozambique','MOZ','MZ',  0   ],
104 => ['Myanmar','MMR','MM',  0   ],
516 => ['Namibia','NAM','NA',  0   ],
520 => ['Nauru','NRU','NR',  0   ],
524 => ['Nepal','NPL','NP',  0   ],
528 => ['Netherlands','NLD','NL',  0   ],
540 => ['New Caledonia','NCL','NC',  0   ],
554 => ['New Zealand','NZL','NZ',  0   ],
558 => ['Nicaragua','NIC','NI',  0   ],
562 => ['Niger','NER','NE',  0   ],
566 => ['Nigeria','NGA','NG',  0   ],
570 => ['Niue','NIU','NU',  0   ],
574 => ['Norfolk Island','NFK','NF',  0   ],
580 => ['Northern Mariana Islands','MNP','MP',  0   ],
578 => ['Norway','NOR','NO',  0   ],
512 => ['Oman','OMN','OM',  0   ],
586 => ['Pakistan','PAK','PK',  0   ],
585 => ['Palau','PLW','PW',  0   ],
275 => ['Palestine, State of','PSE','PS',  0   ],
591 => ['Panama','PAN','PA',  0   ],
598 => ['Papua New Guinea','PNG','PG',  0   ],
600 => ['Paraguay','PRY','PY',  0   ],
604 => ['Peru','PER','PE',  0   ],
608 => ['Philippines','PHL','PH',  0   ],
612 => ['Pitcairn','PCN','PN',  0   ],
616 => ['Poland','POL','PL',  0   ],
620 => ['Portugal','PRT','PT',  0   ],
630 => ['Puerto Rico','PRI','PR',  0   ],
634 => ['Qatar','QAT','QA',  0   ],
638 => ['Réunion','REU','RE',  0   ],
642 => ['Romania','ROU','RO',  0   ],
643 => ['Russian Federation','RUS','RU',  0   ],
646 => ['Rwanda','RWA','RW',  0   ],
652 => ['Saint Barthélemy','BLM','BL',  0   ],
654 => ['Saint Helena, Ascension and Tristan da Cunha','SHN','SH',  0   ],
659 => ['Saint Kitts and Nevis','KNA','KN',  0   ],
662 => ['Saint Lucia','LCA','LC',  0   ],
663 => ['Saint Martin (French part)','MAF','MF',  0   ],
666 => ['Saint Pierre and Miquelon','SPM','PM',  0   ],
670 => ['Saint Vincent and the Grenadines','VCT','VC',  0   ],
882 => ['Samoa','WSM','WS',  0   ],
674 => ['San Marino','SMR','SM',  0   ],
678 => ['Sao Tome and Principe','STP','ST',  0   ],
682 => ['Saudi Arabia','SAU','SA',  0   ],
686 => ['Senegal','SEN','SN',  0   ],
688 => ['Serbia','SRB','RS',  0   ],
690 => ['Seychelles','SYC','SC',  0   ],
694 => ['Sierra Leone','SLE','SL',  0   ],
702 => ['Singapore','SGP','SG',  0   ],
534 => ['Sint Maarten (Dutch part)','SXM','SX',  0   ],
703 => ['Slovakia','SVK','SK',  0   ],
705 => ['Slovenia','SVN','SI',  0   ],
90  => ['Solomon Islands','SLB','SB',  0   ],
706 => ['Somalia','SOM','SO',  0   ],
710 => ['South Africa','ZAF','ZA',  0   ],
239 => ['South Georgia and the South Sandwich Islands','SGS','GS',  0   ],
728 => ['South Sudan','SSD','SS',  0   ],
724 => ['Spain','ESP','ES',  0   ],
144 => ['Sri Lanka','LKA','LK',  0   ],
729 => ['Sudan','SDN','SD',  0   ],
740 => ['Suriname','SUR','SR',  0   ],
744 => ['Svalbard and Jan Mayen','SJM','SJ',  0   ],
748 => ['Swaziland','SWZ','SZ',  0   ],
752 => ['Sweden','SWE','SE',  0   ],
756 => ['Switzerland','CHE','CH',  0   ],
760 => ['Syrian Arab Republic','SYR','SY',  0   ],
158 => ['Taiwan, Province of China','TWN','TW',  0   ],
762 => ['Tajikistan','TJK','TJ',  0   ],
834 => ['Tanzania, United Republic of','TZA','TZ',  0   ],
764 => ['Thailand','THA','TH',  0   ],
626 => ['Timor-Leste','TLS','TL',  0   ],
768 => ['Togo','TGO','TG',  0   ],
772 => ['Tokelau','TKL','TK',  0   ],
776 => ['Tonga','TON','TO',  0   ],
780 => ['Trinidad and Tobago','TTO','TT',  0   ],
788 => ['Tunisia','TUN','TN',  0   ],
792 => ['Turkey','TUR','TR',  0   ],
795 => ['Turkmenistan','TKM','TM',  0   ],
796 => ['Turks and Caicos Islands','TCA','TC',  0   ],
798 => ['Tuvalu','TUV','TV',  0   ],
800 => ['Uganda','UGA','UG',  0   ],
804 => ['Ukraine','UKR','UA',  0   ],
784 => ['United Arab Emirates','ARE','AE',  0   ],
826 => ['United Kingdom','GBR','GB',  0   ],
840 => ['United States','USA','US',  0   ],
581 => ['United States Minor Outlying Islands','UMI','UM',  0   ],
858 => ['Uruguay','URY','UY',  0   ],
860 => ['Uzbekistan','UZB','UZ',  0   ],
548 => ['Vanuatu','VUT','VU',  0   ],
862 => ['Venezuela, Bolivarian Republic of','VEN','VE',  0   ],
704 => ['Viet Nam','VNM','VN',  0   ],
92  => ['Virgin Islands, British','VGB','VG',  0   ],
850 => ['Virgin Islands, U.S.','VIR','VI',  0   ],
876 => ['Wallis and Futuna','WLF','WF',  0   ],
732 => ['Western Sahara','ESH','EH',  0   ],
887 => ['Yemen','YEM','YE',  0   ],
894 => ['Zambia','ZMB','ZM',  0   ],
716 => ['Zimbabwe','ZWE','ZW',  0   ],
# Former Countries 
10000   => ['British Antarctic Territory','BQAQ','BQAQ',  1   ],
10001   => ['Burma','BUMM','BUMM',  1   ],
10002   => ['Byelorussian SSR','BYAA','BYAA',  1   ],
10003   => ['Canton and Enderbury Islands','CTKI','CTKI',  1   ],
10004   => ['Czechoslovakia','CSHH','CSHH',  1   ],
10005   => ['Dahomey','DYBJ','DYBJ',  1   ],
10006   => ['Dronning Maud Land','NQAQ','NQAQ',  1   ],
10007   => ['East Timor [note 1]','TPTL','TPTL',  1   ],
10008   => ['France, Metropolitan','FXFR','FXFR',  1   ],
10009   => ['French Afar and Issas','AIDJ','AIDJ',  1   ],
10010   => ['French Southern and Antarctic Territories','FQHH','FQHH',  1   ],
10011   => ['German Democratic Republic','DDDE','DDDE',  1   ],
10012   => ['Gilbert and Ellice Islands','GEHH','GEHH',  1   ],
10013   => ['Johnston Island','JTUM','JTUM',  1   ],
10014   => ['Midway Islands','MIUM','MIUM',  1   ],
10015   => ['Netherlands Antilles','ANHH','ANHH',  1   ],
10016   => ['Neutral Zone','NTHH','NTHH',  1   ],
10017   => ['New Hebrides','NHVU','NHVU',  1   ],
10018   => ['Pacific Islands, Trust Territory of the','PCHH','PCHH',  1   ],
10019   => ['Panama Canal Zone','PZPA','PZPA',  1   ],
10020   => ['Serbia and Montenegro','CSXX','CSXX',  1   ],
10021   => ['Sikkim','SKIN','SKIN',  1   ],
10022   => ['Southern Rhodesia','RHZW','RHZW',  1   ],
10023   => ['Upper Volta','HVBF','HVBF',  1   ],
10024   => ['U.S. Miscellaneous Pacific Islands','PUUM','PUUM',  1   ],
10025   => ['USSR','SUHH','SUHH',  1   ],
10026   => ['Viet-Nam, Democratic Republic of','VDVN','VDVN',  1   ],
10027   => ['Wake Island','WKUM','WKUM',  1   ],
10028   => ['Yemen, Democratic','YDYE','YDYE',  1   ],
10029   => ['Yugoslavia','YUCS','YUCS',  1   ],
10030   => ['Zaire','ZRCD','ZRCD',  1   ],


	);

    my %euroCountries = (
        'AT' => 1, #Austria (also sometimes OE in German-speaking countries: for "Oesterreich"
        'BE' => 1, #Belgium
        'BG' => 1, #Bulgaria
        'HR' => 1, #Croatia (local name: Hrvatska)
        'CY' => 1, #Cyprus
        'CZ' => 1, #Czech Republic
        'DK' => 1, #Denmark
        'EE' => 1, #Estonia
        'FI' => 1, #Finland
        'FR' => 1, #France
        'DE' => 1, #Germany
        'GR' => 1, #Greece
        'HU' => 1, #Hungary
        'IS' => 1, #Iceland
        'IE' => 1, #Ireland
        'IT' => 1, #Italy
        'LV' => 1, #Latvia
        'LT' => 1, #Lithuania
        'LU' => 1, #Luxembourg
        'MT' => 1, #Malta
        'NL' => 1, #Netherlands
        'NO' => 1, #Norway
        'PO' => 1, #Poland
        'PT' => 1, #Portugal
        'RO' => 1, #Romania
        'SK' => 1, #Slovakia (Slovakian Republic)
        'SI' => 1, #Slovenia
        'ES' => 1, #Spain
        'SE' => 1, #Sweden
        'CH' => 1, #Switzerland (from Confoederatio Helvetica)
        'GB' => 1, #United Kingdom (of Great Britain and Northern Ireland)
    );

#sub getCountriesHash	{
    #my ($Data) =@_;
	#my %cnames=();
	#for my $key (keys %countries)	{ $cnames{$key}=$countries{$key}[0]; }
    #if(defined $Data and $Data->{'SystemConfig'}{'AllowNoCountrySelection'} ) {
        #delete $cname->{$noCountryDisclosedID};        
    #}
	#return \%cnames;
#}

sub getCountriesNameToData {
    my ($Data) =@_;
	my %cnames=();
	for my $key (keys %countries)	{ $cnames{uc($countries{$key}[0])}=[ $countries{$key}[1], $countries{$key}[2],$key]; }
    if( defined $Data and $Data->{'SystemConfig'}{'AllowNoCountrySelection'} ) {
        #delete $cname->{$noCountryDisclosedID};
    }
	return \%cnames;
}

sub getISOCountriesArray	{
    my ($Data) =@_;
	my @countries=();
    my $force_select_country = 0;
    if(defined $Data and $Data->{'SystemConfig'}{'AllowNoCountrySelection'}) {
        $force_select_country = 1;
    }
	for my $key (sort { $countries{$a}[1] cmp $countries{$b}[1]} keys %countries)	{
        #if system config is set for AllowNoCountrySelection then we need to display option " Do not wish to enclose"
		push @countries, $countries{$key}[1] unless(!$force_select_country and $key == $noCountryDisclosedID );
	}
	return @countries;
}
#sub getCountriesArray	{
    #my ($Data) =@_;
	#my @countries=();
    #my $force_select_country = 0;
    #if(defined $Data and $Data->{'SystemConfig'}{'AllowNoCountrySelection'}) {
        #$force_select_country = 1;
    #}
	#for my $key (sort { $countries{$a}[0] cmp $countries{$b}[0]} keys %countries)	{
        ##if system config is set for AllowNoCountrySelection then we need to display option " Do not wish to enclose"
		#push @countries, $countries{$key}[0] unless(!$force_select_country and $key == $noCountryDisclosedID );
	#}
	#return @countries;
#}

sub isEuropean {
    my ($countryCode) = @_;
    return $euroCountries{$countryCode} || 0;
}

sub getISOCountriesHash	{
    my (%params) = @_;
    my %cnames=();
	for my $key (keys %countries)	{ 
		if($countries{$key}[3] ){
            next if !$params{'historicalCountries'};
        }
        $cnames{$countries{$key}[2]}=$countries{$key}[0]; 
	}
	return \%cnames;
}

1;
