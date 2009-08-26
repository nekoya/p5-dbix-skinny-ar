use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DBIx::Skinny::AR',
    AUTHOR              => 'Ryo Miyake <ryo.studiom@gmail.com>',
    VERSION_FROM        => 'lib/DBIx/Skinny/AR.pm',
    ABSTRACT_FROM       => 'lib/DBIx/Skinny/AR.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DBIx-Skinny-AR-*' },
);
