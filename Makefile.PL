use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => 'Opcode',
    VERSION_FROM => 'Opcode.pm',
    # MAN3PODS 	=> ' ', 	# uncomment once back in perl distribution
	clean => { FILES=> '$(DISTVNAME)/' },
    dist  => { DIST_DEFAULT=> 'clean distcheck disttest ci tardist',
                PREOP => '$(MAKE) -f Makefile.old distdir' },
);
