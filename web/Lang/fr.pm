#
# $Header: svn://svn/SWM/trunk/web/Lang/fr.pm 9691 2013-10-08 00:45:50Z apurcell $
#

package Lang::fr;
use base qw(Lang);
use strict;
use vars qw(%Lexicon);
%Lexicon = (

    APPNAME => 'SportingPulse - Sportzware Membership',

    AUTO_INTROTEXT => <<"EOS",
Modifier les données dans les cases ci-dessous tel que requis. Lorsque
terminé, appuyer sur le bouton <b>'[_1]'</b>.<br><b>Noter:</b>. Toutes les
cases marquées avec [_2] doivent être remplies.
EOS
    
    COPYRIGHT => '© Copyright SportingPulse.',

    EVENTCOPY_info => <<"EOS",
Cette option permet la copie d'un jeu d'informations d'un tiers évènement
sur cet évènement. Pour procéder, veuillez entrer le nom d'utilisateur et
le mot de passe de l'évènement que vous désirez copier, et choisissez ce
que vous désirez copier. Lorsque complété, cliquez sur le bouton '[_1]'.
EOS

    FIELDS_intro => "Choose the options for each Member field.",

    HTMLFORM_INTROTEXT => 'auto',

    PERMISSIONS_intro => "Choose the options below to set the permissions various users have to perform tasks in the database. When you have selected the permissions press the <b>'Update Permissions'</b> button to save your settings. <br><b>NB.</b> The permissions only apply to the Members/Club/Teams that the user has access to already.  It does not convey extra permissions.",

    ROWS_FOUND => '[_1] rangées trouvées',

    TO_UPD_WELCOME => <<"EOS",
<p>
  Pour mettre à jour le Message de Bienvenue qui apparait quand vous (ou l'un
  de vos clubs/équipes) vous connectez, remplissez le champs et cliquez sur
  le bouton <b>[_1]</b>.
</p>
EOS

    WELCOME => <<"EOS",
<p>
  Dans la barre du menu à gauche, vous trouverez une liste de toutes les
  options disponibles. Ces options varient en fonction de votre niveau
  d'accès.
</p>
<p>
  En positionnant le pointeur de votre souris sur chacune des icônes dans la
  barre du menu (sur la gauche), sa fonction sera montrée.
</p>
<p>
  Si vous rencontrez des problèmes avec Sportzware Membership ou si vous
  souhaitez fournir des commentaires, merci de nous contacter au
  <a href="mailto:support\@sportingpulse.com">support\@sportingpulse.com</a>.
</p>
EOS

    REPORT_INTRO_TEXT => <<"EOS",
<p>
  Les rapports sont regroupés en différentes zones en fonction des données
  qu'ils rapport sur. Choisissez le type de rapport que vous souhaitez
  utiliser à partir des boutons sur la gauche.
</p>
EOS

    REPORT_INTRO_DESC_TEXT => <<"EOS",
<p>Il existe deux types de rapports présents dans le système.</p>
<br>
<ol>
  <li>
    <b>Rapports Rapide</b> - Indiqué par le bouton «Exécuter», ils sont
    prédéfinis et vous permettre un coup d'oeil rapide à vos données.<br>
  </li>
  <li>
    <b>Rapports Avancés</b> - Indiqué par le bouton «Configurer», ils vous
    permettent de définir les champs que vous souhaitez afficher et ajouter
    des filtres personnalisés pour votre rapport.<br>
  </li>
</ol>
EOS

    ADV_REPORT_INTRO => <<"EOS",
<p>
  Choisissez le champ de la colonne de gauche et glissez le dans la zone
  Champs sélectionnés (la boîte sera élargi pour répondre à vos champs).
</p>
<p>
  Différents types de champs sont disponibles auprès de groupements domaine
  différent. Cliquez sur le titre pour ouvrir le groupe.
</p>
<p>
  Cliquez sur le bouton "Exécuter un rapport» pour exécuter le rapport.
</p>
EOS

    'Jan' => 'Janv',
    'Feb' => 'Févr',
    'Mar' => 'Mars',
    'Apr' => 'Avril',
    'May' => 'Mai',
    'Jun' => 'Juin',
    'Jul' => 'Juil',
    'Aug' => 'Août',
    'Sep' => 'Sept',
    'Oct' => 'Oct',
    'Nov' => 'Nov',
    'Dec' => 'Déc',

    'Abbreviation' => 'Abréviation',
    'Accreditation Provider' => 'Accreditation Provider', #todo
    'Accreditation Result' => 'Accreditation Result', #todo
    'Action' => 'Action',    
    'Active' => 'Actif',
    'Active?' => 'Actif?',
    'Active in Association' => "Actif dans l'association",
    'Add' => 'Ajouter',
    'Add Season Club Record' => 'Add Season Club Record', #todo
    'Add Season Record' => 'Add Season Record', #todo
    'Added By' => 'Ajouté par',

    'Additional Contacts' => 'Contacts Supplémentaires ',

    'Address Line 1' => 'Adresse Ligne 1',
    'Address Line 2' => 'Adresse Ligne 2',
    'Age Group' => "Groupe d'Âge",
    'Age Groups' => "Groupes d'âge",
    'Allow Clubs to' => 'Allow Clubs to',  #todo #have another look at where this is used...
    'Allow Medical Treatment' => 'Allow Medical Treatment', #todo
    'Allow Teams to' => 'Allow Teams to',  #todo
    'Allow Parent Body' => 'Allow Parent Body', #todo
    'Alternate Uniform Bottom Colour' => "Alterner couleur basse uniforme",
    'Alternate Uniform Number' => 'Alternate Uniform Number', #is this actually number colour? #todo

    'Alternate Uniform Number Colour'
        => "Alterner nombre de couleur uniforme",

    'Alternate Uniform Top Colour' => "Alterner couleur haute uniforme",
    'Amount' => 'Amount', #todo
    'Any Allergies' => 'Allergies',
    'Any Medical Conditions?' => 'Conditions Médicales?',
    'Allergies?' => 'Allergies?',
    'Medical Conditions?' => 'Conditions Médicales?',
    'Application Date' => 'Application Date', #todo
    'Association' => 'Association',
    'Association Name' => "Nom de l'Association",
    'Association Season Member Package' => 'Association Season Member Package', #todo
    'Association Summary' => 'Résumé des associations',
    'Associations' => 'Associations',
    'Athletics Associations' => "Associations d'athlétisme",
    'Audit Log' => "Journal d'Audit",
    'Bank Account Details' => 'Détails du compte en banque',
    'Birth Certificate Number' => 'Birth Certificate Number', #todo
    'Both' => 'Les deux',
    'Business Number' => "Numéro d'affaires",
    'cannot contain HTML' => 'cannot contain HTML', #todo
    'cannot have spaces' => 'cannot have spaces',   #todo
    'Career Games' => 'Career Games', #todo
    'Choose an option from the list below' => 'Choose an option from the list below', #todo
    'City of Residence' => 'Ville de résidence',
    'Click here to resolve it.' => 'Cliquez ici pour résoudre.',
    'Club' => 'Club',
    'Club Name' => 'Nom du Club',
    'Club Season Member Package' => 'Paquet membre du Club Saison',
    'Clubs' => 'Clubs',
    'Coach?' => 'Entraîneur?',
    'Coach in<br>Association?' => 'Entraîneur<br>en Association?',
    'Coach in<br>Club?' => 'Entraîneur dans<br>le Club?',
    'Coach Active?' => 'Coach Active?', #todo
    'Coach Registration No.' => 'Coach Registration No.', #todo
    'Colours' => 'Couleurs',
    'Communicator' => 'Communicator', #todo maybe
    'Competition' => 'Compétition',
    'Competitions' => 'Compétitions',
    'Compulsory' => 'Compulsory', #todo
    'Compulsory Field' => 'Compulsory Field', #todo
    'Configuration' => 'Configuration',
    'Contact' => 'Contact',
    'Contact Email' => 'Contact e-mail',
    'Contact Email 2' => 'Contact e-mail 2',
    'Contact Email 3' => 'Contact e-mail 3',
    'Contact Person' => 'Nom du Contact',
    'Contact Person 2' => 'Nom du Contact 2',
    'Contact Person 3' => 'Nom du Contact 3',
    'Contact Phone 2' => 'Contact Phone 2', #todo
    'Contact Phone 3' => 'Contact Phone 3', #todo
    'Country' => 'Pays',
    'Courses' => 'Cours', #pre-ms
    'Custom Fields' => 'Custom Fields', #todo
    'Database Error in Addition' => 'Database Error in Addition', #todo
    'Database Error in Update' => 'Database Error in Update', #todo
    'Date' => 'Date',
    'Date Added' => "Date d'ajout",
    'Date Created Online' => 'Date Created Online', #todo
    'Date First Registered' => 'Date First Registered', #todo
    'Date Last Registered' => 'Dernière Date Enregistrée',
    'Date of Birth' => 'Date de naissance',
    'Date Registered Until' => 'Date Registered Until', #todo
    'Date Suspended Until' => 'Date Suspended Until', #todo
    'Deceased?' => 'Décédé?',
    'Defaulter' => 'Defaulter', #todo
    'Delete' => 'Effacer',
    'Details' => 'Détails',
    'Deregistered' => 'Deregistered', #todo
    'Display details for [_1]' => 'Display details for [_1]', #todo
    'Duplicate Resolution' => 'Résolution des Doublons',
    'Edit' => 'Éditer',
    'Edit Welcome Message' => 'Editer le message de bienvenue',
    'Editable' => 'Editable', #todo
    'Email' => 'E-mail',
    'Email 2' => 'E-mail 2',
    'Emergency Contact Name' => 'Emergency Contact Name', #todo
    'Emergency Contact Number' => 'Emergency Contact Number', #todo
    'Emergency Contact Number 2' => 'Emergency Contact Number 2', #todo
    'Emergency Contact Relationship' => 'Emergency Contact Relationship', #todo
    'End Date' => 'End Date', #todo
    'Entity ID' => 'Entity ID', #todo

    'Ethnicity' => 'Ethnie',
    'Exclude from Club Championships' => 'Exclude from Club Championships', #todo
    'Eye Colour' => 'Couleur des yeux',
    'Family Name' => 'Nom de famille',
    'Family name' => 'Nom de famille',
    'First Name' => 'Prénom',
    'Fax' => 'Fax',
    'Field options' => 'Field Options', #todo
    'Fields Updated' => 'Fields Updated', #todo
    'Financial?' => 'Financial?', #todo
    'First name' => 'Prénom',
    'Fitness Tests' => 'Tests Sportifs', #pre-ms

    'From here you can login to your Sportzware Membership online system.' =>
        "D'ici vous pouvez vous connecter via votre code d'accès " .
        'Sportzware en ligne.',

    'Gender' => 'Sexe',
    'Hair Colour' => 'Couleur des cheveux',
    'Health Care Number' => 'Health Care Number', #todo
    'Height' => 'Taille',
    'Help' => 'Aide',
    'Hidden' => 'Hidden', #todo
    'Home Venue Name' => 'Nom du lieu de domicile',
    'Home Venue Address' => 'Adresse du lieu de domicile',
    'Home Venue Post Code' => 'Code postal du Lieu de domicile',
    'Home Venue Suburb' => 'Banlieue/Quartier du Lieu de domicile',
    'How did you find out about us?' => 'How did you find out about us?', #todo
    'I cannot find any records of changes'
        => "Il n'y a pas de rapport des modifications",

    'Identification Number' => 'Identification Number', #todo
    'Identification Type' => 'Identification Type', #todo
    'in' => 'dans',
    'Inactive' => 'Inactif',
    'Incorporation Number' => "Numéro d'Incorporation",
    'Instructor Registration No' => 'Instructor Registration No', #todo
    'International' => 'International', #todo maybe
    'International Region' => 'International Region', #todo maybe
    'International Regions' => 'International Regions', #todo maybe
    'International Zone' => 'International Zone', #todo maybe
    'International Zones' => 'International Zones', #todo maybe
    'Invalid Date' => 'Invalid Date', #todo maybe
    'is not between [_1] and [_2]' => 'is not between [_1] and [_2]', #todo
    'is not less than [_1]' => 'is not less than [_1]', #todo
    'is not less than or equal to [_1]' => 'is not less than or equal to [_1]', #todo
    'is not more than [_1]' => 'is not more than [_1]', #todo
    'is not more than or equal to [_1]' => 'is not more than or equal to [_1]', #todo
    'is not a valid date' => 'is not a valid date', #todo
    'is not a valid email address' => 'is not a valid email address', #todo
    'is not a valid number' => 'is not a valid number', #todo
    'Jumper Numbers' => 'Jumper Numbers', #todo
    'Junior?' => 'Junior?', #todo
    'Last Recorded Game' => 'Last Recorded Game', #todo
    'Last Updated' => 'Last Updated', #todo
    'Level' => 'Niveau',
    'List of Payment Records' => 'Liste des rapports de paiement',
    'Login' => 'Connexion',
    'Logout' => 'Déconnexion',
    'Loyalty Number' => 'Loyalty Number', #todo
    'Maiden name' => 'Nom de jeune fille',
    'Manage Lookup Information' => 'Manage Lookup Information', #todo
    'Manager' => 'Directeur',
    'Match Official?' => 'Officiel de Match?',
    'Match Official in<br>Club?' => 'Match Officiel dans<br>le Club?',
    'Match Official Active?' => 'Match Official Active?', #todo
    'Match Official Registration No.' => 'Match Official Registration No.', #todo
    'Medical Notes' => 'Notes médicales',
    'Member' => 'Membre',
    'Member Financial?' => 'Member Financial?', #todo
    'Member Financial Balance' => 'Member Financial Balance', #todo
    'Member Number' => 'Member Number', #todo
    'Member Tags' => 'Member Tags', #todo
    'Member Types' => 'Member Types', #todo
    'Members' => 'Membres',
    'Middle name' => 'Deuxième prénom',
    'Misc?' => 'Misc?', #todo
    'Modify Member List' => 'Modifier la liste des membres',
    'Month', => 'Mois',
    'must be [_1] characters long' => 'must be [_1] characters long', #todo
    'Name' => 'Nom',
    'Name (or part of name)' => 'Nom (ou partie du nom)',
    'National Bodies' => 'National Bodies', #todo
    'National Body' => 'Organisme national',
    'National Number' => 'National Number', # todo
    'National Team' => 'National Team', #todo
    'Nickname' => 'Surnom',

    'No entries match your Search criteria. Please try again' =>
        "Aucune entrée ne correspond aux critères de recherche. S'il " .
        "vous plaît essayez de nouveau.",

    'No Payment Records can be found in the database.' => 'No Payment Records can be found in the database.', #todo
    'No Tags Found' => 'No Tags Found', #todo
    'Not Available' => 'Non disponible',
    'Notes' => 'Notes',
    'Occupation' => 'Occupation', #todo
    'Official?' => 'Official?', #todo
    'Offline Number' => 'Offline Number', #todo
    'OR' => 'OU',
    'or' => 'ou',
    'Other Details' => 'Autres détails',
    'Pager' => 'Pager', #todo
    'Parent/Guardian 1 Assistance Area' => 'Parent/Guardian 1 Assistance Area', #todo
    'Parent/Guardian 1 Email' => 'Parent/Guardian 1 Email', #todo
    'Parent/Guardian 1 Email 2' => 'Parent/Guardian 1 Email 2', #todo
    'Parent/Guardian 1 Firstname' => 'Parent/Guardian 1 Firstname', #todo
    'Parent/Guardian 1 Gender' => 'Parent/Guardian 1 Gender', #todo
    'Parent/Guardian 1 Mobile' => 'Parent/Guardian 1 Mobile', #todo
    'Parent/Guardian 1 Phone' => 'Parent/Guardian 1 Phone', #todo
    'Parent/Guardian 1 Phone 2' => 'Parent/Guardian 1 Phone 2', #todo
    'Parent/Guardian 1 Salutation' => 'Parent/Guardian 1 Salutation', #todo
    'Parent/Guardian 1 Surname' => 'Parent/Guardian 1 Surname', #todo
    'Parent/Guardian 2 Assistance Area' => 'Parent/Guardian 2 Assistance Area', #todo
    'Parent/Guardian 2 Email' => 'Parent/Guardian 2 Email', #todo
    'Parent/Guardian 2 Email 2' => 'Parent/Guardian 2 Email 2', #todo
    'Parent/Guardian 2 Firstname' => 'Parent/Guardian 2 Firstname', #todo
    'Parent/Guardian 2 Gender' => 'Parent/Guardian 2 Gender', #todo
    'Parent/Guardian 2 Mobile' => 'Parent/Guardian 2 Mobile', #todo
    'Parent/Guardian 2 Phone' => 'Parent/Guardian 2 Phone', #todo
    'Parent/Guardian 2 Phone 2' => 'Parent/Guardian 2 Phone 2', #todo
    'Parent/Guardian 2 Salutation' => 'Parent/Guardian 2 Salutation', #todo
    'Parent/Guardian 2 Surname' => 'Parent/Guardian 2 Surname', #todo
    'Passport Country of Issue' => 'Passport Country of Issue', #todo
    'Passport Expiry Date' => "Date d'expiration du passeport",
    'Password' => 'Mot de Passe',
    'Password Management' => 'Gestion des mots de passe',
    'Payment Type' => 'Payment Type', #todo
    'Permissions' => 'Permissions', #todo
    'Permissions Updated' => 'Permissions Updated', #todo

    'Please enter your username and password below and then press the ' .
    'Sign in button.'
        =>
    "Merci d'entrer vos nom d'utilisateur et mot de passe ci-dessous et " .
    "d'appuyer sur le bouton Connexion.",

    'Phone' => 'Téléphone',
    'Mobile' => 'Portable',
    'Phone (Home)' => 'Téléphone (Domicile)',
    'Phone (Work)' => 'Téléphone (Travail)',
    'Phone (Mobile)' => 'Téléphone (Portable)',
    'Phone 2' => 'Téléphone 2',
    'Phone 3' => 'Téléphone 3',
    'Place (Town) of Birth' => 'Lieu (Ville) de naissance',
    'Player?' => 'Joueur?', #todo
    'Player in<br>Association?' => "Joueur dans<br>l'Association?",
    'Player in<br>Club?' => 'Joueur dans<br>le le Club?',
    'Player Active?' => 'Player Active?', #todo
    'Player Age Group' => "Groupe d'Âge Joueur",
    'Police Check Date' => 'Police Check Date', #todo
    'Police Check Expiry Date' => 'Police Check Expiry Date', #todo
    'Police Check Number' => 'Police Check Number', #todo
    'Position' => 'Position', #todo
    'Postal Code' => 'Code postal',
    'Preferred name' => 'Nom préféré',
    'President' => 'Président',
    'Problem Updating Fields' => 'Problem Updating Fields', #todo
    'Problem Updating Permissions' => 'Problem Updating Permissions', #todo
    'Problems' => 'Problems',   #todo
    'Products', => 'Produits',
    'Re-Accreditation' => 'Re-Accreditation', #todo
    'Read Only' => 'Read Only',  #todo
    'Record added successfully' => 'Record added successfully', #todo

    'Record updated successfully'
        => 'La base de données a été mise à jour avec succès',

    'Ref. No.' => 'N° de référence',
    'Region' => 'Région',
    'Regions' => 'Régions',
    'Registration Number' => 'Registration Number', #todo
    'Reports' => 'Rapports',
    'Reset' => 'Réinitialiser',
    'Response Code' => 'Response Code', #todo
    'Salutation' => 'Salutations',
    'Save Tags' => 'Save Tags', #todo
    'Save Options' => 'Save Options', #todo
    'School' => 'School', #todo
    'School Grade' => 'School Grade', #todo
    'School Name' => 'School Name', #todo
    'School Suburb ' => 'School Suburb ', #todo
    'Search' => 'Recherche',
    'Search Again' => 'Chercher à nouveau',
    'Search Entity' => 'Rechercher une entité',

    'Search found the following results'
        => 'La recherche a trouvé les résultats suivants',

    'Search Results' => 'Résultats de la recherche',
    'Search using the options below' => 'Recherche en utilisant les options ci-dessous',
    'Season' => 'Saison',
    'Season Coach?' => 'Season Coach?', #todo
    'Season Coach Financial?' => 'Season Coach Financial?', #todo
    'Season Match Official?' => 'Season Match Official?', #todo
    'Season Match Official Financial?' => 'Season Match Official Financial?', #todo
    'Season Member Package' => 'Paquet membre de la Saison',
    'Season Participating?' => 'Season Participating?', #todo
    'Season Player?' => 'Season Player?', #todo
    'Season Player Financial?' => 'Season Player Financial?', #todo
    'Seasons' => 'Saisons',
    'Secretary' => 'Secrétaire',
    'Selections' => 'Sélections',   # check this
    'Senior?' => 'Senior?', #todo
    'Services' => 'Services',
    'Signature Sighted' => 'Signature Voyants',
    'Sport' => 'Sport', #todo

    'Sportzware Membership Login Page'
        => 'Page de connexion à Sportzware Membership',

    'Start Date' => 'Start Date', #todo
    'State' => 'Etat',
    'State Team Supported' => 'State Team Supported', #todo
    'States' => 'Etats',
    'Statistics' => 'Statistiques',
    'Status' => 'Status', #todo maybe
    'Suburb' => 'Banlieue/Quartier',

    'System developed and powered by [_1].'
        => 'Système développé et propulsé par [_1].',

    'Tags Updated' => 'Tags Updated', #todo
    'Team' => 'Equipe',
    'Team Name' => 'Team Name', #todo
    'Team Passwords' => 'Team Passwords', #todo
    'Teams' => 'Equipes',
    'The following fields are compulsory and need to be filled in' => 'The following fields are compulsory and need to be filled in', #todo

    'The list is limited to the first [_1] entries.'
        => 'La liste est limitée aux [_1] premières entrées.',

    'Their Details' => 'Their Details', #todo
    'Their Password' => 'Their Password', #todo
    'Their Member Types' => 'Their Member Types', #todo
    'There are no available Tags to assign' => 'There are no available Tags to assign', #todo

    'There was a problem changing the welcome message'
        => 'Il y avait un problème modifiant le Message de Bienvenue',

    'These configuration options allow you to modify the data and behaviour of the system.' => 'These configuration options allow you to modify the data and behaviour of the system.', #todo
    'This is the list of the last 20 changes peformed.' => 'This is the list of the last 20 changes peformed.', #todo
    'This member has been associated with the following tags.' => 'This member has been associated with the following tags.', #todo
    'Title of Contact' => 'Titre du Contact',
    'Title of Contact 2' => 'Titre du Contact 2',
    'Title of Contact 3' => 'Titre du Contact 3',
    'Type' => 'Type',   #todo maybe
    'Update' => 'Mettre à jour',
    'Update Club' => 'Update Club', #todo
    'Update Information' => 'Mettre à jour les Informations',
    'Update Permissions' => 'Update Permissions', #todo
    'Update Welcome Message' => 'Mettre à jour le Message de Bienvenue',
    'Username' => "Nom d'utilisateur",
    'Username/Code' => "Nom d'utilisateur/code",
    'Veteran?' => 'Veteran?', #todo
    'View' => 'Vue',
    'View Receipt' => 'View Receipt', #todo
    'View Type' => 'View Type', #todo
    'View Types' => 'View Types', #todo
    'Volunteer?' => 'Volunteer?', #todo
    'Website' => 'Site internet',
    'Weight' => 'Poids',
    'Welcome' => 'Bienvenue',
    'Welcome Message' => 'Message de Bienvenue',

    'Welcome Message Updated'
        => 'Le Message de Bienvenue a été mis à jour',

    'Yes' => 'Oui',

    'You have [_1] duplicate to resolve.'
        => 'Vous avez [quant,_1,doublon,doublons] à résoudre.',

    'You have entered an Invalid Date of birth'
        => "La date de naissance entrée n'est pas valide",

    'Zone' => 'Zone',
    'Zones' => 'Zones',


    '[_1] updated successfully' => '[_1] a été a mis à jour avec succès',

    'An invalid Action Code has been passed to me.'
        => 'Une action Code non valide a été effectuée.',

    'Database Home' => 'Accueil de la base de données',
    'Menu'          => 'Menu',
    'Event Options' => "Options de l'événement",
    'Edit Event'    => 'Modifier un événement',

    'Configure Event Details'
        => "Configurez les détails de l'événement",

    'Bulk Printing'        => 'Impression en vrac',

    'Accreditation'             => 'Accréditation',
    'Add new record'            => 'Ajouter nouvelle donnée',
    'None Available'            => 'Aucun disponible',
    'Sort Order'                => 'Ordre de tri',
    'Other Code'                => 'Autre code',
    'Male'                      => 'Homme',
    'Female'                    => 'Femme',
    'Mixed'                     => 'Mixte',
    'None Specified'            => 'Non indiqué',
    'Ask for Photo?'          => 'Demander pour la photo',
    'Name (or part of)'      => 'Nom (ou partie)',
    'Organisation'           => 'Organisation',
    'Accreditation Category' => "Catégorie d'accréditation",

    'Fill in the appropriate filter boxes below to search.'
        => 'Remplissez les cases appropriées ci-dessous pour ' .
           'filtrer la recherche.',

    'Personal Details'          => 'Informations personnelles',
    'Contact Details'           => 'Coordonnées',
    'Identifications'           => 'Identifications',
    'Parent/Guardian'           => 'Parent/Tuteur',
    'Medical'                   => 'Médical',
    'Other Fields'              => 'Autres domaines',
    'Click to Open/Close Group' => 'Cliquez pour ouvrir/fermer le groupe',
    'Filter Only'               => 'Filtre uniquement',
    'Run Report'                => 'Exécuter un rapport',
    'Unique Records Only'       => 'Données uniques seulement',
    'Summary Data'              => 'Résumé des données',
    'All Records'               => 'Tous les dossiers',
    'Options'                   => 'Options',
    'Show'                      => 'Montrer',
    'Sort By'                   => 'Trier par',
    'Secondary Sort By'         => 'Tri secondaire par',
    'Ascending'                 => 'Ascendant',
    'Descending'                => 'Descendant',
    'None'                      => 'Aucun',
    'Limit'                     => 'Limite',
    'No Limit'                  => 'Aucune limite',

    'Maximum no. of rows to display'
        => 'Nombre maximum de lignes à afficher',

    'Bulk Change' => 'Changement en vrac',

    'Select a Status to Assign'
        => 'Sélectionnez un statut à attribuer',

    'Assign Approval Statuses'       => 'Attribution des statuts approuvés',

    'This will assign the status to all matching records' =>
        "Cela affectera l'état de tous les enregistrements correspondants",

    'Select your report type below.'
        => 'Sélectionnez votre type de rapport ci-dessous',

    'Current Level'          => 'Niveau actuel',
    'Member Reports'         => 'Rapports du membre',
    'Member Summary Reports' => 'Résumé des rapports du membre',
    'Status Reports'         => 'Rapports des statuts',
    'Cards Printed'          => 'Cartes imprimées',

    'Member Sport Detail Reports'
        => 'Rapports des détails sportifs du membre',

    'No Results could be found' => "Aucun résultat n'a pu être trouvé",
    'Member Events Summary'     => 'Résumé des évènements du membre',
    'Edit Member'               => 'Modifier membres',
    'Mark as Duplicate'         => 'Marquer comme en double',
    'Mark Member as Duplicate'  => 'Marquer membre comme un doublon',
    'Delete Member'             => 'Supprimer membres',

    'Are you sure you want to Delete this Member'
        => 'Etes-vous sûr de vouloir supprimer ce membre',

    'Photo'                 => 'Photo',
    'Replace Photo'         => 'Remplacer photo',
    'Delete Photo'          => 'Supprimer la photo',
    'Add Photo'             => 'Ajouter une photo',
    'No Photo Found'        => 'Aucune photo trouvée',
    'Edit Personal Details' => 'Modifier les détails personnels',

    'Choose the options below to set up your event' =>
        'Choisissez les options ci-dessous pour configurer votre ' .
        'événement :',

    'Venue'         => 'Site',
    'Venues'        => 'Sites',
    'Zone'          => 'Zone',
    'Zones'         => 'Zones',
    'Venue Name'             => 'Nom du site',
    'Venue Code'             => 'Code du site',
    'Zone Name'              => 'Nom de la zone',
    'Zone Code'              => 'Code de la zone',

    'Choose'                     => 'Choisissez',
    'Generic (Tab Delimited)'
        => 'Générique (délimité par des tabulations)',

    'Member Number'        => 'Numéro de membre',
    'Middle Name'          => 'Deuxième prénom',
    'Surname'              => 'Nom de Famille',
    'Maiden Name'          => 'Nom de jeune fille',
    'Home Phone'           => 'Téléphone à la maison',
    'Work Phone'           => 'Téléphone au travail',
    'Mobile Phone'         => 'Téléphone portable',
    'Pager'                => 'Téléavertisseur',
    'Place of Birth'       => 'Lieu de naissance',
    'Passport Nationality' => 'Nationalité Passeport',
    'Passport Number'      => 'Numéro de passeport',
    'Selected by'          => 'Choisis par',

    'Invalid or Blank Email Address' => 'Blancs ou Nuls Adresse Email',
    'Unknown export format'          => "Format d'exportation Inconnue",

    'Error Sending Mail'
        => 'Erreur envoi de courrier électronique',

    'No Data to Export'        => "Aucune donnée à l'exportation",
    'System ID'                => "Numéro d'identification du système",
    'Event Number'             => "Numéro d'événement",
    'Arrival Date'             => "Date d'arrivée",
    'Departure Date'           => 'Date de départ',

    'Search for Person'       => 'Recherche de personne',
    'Invalid number'          => 'Nombre incorrect',
    'You must enter a number' => 'Vous devez entrer un numéro',
    'Problem updating status' => 'Problème mise à jour le statut',
    'Status Updated'          => 'Statut mis à jour',

    'View Types'                       => 'Voir les types',
    'Edit Details'               => 'Modifier les détails',

    'Upload Photo'  => 'Envoyer la photo',
    'Upload Photos' => 'Télécharger des photos',
    'Uploading'     => 'Téléchargé',

    'The estimated time to upload a 400Kb image is'
        => 'Le temps estimé pour télécharger une image 400Kb est',

    'Connection'                 => 'Connexion',
    'Approx. Time'               => 'Temps Approximatif',
    'Cable'                      => 'Câble',
    'minutes'                    => 'minutes',
    'Under 1 minute'             => 'Moins de 1 minute',
    'Please be Patient'          => "S'il vous plaît être patient",
    'on your Accreditation pass' => 'sur votre accréditation passer',
    'Save'                       => 'Enregistrer',
    'Preview'                    => 'Aperçu',
    'Modify Photo'               => 'Modifier Photo',
    'Original Photo'             => 'Photo Originale',
    'Rotate Left 90 degrees'     => 'Tourner à gauche à 90 degrés',
    'Rotate Right 90 degrees'    => 'Tourner à droite à 90 degrés',
    'Clubs'                      => 'Clubs',
    'Association Season Summary' => 'Résumé de la saison Association',
    'Club Season Summary'        => 'Résumé Saison Club',
    'Full Season Summary'        => 'Résumé de la saison complète',

    'Association Season Member Package'
        => "Paquet membres de l'Association saison",

    'No'                 => 'Non',
    'Area of Expertise'  => "Domaine d'expertise",
    'Update Member'      => "Mise à jour Membre",
    'Resolve Duplicates' => 'Résoudre les Doublons',

    'To resolve this duplicate click'
        => 'Pour résoudre ce double exemplaire cliquez sur',

    'Member marked as a duplicate' => 'Membre marqué comme duplicata',

    'Member has been marked as a duplicate'
        => 'Ce membre a été marqué comme duplicata',

    'Accreditation Bulk Print' => "Impression en vrac d'accréditation",
    'Any Category'             => 'Toute Catégorie',
    'Any (or No) Sport'        => 'Tous les Sports (ou pas)',
    'Any Organisation'         => 'Toute Organisation',

    'Choose what you want to bulk print from the options below.'
        => 'Choisissez ce que vous souhaitez imprimer en vrac à partir ' .
           'des options ci-dessous.',

    'All the filters are additive.' => 'Tous les filtres sont additifs.',
    'Generate Bulk Print'           => 'Imprimer Générer vrac',
    'Copy'                          => 'Copier',
    'Copy Event Details'            => "Copier les détails de l'évènement",
    'Information to copy'           => 'Information à copier',
    'Test approval'                 => 'Approbation du test',

    'Update status required for pass printing' =>
        "Mettre à jour les statuts requis l'impression d'une accréditation",

    'Quick Link to record' => 'Lien rapide pour enregistrer',

    'Photo Present?'            => 'Photo inclues?',
    'Group By'                  => 'Groupe par',
    'No Grouping'               => 'Pas de regroupement',
    'Report Output'             => 'Rapport de sortie',
    'Display'                   => 'Affichage',
    'Normal (Tab Delimited)'    => 'Normal (délimité par des tabulations)',
    'Saved Report'         => 'Rappeler rapport',
    'Saved Reports'        => 'Rapports rappeler',
    'Save Report as'        => 'Rappelez-vous le rapport comme',
    'Field'                     => 'Domaine',
    'Filter'                    => 'Filtre',
    'Passport Expiry'           => "Date d'expiration du passeport",

    'Address 1'                 => 'Adresse 1',
    'Address 2'                 => 'Adresse 2',

    'Is Blank'                  => 'Vide',
    'Is Not Blank'              => 'Pas Vide',
    'Equals'                    => 'Egal',
    'Not Equals'                => 'Pas Égal',
    'Like'                      => 'Ressemble',
    'Less Than'                 => 'Moins Que',
    'More Than'                 => 'Plus Que',
    'Between'                   => 'Entre',

    'Showing'                   => 'Monter',

    'Default'                   => 'Par défaut',
    'Season'                    => 'Saison',
    'No Season'                 => 'Aucune saison',
    'All Seasons'               => 'Toutes saisons',
    'All Age Groups'            => 'Toutes les catégories d’âge',
    'No Age Group'              => 'Aucune catégorie d’âge',

    'Association Status'        => "Statut de l’association",
    'All'                       => 'Tous',

    'Rollover'                  => 'Remaniement',
    'Show Members for Rollover' => 'Montrer les membres pour un remaniement',
    'To Season'                 => 'Prendre en compte la saison',

    'Include All records in Rollover'
        => 'Inclus tous les rapports dans le remaniement',

    'Include Club Records in Rollover'
        => 'Inclus les rapports des clubs dans le remaniement',

    'Make selected members Active in Association during Rollover' =>
        'Sélectionner les members actifs en association pendant le ' .
        'remaniement',


































    'NO_BODY '=>  <<"EOS",
Attention, cela ne devrait pas se produire. Merci de contacter
<a href="mailto:info\@sportingpulse.com">info\@sportingpulse.com</a>
EOS

    'CHOOSE_AND_REPORT' => <<"EOS",
Choisissez les champs que vous voulez sur votre rapport et les filtres que
vous souhaitez appliquer. Lorsque complété, cliquez sur le bouton "[_1]".

EOS

    'UPLOAD_PHOTO_FORM_TEXT' => <<"EOS",
<p>
  <b>Les photos doivent généralement se conformer à ce qui suit:</b>
</p>
<ul>
  <li>Bien celle du demandeur</li>
  <li>Vue de face de la tête de la requérante et les épaules</li>
  <li>Aucun des chapeaux ou des lunettes de soleil</li>
  <li>Pris sur un fond blanc</li>
  <li>Moins de 6 mois</li>
</ul>
<p>
  Pour ajouter une photo, cliquez sur le bouton Parcourir et trouvez l'image
  que vous souhaitez télécharger à partir de votre ordinateur. Lorsque vous
  avez sélectionné le fichier cliquez sur le "[_1]" bouton.
</p>
<p>
  Les photos doivent être en format JPEG (jpg) et à moins de 3 Mo..
</p>
EOS

    'MODIFY_PHOTO_FORM_HEADER' => <<"EOS",
<p>
  Recadrage de la photo en faisant glisser le rectangle comme l'exige.
  L'aperçu montre comment votre photo sera affichée[_1].
</p>
<p>
  Lorsque vous avez terminé les modifications, cliquez sur le bouton '[_2]'
  ci-dessous.
</p>
EOS

    'MARK_AS_DUPLICATE_INSTRUCTIONS' => <<"EOS",
<p>
  Si vous croyez que le [_1] désigné ci-dessous est un double possible,
  cliquez sur le <b>'[_3]'</b> bouton.
</p>
<p>
  Ce sera cette [_1] comme un duplicata de votre [_2] à vérifier et à
  résoudre.
</p>
EOS

    'MARK_AS_DUPLICATE_WARNING' => <<"EOS",
NOTER: Seuls marquer le [_1] supplémentaire, pas le [_1] vous croyez
peut-être l'original
EOS

    'BULK_PRINT_BUTTON_INFO' => <<"EOS",
Appuyez sur la <b> '[_1]' </b> bouton pour générer une liste de passages à
imprimer.
EOS

    'ENTER_USER_PASSWORD' => <<"EOS",
Merci d'entrer vos nom d'utilisateur et mot de passe ci-dessous et d'appuyer
sur le bouton '[_1]'.
EOS

    'CHOOSE_HOW_REPORTS' => <<"EOS",
Choisissez comment vous souhaitez recevoir les données de ce rapport.
EOS

    'DISPLAY_REPORT' => <<"EOS",
Ouvrez l'état pour l'affichage sur l'écran.
EOS

    'EMAIL_REPORT' => <<"EOS",
E-mail du rapport dans un format adapté à être importé dans un autre
produit.
EOS

    'CHOOSE_EXPORT_FORMAT' => <<"EOS",
Choisissez le format d'exportation que vous souhaitez utiliser
EOS

    'EXPORT_WARNING' => <<"EOS",
Cette option a un ensemble déterminé de domaines qu'elle exporte, mais les
filtres sont appliqués.
EOS

    'ROLLOVER_INSTRUCTIONS' => <<"EOS",
<p>
  Sélectionnez la saison dans laquelle vous désirez enregistrer les joueurs
  sélectionnés et ensuite cliquez sur le bouton « [_1]. »  Vous pourrez
  alors sélectionner ou désélectionner les membres que vous voulez
  enregistrer.
</p>
EOS

);


sub getNumberOf {
    my $levelName = $_[1];
    # currently only catering for accented E
    $levelName =~ s/É/E/g;
    my $result = 'Nombre ';
    $result .= (substr($levelName, 0, 1) !~ /[~AEIOUH]/)
        ? 'de '
        : qq[d'];
    $result .= $_[1];
    return $result; 
}


sub getSearchingFrom {
    my $levelName = $_[1];
    # currently only catering for accented E
    $levelName =~ s/É/E/g;
    my $result = 'Recherche ';
    $result .= (substr($levelName, 0, 1) =~ /[~AEIOUH]/)
        ? qq[de l']
        : 'de la ';
    $result .= $_[1] . ' vers le bas';
    return $result; 
}

1;
