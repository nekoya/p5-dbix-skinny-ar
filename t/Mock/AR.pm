package Mock::AR;
use Any::Moose;
extends 'DBIx::Skinny::AR';

__PACKAGE__->setup({
    db => 'Mock::Basic',
    validator => {
        module  => 'FormValidator::Simple',
        plugins => [ 'FormValidator::Simple::Plugin::DBIC::Unique' ],
    },
});

1;
