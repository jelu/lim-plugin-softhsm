package Lim::Plugin::SoftHSM::Server;

use common::sense;

use Fcntl qw(:seek);
use File::Temp ();
use IO::File ();
use Digest::SHA ();
use AnyEvent ();
use AnyEvent::Util ();
use Scalar::Util qw(weaken);

use Lim::Plugin::SoftHSM ();

use Lim::Util ();

use base qw(Lim::Component::Server);

=head1 NAME

...

=head1 VERSION

Version 0.1

=cut

our $VERSION = $Lim::Plugin::SoftHSM::VERSION;
our %ConfigFiles = (
    'softhsm.conf' => [
        '/etc/softhsm/softhsm.conf',
        '/etc/softhsm.conf',
        'softhsm.conf'
    ]
);

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub Init {
    my $self = shift;
    my %args = ( @_ );
    
    $self->{config} = {};
}

=head2 function1

=cut

sub Destroy {
}

=head2 function1

=cut

sub _ScanConfig {
    my ($self) = @_;
    my %file;
    
    foreach my $config (keys %ConfigFiles) {
        foreach my $file (@{$ConfigFiles{$config}}) {
            if (defined ($file = Lim::Util::FileWritable($file))) {
                if (exists $file{$file}) {
                    $file{$file}->{write} = 1;
                    next;
                }
                
                $file{$file} = {
                    name => $file,
                    write => 1,
                    read => 1
                };
            }
            elsif (defined ($file = Lim::Util::FileReadable($file))) {
                if (exists $file{$file}) {
                    next;
                }
                
                $file{$file} = {
                    name => $file,
                    write => 0,
                    read => 1
                };
            }
        }
    }
    
    return \%file;
}

=head2 function1

=cut

sub ReadConfigs {
    my ($self, $cb) = @_;
    my $files = $self->_ScanConfig;
    
    $self->Successful($cb, {
        file => [ values %$files ]
    });
}

=head2 function1

=cut

sub CreateConfig {
    my ($self, $cb) = @_;
    
    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub ReadConfig {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig;
    my $result = {};

    if (exists $q->{file}) {
        foreach my $read (ref($q->{file}) eq 'ARRAY' ? @{$q->{file}} : $q->{file}) {
            if (exists $files->{$read->{name}}) {
                my $file = $files->{$read->{name}};
                
                if ($file->{read} and defined (my $fh = IO::File->new($file->{name}))) {
                    my ($tell, $content);
                    $fh->seek(0, SEEK_END);
                    $tell = $fh->tell;
                    $fh->seek(0, SEEK_SET);
                    if ($fh->read($content, $tell) == $tell) {
                        if (exists $result->{file}) {
                            unless (ref($result->{file}) eq 'ARRAY') {
                                $result->{file} = [ $result->{file} ];
                            }
                            push(@{$result->{file}}, {
                                name => $file->{name},
                                content => $content
                            });
                        }
                        else {
                            $result->{file} = {
                                name => $file->{name},
                                content => $content
                            };
                        }
                    }
                }
            }
            else {
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'File "'.$read->{name}.'" not found in configuration files'
                ));
                return;
            }
        }
    }
    $self->Successful($cb, $result);
}

=head2 function1

=cut

sub UpdateConfig {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig;
    my $result = {};

    if (exists $q->{file}) {
        foreach my $read (ref($q->{file}) eq 'ARRAY' ? @{$q->{file}} : $q->{file}) {
            if (exists $files->{$read->{name}}) {
                my $file = $files->{$read->{name}};

                if ($file->{write} and defined (my $tmp = File::Temp->new)) {
                    print $tmp $read->{content};
                    $tmp->flush;
                    $tmp->close;
                    
                    my $fh = IO::File->new;
                    if ($fh->open($tmp->filename)) {
                        my ($tell, $content);
                        $fh->seek(0, SEEK_END);
                        $tell = $fh->tell;
                        $fh->seek(0, SEEK_SET);
                        unless ($fh->read($content, $tell) == $tell) {
                            $self->Error($cb, Lim::Error->new(
                                code => 500,
                                message => 'Failed to write "'.$read->{name}.'" to temporary file'
                            ));
                            return;
                        }
                        unless (Digest::SHA::sha1_base64($read->{content}) eq Digest::SHA::sha1_base64($content)) {
                            $self->Error($cb, Lim::Error->new(
                                code => 500,
                                message => 'Checksum missmatch on "'.$read->{name}.'" after writing to temporary file'
                            ));
                            return;
                        }
                        unless (rename($tmp->filename, $file->{name}))
                        {
                            $self->Error($cb, Lim::Error->new(
                                code => 500,
                                message => 'Failed to rename "'.$read->{name}.'"'
                            ));
                            return;
                        }
                    }
                }
            }
            else {
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'File "'.$read->{name}.'" not found in configuration files'
                ));
                return;
            }
        }
    }
    $self->Successful($cb);
}

=head2 function1

=cut

sub DeleteConfig {
    my ($self, $cb) = @_;
    
    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub ReadShowSlots {
    my ($self, $cb) = @_;
    
    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub CreateInitToken {
    my ($self, $cb, $q) = @_;
    
    if (exists $q->{token}) {
        my @tokens = ref($q->{token}) eq 'ARRAY' ? @{$q->{token}} : ($q->{token});
        if (scalar @tokens) {
            weaken($self);
            my $cmd_cb; $cmd_cb = sub {
                if (my $token = shift(@tokens)) {
                    my ($stdout, $stderr);
                    # TODO check input, handle optional --options
                    my $cv = AnyEvent::Util::run_cmd
                        [
                            'softhsm',
                            '--init-token',
                            '--slot', $token->{slot},
                            '--label', $token->{label},
                            '--so-pin', $token->{so_pin},
                            '--pin', $token->{pin}
                        ],
                        '<', '/dev/null',
                        '>', \$stdout,
                        '2>', \$stderr;
                    $cv->cb (sub {
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to create token ', $token->{label});
                            return;
                        }
                        $cmd_cb->();
                    });
                }
                else {
                    $self->Successful($cb);
                }
            };
            $cmd_cb->();
            return;
        }
    }
    $self->Successful($cb);
}

=head2 function1

=cut

sub CreateImport {
    my ($self, $cb) = @_;
    
    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub ReadExport {
    my ($self, $cb) = @_;
    
    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub UpdateOptimize {
    my ($self, $cb) = @_;
    
    $self->Error($cb, 'Not Implemented');
}

=head2 function1

=cut

sub UpdateTrusted {
    my ($self, $cb) = @_;
    
    $self->Error($cb, 'Not Implemented');
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

1; # End of Lim::Plugin::SoftHSM::Server
