use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'Template::Perl',
    'VERSION_FROM' => 'Perl.pm', # finds $VERSION
    'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
);
