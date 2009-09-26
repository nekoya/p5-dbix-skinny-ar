#BEGIN { $ENV{'ANY_MOOSE'} = 'Moose' }
use lib './t';
use FindBin::libs;
use Test::More 'no_plan';
use Test::Exception;
use Data::Dumper;
use Perl6::Say;

use Mock::Gender;

BEGIN { Mock::DB->setup_test_db }
END   { unlink './t/main.db' }

package Mock::Gender;

__PACKAGE__->has_one(
    'author' => {
        target_key   => 'gender_name',
    }
);

package main;

{
    my $female = Mock::Gender->find({ name => 'female' });
    ok my $member = $female->author, 'get related object';
    isa_ok $member, 'Mock::Author';
    is $member->name, 'Lisa', 'assert member name';
}
