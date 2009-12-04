use inc::Module::Install;
name 'DBIx-Skinny-AR';
all_from 'lib/DBIx/Skinny/AR.pm';

requires '';

author_tests('xt');

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
