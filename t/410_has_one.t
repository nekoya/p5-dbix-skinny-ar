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

__PACKAGE__->has_one('pseudonym');

package main;

{
    my $lisa = Mock::Author->find({ name => 'Lisa' });
    ok my $pseudo = $lisa->pseudonym, 'get related object';
    isa_ok $pseudo, 'Mock::Pseudonym';
    is $pseudo->name, 'Miyako', 'assert pseudonym name';
}

{
    my $mike = Mock::Author->find({ name => 'Mike' });
    is $mike->pseudonym, undef, 'related object not found';
}
