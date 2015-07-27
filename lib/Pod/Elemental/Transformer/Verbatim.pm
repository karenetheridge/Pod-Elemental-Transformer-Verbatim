use strict;
use warnings;
package Pod::Elemental::Transformer::Verbatim;
# ABSTRACT: Transform :verbatim regions into verbatim paragraphs
# KEYWORDS: pod transformer verbatim literal indent code text
# vim: set ts=8 sts=4 sw=4 tw=115 et :

our $VERSION = '0.001';

use Moose;
with 'Pod::Elemental::Transformer' => { -version => '0.101620' };

use Pod::Elemental::Types 'FormatName';
use Pod::Elemental::Element::Pod5::Verbatim;
use namespace::autoclean;

has format_name => (
    is  => 'ro',
    isa => FormatName,
    default => 'verbatim',
);

sub transform_node
{
    my ($self, $node) = @_;

    # why do we process in reverse? it should make no difference
    for my $i (reverse(0 .. $#{ $node->children })) {
        my $para = $node->children->[ $i ];
        next unless $self->__is_xformable($para);
        my @replacements = $self->_make_verbatim( $para );
        splice @{ $node->children }, $i, 1, @replacements;
    }

    return $node;
}

sub _make_verbatim
{
    my ($self, $parent) = @_;

    # TODO: we can make this nicer with a simple map.
    my @replacements;

    PARA: for my $para (@{ $parent->children }) {
        unless ($para->isa('Pod::Elemental::Element::Pod5::Ordinary')) {
            push @replacements, $self->__is_xformable($para)
                ? $self->_make_verbatim($para)
                : $para;

            next PARA;
        }

        if (length $para->content)
        {
            push @replacements, Pod::Elemental::Element::Pod5::Verbatim->new({
                content => join("\n", map { '    ' . $_ } split(/\n/, $para->content)),
              });
        }
    }

    return @replacements;
}

# from ::List
sub __is_xformable
{
    my ($self, $para) = @_;

    return unless $para->isa('Pod::Elemental::Element::Pod5::Region')
        and $para->format_name eq $self->format_name;

    confess('verbatim regions must be pod (=begin :' . $self->format_name . ')')
        unless $para->is_pod;

    return 1;
}

1;
__END__

=pod

=head1 SYNOPSIS

In your F<weaver.ini>:

     [-Transformer / Verbatim]
     transformer = Verbatim

Or in a plugin bundle:

    sub mvp_bundle_config {
        return (
            ...
            [ '@Author::YOU/Verbatim', _exp('-Transformer'), { 'transformer' => 'Verbatim' } ],
        );
    }

=head1 DESCRIPTION

This module acts as a L<pod transformer|Pod::Elemental::Transformer>, using
C<:verbatim> regions to mark sections of text for treatment as if they were
verbatim paragraphs. The transformer indents the contained text by four
columns, allowing the pod parser to treat them properly; see
L<perlpod/"Verbatim Paragraph">.

That is, this pod:

    =begin :verbatim

    Here is some text.

    =end :verbatim

Is transformed to:

        Here is some text

Note that a single paragraph can be simply noted with C<=for :verbatim> rather
than using C<=begin :verbatim> and C<=end :verbatim> lines.

=attr format_name

This attribute (defaulting to C<verbatim>) is the region format that will be
processed by this transformer.

=method transform_node

Given a pod document object, returns the object with all its children with
C<:verbatim> directives removed and appropriate content replaced with
L<Pod::Elemental::Element::Pod5::Verbatim> objects.

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Elemental-Transformer-Verbatim>
(or L<bug-Pod-Elemental-Transformer-Verbatim@rt.cpan.org|mailto:bug-Pod-Elemental-Transformer-Verbatim@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=for :list
* L<Pod::Weaver>

=cut
