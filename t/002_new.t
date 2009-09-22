use lib './t';
use FindBin::libs;
use Test::More tests => 1;
use Mock::Language;

{
    my $model = Mock::Language->new;
    isa_ok $model, 'Mock::Language';
}
