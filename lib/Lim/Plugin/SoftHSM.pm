package Lim::Plugin::SoftHSM;

use common::sense;
use Carp;

use Log::Log4perl ();
use Fcntl qw(:seek);

use base qw(Lim::Component);

=head1 NAME

...

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS


=head2 function1

=cut

sub Module {
    'SoftHSM';
}

=head2 function1

=cut

sub Calls {
    {
        ReadVersion => {
            out => {
                version => 'string',
                program => {
                    name => 'string',
                    version => 'string'
                }
            }
        },
        #
        # Calls for config files
        #
        ReadConfigs => {
            out => {
                file => {
                    name => 'string',
                    write => 'integer',
                    read => 'integer'
                }
            }
        },
        CreateConfig => {
            in => {
                file => {
                    '' => 'required',
                    name => 'string',
                    content => 'string'
                }
            }
        },
        ReadConfig => {
            in => {
                file => {
                    '' => 'required',
                    name => 'string'
                }
            },
            out => {
                file => {
                    name => 'string',
                    content => 'string'
                }
            }
        },
        UpdateConfig => {
            in => {
                file => {
                    '' => 'required',
                    name => 'string',
                    content => 'string'
                }
            }
        },
        DeleteConfig => {
            in => {
                file => {
                    '' => 'required',
                    name => 'string'
                }
            }
        },
        #
        # Calls for softhsm executable tool
        #
        ReadShowSlots => {
            out => {
                slot => {
                    id => 'integer',
                    token_label => 'string',
                    token_present => 'bool',
                    token_initialized => 'bool',
                    user_pin_initialized => 'bool',
                }
            }
        },
        CreateInitToken => {
            in => {
                token => {
                    '' => 'required',
                    slot => 'integer',
                    label => 'string',
                    so_pin => 'string',
                    pin => 'string'
                }
            }
        },
        CreateImport => {
            in => {
                key_pair => {
                    '' => 'required',
                    file_pin => 'string',
                    slot => 'integer',
                    pin => 'string',
                    label => 'string',
                    id => 'string'
                }
            }
        },
        ReadExport => {
            in => {
                key_pair => {
                    '' => 'required',
                    file_pin => 'string',
                    slot => 'integer',
                    pin => 'string',
                    id => 'string'
                }
            },
            out => {
                key_pair => {
                }
            }
        },
        UpdateOptimize => {
            in => {
                slot => {
                    '' => 'required',
                    slot => 'integer',
                    pin => 'string'
                }
            }
        },
        UpdateTrusted => {
            in => {
                key_pair => {
                    '' => 'required',
                    trusted => 'bool',
                    slot => 'integer',
                    so_pin => 'string',
                    type => 'string',
                    label => 'string',
                    id => 'string'
                }
            }
        }
    };
}

=head2 function1

=cut

sub Commands {
    {
        version => 1,
        configs => 1,
        config => {
            view => 1,
            edit => 1
        },
        show => {
            slots => 1
        },
        init => {
            token => 1
        }
    };
}

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lim at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lim>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lim>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lim>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lim>

=item * Search CPAN

L<http://search.cpan.org/dist/Lim/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::Plugin::SoftHSM
