package DBIx::Skinny::AR;

use warnings;
use strict;
use Carp;

our $VERSION = '0.0.1';

use UNIVERSAL::require;

use Mouse;
extends 'Mouse::Object', 'Class::Data::Inheritable';

__PACKAGE__->mk_classdata('db');
__PACKAGE__->mk_classdata('validator' => {
    module  => 'FormValidator::Simple',
    plugins => [],
});

has 'row' => (
    is  => 'rw',
    isa => 'DBIx::Skinny::Row',
);

no Mouse;

sub table { croak 'implement table name' }
sub validation { croak 'implement validation rules' }
sub default_search_column { 'id' }

sub debug {
    my ($class, $debug) = @_;
    $class->db->attribute->{ profile } = $debug;
}

sub query_log {
    my $class = shift;
    $class->db->profiler->query_log(@_);
}

sub setup {
    my ($class, $args) = @_;

    croak "implement db name" unless $args->{ db };
    $args->{ db }->require or croak "failed to load " . $args->{ db };
    $class->db($args->{ db });

    my $validator = $args->{ validator };
    $validator->{ module } ||= $class->validator->{ module };
    $validator->{ module }->require;

    for my $plugin ( @{ $validator->{ plugins } } ) {
        $validator->{ module }->load_plugin($plugin);
    }
    $class->validator($validator);
}

sub mk_accessors {
    my ($class) = @_;
    my $cols = $class->db->schema->schema_info->{ $class->table }->{ columns };
    for my $col ( @$cols ) {
        next if $class->can($col);
        no strict 'refs';
        *{"$class\::$col"} = sub {
            my ($self, $val) = @_;
            return $self->row->$col unless defined $val;
            $self->row->set({ $col => $val });
        };
    }
}

sub get_where {
    my ($class, $where) = @_;
    return $where if ref $where eq 'HASH';
    return {} unless defined $where;
    return { $class->default_search_column => $where };
}

sub find {
    my ($class, $where, $opt) = @_;
    $where = $class->get_where($where);
    my $row = $class->db->single($class->table, $where, $opt) or return;
    my $self = $class->new({ row => $row });
    return $self;
}

sub find_all {
    my ($class, $where, $opt) = @_;
    $where = $class->get_where($where);
    my $rs = $class->db->search($class->table, $where, $opt);
    my @rows;
    while ( my $row = $rs->next ) {
        push @rows, $class->new({ row => $row });
    }
    return \@rows;
}

sub count {
    my ($class, $args) = @_;
    $class->db->count($class->table, 'id', $args);
}

sub validate {
    my ($self, $_args) = @_;
    my $class = ref $self || $self;
    my $args;
    if ( ref $self ) {
        $args = $self->row->get_columns;
        @$args{keys %$_args} = values %$_args if defined $_args;
    } else {
        $args = $_args or return;
    }
    my $validator = $class->validator->{ module };
    $validator->check($args => $class->validation);
}

sub create {
    my ($class, $args) = @_;
    my $result = $class->validate($args);
    croak $result if $result->has_error;
    my $row = $class->db->insert($class->table, $args);
    $class->new({ row => $row });
}

sub update {
    my $self = shift;
    my $method = '_update_' . (ref $self ? 'instance' : 'static');
    $self->$method(@_);
}

sub _update_instance {
    my ($self, $args) = @_;
    my $result = $self->validate($args);
    croak $result if $result->has_error;
    $self->row->update($args);
}

sub _update_static {
    my ($class, $args, $where) = @_;
    my $result = $class->validate($args);
    croak $result if $result->has_error;
    $class->db->update($class->table, $args, $where);
}

sub delete {
    my $self = shift;
    my $method = '_delete_' . (ref $self ? 'instance' : 'static');
    $self->$method(@_);
}

sub _delete_instance {
    my ($self) = @_;
    $self->row->delete;
}

sub _delete_static {
    my ($class, $where) = @_;
    croak 'delete needs where sentence' unless $where;
    $class->db->delete($class->table, $where);
}

sub belongs_to {
    my ($class, $method, $column, $target) = @_;
    croak 'belongs_to needs method name' unless $method;
    $target = $class->_prepare_target_class($method, $target);
    $column = $method . '_id' unless $column;
    {
        no strict 'refs';
        *{"$class\::$method"} = sub {
            my $self = shift or return;
            return unless $self->$column;
            my $related = $target->find({ id => $self->$column })
                or croak "related row was not found";
        }
    }
}

sub has_many {
    my ($class, $method, $column, $target) = @_;
    croak 'has_many needs method name' unless $method;
    $target = $class->_prepare_target_class($method, $target);
    $column = $method . '_id' unless $column;
    {
        no strict 'refs';
        *{"$class\::$method"} = sub {
            my $self = shift or return;
            return $target->find_all({ $column => $self->id });
        }
    }
}

sub _prepare_target_class {
    my ($self, $method, $target) = @_;
    my $class = ref $self || $self;
    unless ( $target ) {
        ($target = $class) =~ s/[^:]+$//;
        $target .= ucfirst $method;
    }
    $target->require or croak "cannot require $target";
    return $target;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

DBIx::Skinny::AR - [One line description of module's purpose here]


=head1 VERSION

This document describes DBIx::Skinny::AR version 0.0.1


=head1 SYNOPSIS

    use DBIx::Skinny::AR;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
DBIx::Skinny::AR requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-dbix-skinny-ar@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Ryo Miyake  C<< <ryo.studiom@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Ryo Miyake C<< <ryo.studiom@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
