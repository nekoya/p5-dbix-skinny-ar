use lib './t';
use FindBin::libs;
use Test::More 'no_plan';
use Test::Exception;
use Mock::Language;
use Mock::Gender;

BEGIN { Mock::Basic->setup_test_db }
END   { unlink './t/main.db' }

{
    my $perl = Mock::Language->find({ name => 'perl' });
    ok $perl->name('php'), 'modified to unique name';
    throws_ok { $perl->name('ruby') }
        qr/^Attribute \(name\) does not pass the type constraint because: ruby is not a unique value./,
        'failed set not unique name';
}

{
    my $male = Mock::Gender->find({ name => 'male' });
    ok $male->name('female'), 'modified to allowed name';
    throws_ok { $male->name('man') }
        qr/^Attribute \(name\) does not pass the type constraint/,
        'failed set not allowed name';
}
