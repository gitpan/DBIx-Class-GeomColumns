package DBIx::Class::GeomColumns;
use strict;
use warnings;
use Carp;

use version; our $VERSION = qv('0.0.1');
use base qw/DBIx::Class/;

__PACKAGE__->mk_classdata( '_geom_columns' );

=head1 NAME

DBIx::Class::GeomColumns - Filter of geometry columns to access with WKT

=head1 SYNOPSIS

    package POI;
    __PACKAGE__->load_components(qw/GeomColumns Core/);
    __PACKAGE__->utf8_columns('wgs84_col',{'tokyo_col' => 4301});
    
    # then belows return the result of 'AsText(wgs84_col)'
    $poi->wgs84_col;

    # You can also create or update 'GeomFromText($data,$srid)';
    # below example is insert 'GeomFromText('POINT(135 35)',4301)'
    $poi->tokyo_col('POINT(135 35)');
    $poi->update;

=head1 DESCRIPTION

This module allows you to access geometry columns by WKT format.

=head1 SEE ALSO

L<Template::Stash::UTF8Columns>.

=head1 METHODS

=head2 geom_columns

=cut

sub geom_columns {
    my $self = shift;
    if (@_) {
        my %args;
        foreach my $elm (@_) {
            my $ref = ref($elm) ? $elm : { $elm => 4326 };
            foreach my $col ( keys %$ref ) {
                $self->throw_exception("column $col doesn't exist")
                    unless $self->has_column($col);
            }
            %args = ( %args, %$ref );
        }        
        my @keys = keys %args;

        $self->resultset_attributes(
            {
                '+select' => [ map { { 'AsText' => "me.$_" } } @keys ], 
                '+as'     => \@keys,
            }
        );

        return $self->_geom_columns({ map { $_ => $args{$_} } @keys });
    } else {
        return $self->_geom_columns;
    }
}

=head1 EXTENDED METHODS

=head2 store_column

=cut

sub store_column {
    my ( $self, $column, $value ) = @_;

    my $cols = $self->_geom_columns;
    if ( $cols and defined $value and my $srid = $cols->{$column} ) {
        $value = \"GeomFromText('$value',$srid)";
    }

    $self->next::method( $column, $value );
}

=head1 AUTHOR

OHTSUKA Ko-hei <nene@kokogiko.net>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;

