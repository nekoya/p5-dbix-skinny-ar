#BEGIN { $ENV{'ANY_MOOSE'} = 'Moose' }
use lib './t';
use FindBin::libs;
use Test::More 'no_plan';
use Test::Exception;
use Data::Dumper;
use Perl6::Say;

use Mock::Author;

BEGIN { Mock::DB->setup_test_db }
END   { unlink './t/main.db' }

package Mock::Author;

__PACKAGE__->belongs_to(
    'gender' => {
        self_key     => 'gender_name',
    }
);

package main;

{
    my $author = Mock::Author->find({ name => 'mike' });
    isnt $author->can('gender_name'), 1, 'author cannot call gender_name';
    isnt $author->can('gender'), 1, 'author cannot call gender';
    my $gender = $author->gender, 'get related object';
    isa_ok $gender, 'Mock::Gender';
    is $gender->name, 'male', 'assert gender name';
}
