use ExtUtils::MakeMaker;
WriteMakefile(
	      NAME => 'Text::Template',
	      VERSION => '0.1a',
	      'linkext' => {LINKTYPE => ''},
	      'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
);
