use ExtUtils::MakeMaker;
WriteMakefile(
	      NAME => 'Text::Template',
	      VERSION => '1.20',
#	      'linkext' => {LINKTYPE => ''},
	      'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
);
