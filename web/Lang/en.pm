#
# $Header: svn://svn/SWM/trunk/web/Lang/en.pm 10851 2014-03-03 00:01:51Z cregnier $
#

package Lang::en;
use base qw(LangBase);
use strict;
use vars qw(%Lexicon);
%Lexicon = (

    APPNAME => 'SportingPulse Membership',

    AUTO_INTROTEXT => <<"EOS",
To modify this information change the information in the boxes below and when
you have finished press the <strong>'[_1]'</strong> button.<br>
<span class="intro-subtext"><strong>Note:</strong> All boxes marked with a [_2] are compulsory and must be filled in.</span>
EOS

    COPYRIGHT => '&copy;&nbsp; Copyright FOX SPORTS PULSE Pty Ltd & SportingPulse International Pty Ltd &nbsp;2014.&nbsp; All rights reserved.',

    EVENTCOPY_info => <<"EOS",
This option allows the copying of some of the event setup information from
another event to this event.  To proceed please enter the username and
password of the event you wish to copy from and choose what to copy.  When
complete press the '[_1]' button.
EOS

    FIELDS_intro => "Choose the the visibility and editing options for each of the available Member fields.",
    HTMLFORM_INTROTEXT => 'auto',

    PERMISSIONS_intro => <<"EOS",
Choose the options below to set the permissions various users have to perform
tasks in the database. When you have selected the permissions press the
<b>'Update Permissions'</b> button to save your settings. <br>
<b>NB.</b> The permissions only apply to the Members/Club/Teams that the user
has access to already.  It does not convey extra permissions.
EOS

    ROWS_FOUND => '[_1] rows found',
    TO_UPD_DASHBOARD=> '<p>Choose what data you want to display in each dashboard item.</p><p>Click <b>Update</b> to save.</p>',
    TO_UPD_WELCOME => '<p>To update the welcome message to display when you (or any of your clubs/teams) log in, fill in the box and press the <b>[_1]</b> button.</p>',
    WELCOME => q{
        <p>If you experience any problems with SportingPulse Membership or you wish to provide any feedback please contact us at <a href="http://support.sportingpulse.com" target="_support">support.sportingpulse.com</a>.</p>
    },

        REPORT_INTRO_TEXT => <<"EOS",
<p>
  Reports are grouped into different areas depending on the data they report
  on. Choose the type of report you would like to use from the buttons on the
  left.
</p>
EOS

		REPORT_INTRO_DESC_TEXT => q[<p>There are two types of reports present in the system. </p><br><ol><li><b>Quick Reports</b> - Indicated by the 'Run' button, they are predefined and allow you a quick look at your data.<br></li><li><b>Advanced Reports</b> - Indicated by the 'Configure' button, they allow you to define which fields you want to display and add custom filters to your report.<br></li></ol>],
		ADV_REPORT_INTRO => q[
			<p>Choose a field from the left column and drag it into the Selected Fields box (the box will expand to fit your fields).</p><p> Different types of fields are available from different field groupings.  Click the heading to open the group.</p><p>Click the 'Run Report' button to execute the report.</p>
		],


    'Jan' => 'Jan',
    'Feb' => 'Feb',
    'Mar' => 'Mar',
    'Apr' => 'Apr',
    'May' => 'May',
    'Jun' => 'Jun',
    'Jul' => 'Jul',
    'Aug' => 'Aug',
    'Sep' => 'Sep',
    'Oct' => 'Oct',
    'Nov' => 'Nov',
    'Dec' => 'Dec',


    'Abbreviation' => 'Abbreviation',
    'Accreditation Provider' => 'Accreditation Provider',
    'Accreditation Result' => 'Accreditation Result',
    'Action' => 'Action',    
    'Active' => 'Active',
    'Active?' => 'Active?',
    'Active in Association' => 'Active in Association',
    'Add' => 'Add',
    'Add Season Club Record' => 'Add Season Club Record',
    'Add Season Record' => 'Add Season Record',
    'Added By' => 'Added By',
    'Additional Contacts' => 'Additional Contacts',
    'Address Line 1' => 'Address Line 1',
    'Address Line 2' => 'Address Line 2',
    'Age Group' => 'Age Group',
    'Age Groups' => 'Age Groups',
    'Allow Clubs to' => 'Allow Clubs to',
    'Allow Medical Treatment' => 'Allow Medical Treatment',
    'Allow Teams to' => 'Allow Teams to',
    'Allow Parent Body' => 'Allow Parent Body',
    'Alternate Uniform Bottom Colour' => 'Alternate Uniform Bottom Colour',
    'Alternate Uniform Number' => 'Alternate Uniform Number', # is this actually number colour?
    'Alternate Uniform Number Colour' => 'Alternate Uniform Number Colour',
    'Alternate Uniform Top Colour' => 'Alternate Uniform Top Colour',
    'Amount' => 'Amount',
    'Any Allergies' => 'Any Allergies',
    'Any Medical Conditions?' => 'Any Medical Conditions?',
    'Application Date' => 'Application Date',
    'Association' => 'Association',
    'Association Name' => 'Association Name',
    'Association Season Member Package' => 'Association Season Member Package',
    'Association Summary' => 'Association Summary',
    'Associations' => 'Associations',
    'Athletics Associations' => 'Athletic Associations',
    'Audit Log' => 'Audit Log',
    'Bank Account Details' => 'Bank Account Details',
    'Birth Certificate Number' => 'Birth Certificate Number',
    'Both' => 'Both',
    'Business Number' => 'Business Number',
    'cannot contain HTML' => 'cannot contain HTML',
    'cannot have spaces' => 'cannot have spaces',
    'Career Games' => 'Career Games',
    'Choose an option from the list below' => 'Choose an option from the list below',
    'City of Residence' => 'City of Residence',
    'Click here to resolve it.' => 'Click here to resolve [quant2,_1,it,them].',
    'Club' => 'Club',
    'Club Name' => 'Club Name',
    'Club Season Member Package' => 'Club Season Member Package',
    'Clubs' => 'Clubs',
    'Coach?' => 'Coach?',
    'Coach in<br>Association?' => 'Coach in<br>Association?',
    'Coach in<br>Club?' => 'Coach in<br>Club?',
    'Coach Active?' => 'Coach Active?',
    'Coach Registration No.' => 'Coach Registration No.',
    'Colours' => 'Colours',
    'Communicator' => 'Communicator',
    'Competition' => 'Competition',
    'Competitions' => 'Competitions',
    'Compulsory' => 'Compulsory',
    'Compulsory Field' => 'Compulsory Field',
    'Configuration' => 'Configuration',
    'Contact' => 'Contact',
    'Contact Email' => 'Contact Email',
    'Contact Email 2' => 'Contact Email 2',
    'Contact Email 3' => 'Contact Email 3',
    'Contact Person' => 'Contact Person',
    'Contact Person 2' => 'Contact Person 2',
    'Contact Person 3' => 'Contact Person 3',
    'Contact Phone 2' => 'Contact Phone 2',
    'Contact Phone 3' => 'Contact Phone 3',
    'Country' => 'Country',
    'Courses' => 'Courses',
    'Custom Fields' => 'Custom Fields',
    'Database Error in Addition' => 'Database Error in Addition',
    'Database Error in Update' => 'Database Error in Update',
    'Date' => 'Date',
    'Date Added' => 'Date Added',
    'Date Created Online' => 'Date Created Online',
    'Date First Registered' => 'Date First Registered',
    'Date Last Registered' => 'Date Last Registered',
    'Date of Birth' => 'Date of Birth',
    'Date Registered Until' => 'Date Registered Until',
    'Date Suspended Until' => 'Date Suspended Until',
    'Deceased?' => 'Deceased?',
    'Defaulter' => 'Defaulter',
    'Delete' => 'Delete',
    'Details' => 'Details',
    'Deregistered' => 'Deregistered',
    'Display details for [_1]' => 'Display details for [_1]', 
    'Duplicate Resolution' => 'Duplicate Resolution',
    'Edit' => 'Edit',
    'Edit Welcome Message' => 'Edit Welcome Message',
    'Editable' => 'Editable',  
    'eduAddMember_course' => 'Showing all people that have participated in other courses. Click on a name to add them to this course, or click <img src="images/add_icon.gif" border="0"> to enter details for a new participant',
    'eduListDAS' => 'Showing all staff for this delivery agent. Staff can be assigned to modules and courses while editing a specific module or course. Click on a name to edit details.',
    'eduListDeliveryAgent' => 'Delivery agents can be licenced to run courses and modules.',
    'eduListLicence' => 'Showing all licences for this delivery agent. Licences grant a delivery agent the ability to run courses and modules between specified dates.',
    'eduListMem_course' => 'Showing all participants in this course. Click on a member\'s name to edit that member and on <img src="images/sml_edit_icon.gif" border="0"> to edit their status for this course. You can use the buttons in the top right to add new members to the course and quickly approve members.',
    'eduListMem_da' => 'Showing all people that have participated in a course. Click on a name to edit their details, then use the new menu in the bottom left of the screen to administer them.',
    'eduListMem_mem' => 'Showing all modules for this member. Click on a course code to edit their details in that course.',
    'eduListMMT' => 'Showing all certificates issued for this member. Click on the certificate name to edit it or on the <img src="images/sml_view_icon.gif" border="0"> icon to print the certificate.',
    'eduListMTL' => 'Template links connect course templates to their child module templates. When a delivery agent schedules a course, the structure created here will be replicated.',
    'eduListModule_course' => 'Showing modules in this course. If you click on a module the bottom left menu will change, allowing you to administer that module.',
    'eduListModule_da' => 'Showing all modules and courses that you are licenced to run. Click a course code to see scheduled and past courses or click "Create Course" / "Create Module" on the right to schedule a new course or module.',
    'eduListModuleInstance_da' => 'Showing all scheduled, <i>past</i> and <span style="color:red">cancelled</span> <b>courses</b> and modules. Click on a course or module code to edit it, then use the new menu in the bottom left of the screen to administer it.',
    'eduListVenue' => 'Showing all venues. Venues can be assigned to modules and courses while editing a specific module or course. Click on a venue name to edit details.',
    'eduListModuleStaff' => 'Showing all staff for this module / course. Click on a name to edit their details for this course, or click <img src="images/sml_delete_icon.gif" border="0"> to remove them from this course.',
    'eduListModuleTemplate' => 'Templates specify the different types of courses and modules that delivery agents can run.',
    'eduMMTModules' => 'Check the modules and course that should show on this certificate. Only a single course and only modules which haven\'t already been included in a certificate can be selected.',
    'eduShowCourseSearch' => 'Select one or more fields, then click Search. If you select no fields, all courses will be shown',
    'eduShowPaymentSearch' => 'Select one or more fields, then click search. If you select no fields, all payments will be shown',
    'eduTransList_unpaid' => 'Showing unpaid items. To view paid items, click \'Paid\' above. To add a payment, tick one or more items, then enter the payment details at the bottom of the page and click \'Add Payment\'.',
    'eduTransList_paid' => 'Showing paid items. You can edit the payment associated with these items by clicking the <img src="images/player_pay.gif" border="0"> icon. To view all items for a single payment, click \'Filter by linked payment\'. To cancel a payment, click <img src="images/player_pay.gif" border="0">, then click \'*Cancel Payment*\'',
    'eduListPayment' => 'Showing payments. To edit a payment, click <img src="images/player_pay.gif" border="0">. To view the items in a payment, click \'View Items\'',

    'eduReportMember' =>
        'Choose which fields you want on your report and any filters you ' .
        'wish to apply. When complete press the "[_1]" button.',

    'eduReportStaff' =>
        'Choose which fields you want on your report and any filters you ' .
        'wish to apply. When complete press the "[_1]" button.',

    'Email' => 'Email',
    'Email 2' => 'Email 2',
    'Emergency Contact Name' => 'Emergency Contact Name',
    'Emergency Contact Number' => 'Emergency Contact Number',
    'Emergency Contact Number 2' => 'Emergency Contact Number 2',
    'Emergency Contact Relationship' => 'Emergency Contact Relationship',
    'End Date' => 'End Date',
    'Entity ID' => 'Entity ID',
    'Estimated Participants' => 'Estimated Participants',
    'Estimated Registered Players' => 'Estimated Registered Players',
    'Estimated Un-Registered Players' => 'Estimated Un-Registered Players',
    'Ethnicity' => 'Ethnicity',
    'Exclude from Club Championships' => 'Exclude from Club Championships',
    'Eye Colour' => 'Eye Colour',
    'Family Name' => 'Family Name',
    'Family name' => 'Family name',
    'First Name' => 'First Name',
    'Fax' => 'Fax',
    'Field options' => 'Field Options',
    'Fields Updated' => 'Fields Updated',
    'Financial?' => 'Financial?',
    'First name' => 'First name',
    'Fitness Tests' => 'Fitness Tests',
    'From here you can login to your Sportzware Membership online system.' => 'From here you can login to your Sportzware Membership online system.',
    'Gender' => 'Gender',
    'Hair Colour' => 'Hair Colour',
    'Health Care Number' => 'Health Care Number',
    'Height' => 'Height',
    'Help' => 'Help',
    'Hidden' => 'Hidden',    
    'Home Venue Name' => 'Home Venue Name',
    'Home Venue Address' => 'Home Venue Address',
    'Home Venue Post Code' => 'Home Venue Post Code',
    'Home Venue Suburb' => 'Home Venue Suburb',
    'How did you find out about us?' => 'How did you find out about us?',
    'How many national games do you attend per season?' => 'How many national games do you attend per season?',
    'How often do you watch matches on TV?' => 'How often do you watch matches on TV?',
    'I cannot find any records of changes' => 'I cannot find any records of changes',
    'Identification Number' => 'Identification Number',
    'Identification Type' => 'Identification Type',
    'in' => 'in',
    'Inactive' => 'Inactive',
    'Incorporation Number' => 'Incorporation Number',
    'Instructor Registration No' => 'Instructor Registration No',
    'International' => 'International',
    'International Region' => 'International Region',
    'International Regions' => 'International Regions',
    'International Zone' => 'International Zone',
    'International Zones' => 'International Zones',
    'Invalid Date' => 'Invalid Date',
    'is not between [_1] and [_2]' => 'is not between [_1] and [_2]',
    'is not less than [_1]' => 'is not less than [_1]',
    'is not less than or equal to [_1]' => 'is not less than or equal to [_1]',
    'is not more than [_1]' => 'is not more than [_1]',
    'is not more than or equal to [_1]' => 'is not more than or equal to [_1]',
    'is not a valid date' => 'is not a valid date',
    'is not a valid email address' => 'is not a valid email address',
    'is not a valid number' => 'is not a valid number',
    'Jumper Numbers' => 'Jumper Numbers',
    'Junior?' => 'Junior?',
    'Last Recorded Game' => 'Last Recorded Game',
    'Last Updated' => 'Last Updated',
    'Level' => 'Level',
    'Life Member?' => 'Life Member?',
    'List of Payment Records' => 'List of Payment Records',
    'Login' => 'Login',
    'Logout' => 'Logout',
    'Loyalty Number' => 'Loyalty Number',
    'Maiden name' => 'Maiden name',
    'Mailing List?' => 'Mailing List?',
    'Manage Lookup Information' => 'Manage Lookup Information',
    'Manager' => 'Manager',
    'Match Official?' => 'Match Official?',
    'Match Official in<br>Association?' => 'Match Official in<br>Association?',
    'match Official in<br>Club?' => 'Match Official in<br>Club?',
    'Match Official Active?' => 'Match Official Active?',
    'Match Official Registration No.' => 'Match Official Registration No.',
    'Medical Notes' => 'Medical Notes',
    'Member' => 'Member',
    'Member Financial?' => 'Member Financial?',
    'Member Financial Balance' => 'Member Financial Balance',
    'Member Number' => 'Member Number',
    'Member Package' => 'Member Package',
    'Member Passwords' => 'Member Passwords',
    'Member Tags' => 'Member Tags',
    'Member Types' => 'Member Types',

    ## START NOT PRESENT IN fr.pm

    'Member Types: Player' => 'Member Types: Player',
    'Member Types: Referee' => 'Member Types: Referee',
    'Member Types: Official' => 'Member Types: Official',
    'Member Types: Match Official' => 'Member Types: Match Official',
    'Member Types: Misc' => 'Member Types: Misc',
    'Member Types: FAO' => 'Member Types: FAO',
    'Member Types: Volunteer' => 'Member Types: Volunteer',
    'Member Types: Riders' => 'Member Types: Riders',
    'Member Types: Coach' => 'Member Types: Coach',
    'Member Types: Coach Accred' => 'Member Types: Coach Accred',
    'Member Types: Referee Accred' => 'Member Types: Referee Accred',
    'Member Types: Official Accred' => 'Member Types: Official Accred',
    'Member Types: Match Official Accred' => 'Member Types: Match Official Accred',
    'Member Types: FAO Accred' => 'Member Types: FAO Accred',
    'Member Types: Volunteer Accred' => 'Member Types: Volunteer Accred',
    'Member Types: Misc Accred' => 'Member Types: Misc Accred',
    'Member Types: Rider Accred' => 'Member Types: Rider Accred',
    'Member Types: Coach Position' => 'Member Types: Coach Position',
    'Member Types: Referee Position' => 'Member Types: Referee Position',
    'Member Types: Official Position' => 'Member Types: Official Position',
    'Member Types: Match Official Position' => 'Member Types: Match Official Position',
    'Member Types: FAO Position' => 'Member Types: FAO Position',
    'Member Types: Volunteer Position' => 'Member Types: Volunteer Position',
    'Member Types: Misc Position' => 'Member Types: Misc Position',
    'Member Types: Rider Position' => 'Member Types: Rider Position',

    ## END NOT PRESENT IN fr.pm

    'Members' => 'Members',
    'Membership Package' => 'Membership Package',
    'Middle name' => 'Middle name',
    'Misc?' => 'Misc?',
    'Modify Member List' => 'Modify Member List',
    'Month', => 'Month',
    'must be [_1] characters long' => 'must be [_1] characters long',
    'Name' => 'Name',
    'Name (or part of name)' => 'Name (or part of name)',
    'National Bodies' => 'National Bodies',
    'National Body' => 'National Body',
    'National Number' => 'National Number',
    'National Team' => 'National Team',
    'Nickname' => 'Nickname',
		'No Clubs of this status can be found in the database.' => 'No Clubs of this status can be found in the database.',
    'No entries match your Search criteria. Please try again' => 'No entries match your Search criteria. Please try again',
    'No Payment Records can be found in the database.' => 'No Payment Records can be found in the database.',
    'No Tags Found' => 'No Tags Found',
    'Not Available' => 'Not Available',
    'Notes' => 'Notes',
    'Occupation' => 'Occupation',
    'Official?' => 'Official?',
    'Offline Number' => 'Offline Number',
    'OR' => 'OR',
    'or' => 'or',
    'Other Details' => 'Other Details',
    'Pager' => 'Pager',
    'Parent/Guardian 1 Assistance Area' => 'Parent/Guardian 1 Assistance Area',
    'Parent/Guardian 1 Email' => 'Parent/Guardian 1 Email',
    'Parent/Guardian 1 Email 2' => 'Parent/Guardian 1 Email 2',
    'Parent/Guardian 1 Firstname' => 'Parent/Guardian 1 Firstname',
    'Parent/Guardian 1 Gender' => 'Parent/Guardian 1 Gender',
    'Parent/Guardian 1 Mobile' => 'Parent/Guardian 1 Mobile',
    'Parent/Guardian 1 Phone' => 'Parent/Guardian 1 Phone',
    'Parent/Guardian 1 Phone 2' => 'Parent/Guardian 1 Phone 2',
    'Parent/Guardian 1 Salutation' => 'Parent/Guardian 1 Salutation',
    'Parent/Guardian 1 Surname' => 'Parent/Guardian 1 Surname',
    'Parent/Guardian 2 Assistance Area' => 'Parent/Guardian 2 Assistance Area',
    'Parent/Guardian 2 Email' => 'Parent/Guardian 2 Email',
    'Parent/Guardian 2 Email 2' => 'Parent/Guardian 2 Email 2',
    'Parent/Guardian 2 Firstname' => 'Parent/Guardian 2 Firstname',
    'Parent/Guardian 2 Gender' => 'Parent/Guardian 2 Gender',
    'Parent/Guardian 2 Mobile' => 'Parent/Guardian 2 Mobile',
    'Parent/Guardian 2 Phone' => 'Parent/Guardian 2 Phone',
    'Parent/Guardian 2 Phone 2' => 'Parent/Guardian 2 Phone 2',
    'Parent/Guardian 2 Salutation' => 'Parent/Guardian 2 Salutation',
    'Parent/Guardian 2 Surname' => 'Parent/Guardian 2 Surname',
    'Passport Country of Issue' => 'Passport Country of Issue',
    'Passport Expiry Date' => 'Passport Expiry Date',
    'Password' => 'Password',
    'Password Management' => 'Password Management',
    'Payment Type' => 'Payment Type',
    'Permissions' => 'Permissions',
    'Permissions Updated' => 'Permissions Updated',
    'Please enter your username and password below and then press the Sign in button.' => 'Please enter your username and password below and then press the Sign in button.',
    'Phone' => 'Phone',
    'Mobile' => 'Mobile',
    'Phone (Home)' => 'Phone (Home)',
    'Phone (Work)' => 'Phone (Work)',
    'Phone (Mobile)' => 'Phone (Mobile)',
    'Phone 2' => 'Phone 2',
    'Phone 3' => 'Phone 3',
    'Place (Town) of Birth' => 'Place (Town) of Birth',
    'Player?' => 'Player?',
    'Player in<br>Association?' => 'Player in<br>Association?',
    'Player in<br>Club?' => 'Player in<br>Club?',
    'Player Active?' => 'Player Active?',
    'Player Age Group' => 'Player Age Group',
    'Police Check Date' => 'Police Check Date',
    'Police Check Expiry Date' => 'Police Check Expiry Date',
    'Police Check Number' => 'Police Check Number',
    'Position' => 'Position',
    'Postal Code' => 'Postal Code',
    'Preferred name' => 'Preferred name',
    'President' => 'President',
    'Problem Updating Fields' => 'Problem Updating Fields',
    'Problem Updating Permissions' => 'Problem Updating Permissions',
    'Problems' => 'Problems', 
    'Product Blog' => 'Product Blog', 
    'Products', => 'Products',
    'Re-Accreditation' => 'Re-Accreditation',
    'Read Only' => 'Read Only', 
    'Record added successfully' => 'Record added successfully',
    'Record updated successfully' => 'Record updated successfully',
    'Ref. No.' => 'Ref. No.',
    'Region' => 'Region',
    'Regions' => 'Regions',
    'Registration Number' => 'Registration Number',
    'Reports' => 'Reports',
    'Reset' => 'Reset',
    'Response Code' => 'Response Code',
    'Salutation' => 'Salutation',
    'Save Tags' => 'Save Tags',
    'Save Options' => 'Save Options',
    'School' => 'School',
    'School Grade' => 'School Grade',
    'School Name' => 'School Name',
    'School Suburb ' => 'School Suburb ',
    'Search' => 'Search',
    'Search Again' => 'Search Again',
    'Search Entity' => 'Search Entity',
    'Search found the following results' => 'Search found the following results',
    'Search Results' => 'Search Results',
    'Search using the options below' => 'Search using the options below',
    'Season' => 'Season',
    'Season Coach?' => 'Season Coach?',
    'Season Coach Financial?' => 'Season Coach Financial?',
    'Season Match Official?' => 'Season Match Official?',
    'Season Match Official Financial?' => 'Season Match Official Financial?',
    'Season Member Package' => 'Season Member Package',
    'Season Participating?' => 'Season Participating?',
    'Season Player?' => 'Season Player?',
    'Season Player Financial?' => 'Season Player Financial?',
    'Seasons' => 'Seasons',
    'Secretary' => 'Secretary',
    'Selections' => 'Selections',
    'Senior?' => 'Senior?',
    'Services' => 'Services',
    'Signature Sighted' => 'Signature Sighted',
    'Sport' => 'Sport',
    'Sportzware Membership Login Page' => 'Sportzware Membership Login Page',
    'Start Date' => 'Start Date',
    'State' => 'State',
    'State Team Supported' => 'State Team Supported',
    'States' => 'States',
    'Statistics' => 'Statistics',
    'Status' => 'Status',
    'Suburb' => 'Suburb',
    'System developed and powered by [_1]' => 'System developed and powered by [_1]',
    'Tags Updated' => 'Tags Updated',
    'Team' => 'Team',
    'Team Name' => 'Team Name',
    'Team Passwords' => 'Team Passwords',
    'Teams' => 'Teams',
    'The following fields are compulsory and need to be filled in' => 'The following fields are compulsory and need to be filled in',
    'The list is limited to the first [_1] entries.' => 'The list is limited to the first [_1] entries.',
    'Their Details' => 'Their Details',
    'Their Password' => 'Their Password',
    'Their Member Types' => 'Their Member Types',
    'There are no available Tags to assign' => 'There are no available Tags to assign',
    'There was a problem changing the welcome message' => 'There was a problem changing the welcome message',
    'These configuration options allow you to modify the data and behaviour of the system.' => 'These configuration options allow you to modify the data and behaviour of the system.',
    'This is the list of the last 20 changes peformed.' => 'This is the list of the last 20 changes peformed.',
    'This member has been associated with the following tags.' => 'This member has been associated with the following tags.',
    'Title of Contact' => 'Title of Contact',
    'Title of Contact 2' => 'Title of Contact 2',
    'Title of Contact 3' => 'Title of Contact 3',
    'Type' => 'Type',  
    'Uniform Bottom Colour' => 'Uniform Bottom Colour',
    'Uniform Colours' => 'Uniform Colours',
    'Uniform Number' => 'Uniform Number',
    'Uniform Number Colour' => 'Uniform Number Colour',
    'Uniform Top Colour' => 'Uniform Top Colour',
    'Update' => 'Update',
    'Update Association' => 'Update Association',
    'Update Club' => 'Update Club',
    'Update Information' => 'Update Information',
    'Update Permissions' => 'Update Permissions',
    'Update Team' => 'Update Team',
    'Update Welcome Message' => 'Update Welcome Message',
    'Username' => 'Username',
    'Username/Code' => 'Username/Code',
    'Venue 1' => 'Venue 1',
    'Venue 2' => 'Venue 2',
    'Venue 3' => 'Venue 3',
    'Veteran?' => 'Veteran?',
    'View' => 'View',
    'View Receipt' => 'View Receipt',
    'View Type' => 'View Type',
    'View Types' => 'View Types',
    'Volunteer?' => 'Volunteer?',
    'Website' => 'Website',
    'Weight' => 'Weight',
    'Welcome' => 'Welcome',
    'Welcome Message' => 'Welcome Message',
    'Welcome Message Updated' => 'Welcome Message Updated',
    'Yes' => 'Yes',
    'You have [_1] duplicate to resolve.' => 'You have [quant,_1,duplicate,duplicates] to resolve.',
    'You have entered an Invalid Date of birth' => 'You have entered an Invalid Date of birth',
    'Zone' => 'Zone',
    'Zones' => 'Zones',


    '[_1] updated successfully' => '[_1] updated successfully',

    'Event Management' => 'Event Management',
    'Select from the options on the left to manage your event.' => 'Select from the options on the left to manage your event',
    'An invalid Action Code has been passed to me.' => 'An invalid Action Code has been passed to me.',
    'Database Home' => 'Database Home',
    'Menu' => 'Menu',

    'Event Options' => 'Event Options',


    'Edit Event' => 'Edit Event',
    'Configure Event Details' => 'Configure Event Details',
    'Data Export' => 'Data Export',
    'Police Check' => 'Police Check',
    'Consent Forms' => 'Consent Forms',
    'Bulk Printing' => 'Bulk Printing',
    'Apply for a Day Pass' => 'Apply for a Day Pass',

    'Event Name' => 'Event Name',
    'Starting Date for Registrations' => 'Starting Date for Registrations',
    'Closing Date for Registrations' => 'Closing Date for Registrations',
    'Starting Date for Arrivals' => 'Starting Date for Arrivals',
    'Last Date for Departures' => 'Last Date for Departures',
    'Email Address of the Organiser' => 'Email Address of the Organiser',
    'Name of event number (if required)' => 'Name of event number (if required)',

    'Name of event number (if required)'
        => 'Name of event number (if required)',

    'Max number of Venues to appear on accred.'
        => 'Max number of Venues to appear on accred.',

    'Max number of Zones to appear on accred.'
        => 'Max number of Zones to appear on accred.',

    'Automatically Approve Selections' => 'Automatically Approve Selections',

    'Update Event' => 'Update Event',

    'Sports'                   => 'Sports',
    'Sporting Events'          => 'Sporting Events',
    'Accreditation Categories' => 'Accreditation Categories',
    'Approval Types'           => 'Approval Types',

    'Add new record'           => 'Add new record',
    'None Available'           => 'None Available',

    'Sport Name'               => 'Sport Name',
    'Sport Code'               => 'Sport Code',
    'Sort Order'               => 'Sort Order',
    'Other Code'               => 'Other Code',
    'Event Abbrev'             => 'Event Abbrev',
    'Choose a Sport'           => 'Choose a Sport',

    'Male'                     => 'Male',
    'Female'                   => 'Female',
    'Mixed'                    => 'Mixed',
    'Non Specified'            => 'Non Specified',

    'Category Name'                     => 'Category Name',
    'Sub Category'                      => 'Sub Category',
    'Sub Category Abbrev.'              => 'Sub Category Abbrev.',
    'Ask for Sports Selection?'         => 'Ask for Sports Selection?',

    'Ask for Sporting Event Selection?'
        => 'Ask for Sporting Event Selection?',

    'Ask for Job Title'       => 'Ask for Job Title',
    'Ask for Photo?'          => 'Ask for Photo?',
    'Event Approval Statuses' => 'Event Approval Statuses',
    'Approval Name Text'      => 'Approval Name Text',

    'Allow Card Printing when at this status'
        => 'Allow Card Printing when at this status',

    'Name (or part of)'      => 'Name (or part of)',
    'Organisation'           => 'Organisation',
    'Accreditation Category' => 'Accreditation Category',
    'Select Sporting Event'  => 'Select Sporting Event',

    'Fill in the appropriate filter boxes below to search.'
        => 'Fill in the appropriate filter boxes below to search.',

    'Personal Details'               => 'Personal Details',
    'Contact Details'                => 'Contact Details',
    'Identifications'                => 'Identifications',
    'Parent/Guardian'                => 'Parent/Guardian',
    'Medical'                        => 'Medical',
    'Other Fields'                   => 'Other Fields',
    'Selections'                     => 'Selections',
    'Approvals'                      => 'Approvals',
    'Click to Open/Close Group'      => 'Click to Open/Close Group',
    'Filter Only'                    => 'Filter Only',
    'Run Report'                     => 'Run Report',
    'Unique Records Only'            => 'Unique Records Only',
    'Summary Data'                   => 'Summary Data',
    'All Records'                    => 'All Records',
    'Options'                        => 'Options',
    'Show'                           => 'Show',
    'Sort By'                        => 'Sort By',
    'Ascending'                      => 'Ascending',
    'Descending'                     => 'Descending',
    'Secondary Sort By'              => 'Secondary Sort By',
    'None'                           => 'None',
    'Limit'                          => 'Limit',
    'No Limit'                       => 'No Limit',
    'Maximum no. of rows to display' => 'Maximum no. of rows to display',
    'Bulk Change'                    => 'Bulk Change',
    'Select a Status to Assign'      => 'Select a Status to Assign',
    'Assign Approval Statuses'       => 'Assign Approval Statuses',

    'This will assign the status to all matching records'
        => 'This will assign the status to all matching records',

    'Current Level'                  => 'Current Level',
    'Select your report type below.' => 'Select your report type below.',

    'Member Reports'                 => 'Member Reports',
    'Member Summary Reports'         => 'Member Summary Reports',
    'Status Reports'                 => 'Status Reports',
    'Cards Printed'                  => 'Cards Printed',
    'Member Sport Detail Reports'    => 'Member Sport Detail Reports',


    'Passport Nationality' => 'Passport Nationality',
    'Passport Number' => 'Passport Number',



    'NO_BODY' => <<"EOS",
"Oops, this shouldn't be happening. Please contact
<a href="mailto:info\@sportingpulse.com">info\@sportingpulse.com</a>
EOS

    'CHOOSE_AND_REPORT' => <<"EOS",
Choose which fields you want on your report and any filters you wish to apply.
When complete press the "Run Report" button.
EOS

    'REQUIRED_PASS_STATUS' => <<"EOS",
Check the boxes if the status is required for pass printing.  When you have
finished press the '[_1]' button to save your responses.
EOS

    'DATA_EXPORT_LIST_SELECTION' => <<"EOS",
To export for a particular sport or all sports, select the one you want using
the top list.  For only a particular event select in the bottom list.'
EOS

    'DATA_EXPORT_DESCRIPTION' => <<"EOS",
The data exported includes the member name, accreditation type, entry and exit
dates, event number etc.
EOS

    'DATA_EXPORT_EMAIL_PROMPT' => <<"EOS",
The data will be emailed as an attachment to an email address. Enter the email
address in the box below where you want the data to be sent.
EOS

    'DATA_EXPORT_FORMAT_DESCRIPTION' => <<"EOS",
You can export the data in two formats. Sportzware format is for importing
into the Sportzware competition management software package. Generic (Tab
delimited) file format is suitable for other programs eg MS Excel.
Accreditation information can only be exported in the Generic format.
EOS


    'DATA_EXPORT_EMAIL_TEXT' => <<"EOS",
The data you requested for export ([_1]) is included in the attached file.
EOS


    'DATA_EXPORT_EMAIL_SENT' => <<"EOS",
<p>Your data has been sent successfully.</p>
<p>If it does not arrive immediately please be patient.</p>
EOS

    'MARK_CONSENT_FORM_RECEIVED' => <<"EOS",
Mark form as received by entering the Form reference number and press the
'[_1]' button.
EOS

    'SEARCH_FOR_CONSENT_FORM' => <<"EOS",
Search for a person by entering their surname and/or first name and then press
the '[_1]' button.
EOS

    'ACCREDITATION_CATEGORY_SELECTION_TEXT' => <<"EOS",
<p>
  Your Accreditation Application category selections are outlined below. Click
  on "[_1]" to review your application information.
  <br><br>
  If this Category Selection is incorrect, click "[_2]".
</p>
EOS

    'PLEASE_COMPLETE_BIO' => <<"EOS",
Please complete the Biographical Information below.  When you have finished
press the '[_1]' button.
EOS

    'MUST_PRINT_CONSENT_FORM' => <<"EOS",
<p>
  It is a requirement of accreditation that the consent form must be printed,
  signed and returned.
</p>
EOS

    'UPLOAD_PHOTO_FORM_TEXT' => <<"EOS",
<p>
  <b>Photos should generally comply with the following:</b>
</p>
<ul>
  <li>True likeness of the applicant</li>
  <li>Front view of the applicant's head and shoulders</li>
  <li>No hats or sunglasses</li>
  <li>Taken on a white background</li>
  <li>Less than 6 months old </li>
</ul>
EOS

    'MODIFY_PHOTO_FORM_HEADER' => <<"EOS",
<p>
  Crop the photo by dragging the rectangle as required.  The preview shows how
  your photo will be displayed[_1].
</p>
<p>When you have finished making changes click the '[_2]' button below.</p>
EOS

    'MARK_AS_DUPLICATE_INSTRUCTIONS' => <<"EOS",
<p>
  If you believe the [_1] named below is a possible duplicate, click the
  <b>'[_3]'</b> button.
</p>
<p>
  This will mark this [_1] as a duplicate for your [_2] to verify and resolve.
</p>
EOS

    'MARK_AS_DUPLICATE_WARNING' => <<"EOS",
NOTE: Only mark the extra [_1], not the [_1] you believe may be the original
EOS

    'BULK_PRINT_BUTTON_INFO' => <<"EOS",
Press the <b>'[_1]'</b> button to generate a list of passes to be printed.
EOS

    'ACCREDITATION_DETAILS_TOP' => <<"EOS",
Choose the relevant options below and press the <b>'[_1]'</b> button when
complete to save your changes.  <b>Note</b>  By making individual changes to a
person's accreditation and subsequent changes made to the default
accreditation settings will not be reflected here.
EOS

    'ENTER_USER_PASSWORD' => <<"EOS",
Please enter your username and password below and then press the '[_1]'
button.
EOS

    'CHOOSE_HOW_REPORTS' => <<"EOS",
Choose how you want to receive the data from this report.
EOS

    'DISPLAY_REPORT' => <<"EOS",
Open the report for viewing on the screen.
EOS

    'EMAIL_REPORT' => <<"EOS",
Email the report in a format suitable to be imported into another product.
EOS

    'CHOOSE_EXPORT_FORMAT' => <<"EOS",
Choose the export format you wish to use
EOS

    'EXPORT_WARNING' => <<"EOS",
This option has a specified set of fields that it exports, however filters are
applied.
EOS

    'ROLLOVER_INSTRUCTIONS' => <<"EOS",
<p>
  Select the season you would like to register the selected players to and
  then click on the "[_1]" button. You will then be taken to a screen where
  you select and deselect the members you wish to register.
</p>
EOS

);

sub getNumberOf {
    my $result = 'Number of ' . $_[1];
    return $result;
}


sub getSearchingFrom {
    my $result = 'Searching from ' . $_[1] . ' down';
    return $result; 
}

1;
