package tblEntityRegistrationAllowed;
require Exporter;
@ISA = qw(Exporter);


sub load{
    return {
      Gender => {
        "rule" => "multiplyEntry",
        "value" => 'ALL',
        "field" => 'Gender',
        "collection" => ['MALE','FEMALE']
      }
    };
}
