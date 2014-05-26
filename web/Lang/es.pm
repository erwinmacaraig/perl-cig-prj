#
# $Header: svn://svn/SWM/trunk/web/Lang/es.pm 8251 2013-04-08 09:00:53Z rlee $
#

package Lang::es;
use base qw(Lang);
use strict;
use vars qw(%Lexicon);
%Lexicon = (
"We are making it easier to access your SP products with a single email and password, your" => "Estamos haciendo más fácil su acceso a todos los productos SP con una sola cuenta de email y contrasey se llamará SP",
"This gives you:" => "Esto le da:",
"A single login for all SP products, especially handy if you juggle multiple username / passwords in" => "Una sola cuenta de ingreso a todos los productos SP, especialmente si usted utiliza ,uchos uuarios diferentes de",
"Better auditing of database updates" => "Mejor control de actualizaciones de su Base de Datos",
"Better communications from SP on product updates" => "Mejores comunicaciones de SP sobre actualizaciones del producto",
"Access SP Membership at any time with a single click from the global navigation" => "El acceso a la Membresía SP en cualquier momento con un solo click desde la navegación global",
"Register/Sign in with" => "Ingrese con",
"Don't have a" => "¿No tiene S",
"No problems, just click Register to create one and gain access to your"=>" No hay problema, solo tiene que hacer click en Registrarse para crear y acceder a su base de datos de",



"you will be able to login by clicking on it above."=>"usted seráapaz de iniciar sesióaciendo clic en éanteriormente.",
"If you have not linked your account please enter your"=>"Si no ha asociado su cuenta, por favor ingrese su nombre de usuario y contraseñe",
"username and password below to link that account to your"=>"abajo para vincular esa cuenta a su",



"Password" => "Contraseña",
"Link Account" => "Conectar a cuenta.",
"Username" =>"Nombre de Usuario",
"Select the"=>"Seleccione la",
"If you have already linked your"=>"Si ya ha conectado su",
"SP Membership"=>"Membresía SP ",
"SP Passport"=>"Pasaporte SP",
"account you would like to access from the list below or link another to your"=>"le gustarÃso a la lista de abajo o enlazar otro a tu",
"via the form at the bottom of this page."=>"a través del formulario en la parte inferior de esta página.",
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

