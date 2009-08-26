use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DBIx::Skinny::AR',
    license             => 'perl',
    dist_author         => 'Ryo Miyake <ryo.studiom@gmail.com>',
    dist_version_from   => 'lib/DBIx/Skinny/AR.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'DBIx-Skinny-AR-*' ],
);

$builder->create_build_script();
