use ExtUtils::MakeMaker;
WriteMakefile(
	      NAME => 'Text::Template',
	      VERSION_FROM => 'Template.pm',
#	      'linkext' => {LINKTYPE => ''},
	      'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
);
