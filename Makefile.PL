use ExtUtils::MakeMaker;
WriteMakefile(
	      NAME => 'Text::Template',
	      VERSION => '1.03',
#	      'linkext' => {LINKTYPE => ''},
	      'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
);
