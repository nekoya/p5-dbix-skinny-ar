package DBIx::Skinny::AR::Meta::Attribute::Trait::Unique;
use Any::Moose '::Role';

after 'install_accessors' => sub {
    my $self = shift;
    my $meta = $self->associated_class;
    for my $attr ( $meta->get_all_attributes ) {
        if ( $attr->does('DBIx::Skinny::AR::Meta::Attribute::Trait::Unique') ) {
            my $name = $attr->name;
            $meta->add_after_method_modifier(
                $name,
                sub {
                    my $self = shift;
                    $self->_chk_unique_value($name) if @_;
                }
            );
        }
    }
};

local $@;
my $code = "package " . any_moose . "::Meta::Attribute::Custom::Trait::Unique;\n".
           "sub register_implementation {'DBIx::Skinny::AR::Meta::Attribute::Trait::Unique'}";
eval $code; ## no critic
die $@ if $@;

1;
