package Lim::Plugin::SoftHSM::Server;

use common::sense;

use Fcntl qw(:seek);
use IO::File ();
use Digest::SHA ();
use Scalar::Util qw(weaken);

use Lim::Plugin::SoftHSM ();

use Lim::Util ();

use base qw(Lim::Component::Server);

=head1 NAME

...

=head1 VERSION

See L<Lim::Plugin::SoftHSM> for version.

=cut

our $VERSION = $Lim::Plugin::SoftHSM::VERSION;
our %ConfigFiles = (
    'softhsm.conf' => [
        '/etc/softhsm/softhsm.conf',
        '/etc/softhsm.conf',
        'softhsm.conf'
    ]
);

sub SOFTHSM_VERSION_MIN (){ 1003000 }
sub SOFTHSM_VERSION_MAX (){ 1003003 }

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub Init {
    my $self = shift;
    my %args = ( @_ );

    $self->{bin} = {
        softhsm => 0
    };
    $self->{version} = {};
    
    my ($stdout, $stderr);
    my $cv = Lim::Util::run_cmd [ 'softhsm', '--version' ],
        '<', '/dev/null',
        '>', \$stdout,
        '2>', \$stderr;
    if ($cv->recv) {
        $self->{logger}->warn('Unable to find "softhsm" executable, module functions limited');
    }
    else {
        if ($stdout =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)/o) {
            my ($major,$minor,$patch) = ($1, $2, $3);
            
            if ($major > 0 and $major < 10 and $minor > -1 and $minor < 10 and $patch > -1 and $patch < 100) {
                my $version = ($major * 1000000) + ($minor * 1000) + $patch;
                
                unless ($version >= SOFTHSM_VERSION_MIN and $version <= SOFTHSM_VERSION_MAX) {
                    $self->{logger}->warn('Unsupported "softhsm" executable version, unable to continue');
                }
                else {
                    $self->{bin}->{softhsm} = $version;
                    $self->{version}->{softhsm} = $major.'.'.$minor.'.'.$patch;
                }
            }
            else {
                $self->{logger}->warn('Invalid "softhsm" version, module functions limited');
            }
        }
        else {
            $self->{logger}->warn('Unable to get "softhsm" version, module functions limited');
        }
    }
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

sub ReadVersion {
    my ($self, $cb) = @_;
    my @program;
    
    if ($self->{version}->{softhsm}) {
        push(@program, { name => 'softhsm', version => $self->{version}->{softhsm} });
    }

    if (scalar @program) {
        $self->Successful($cb, { version => $VERSION, program => \@program });
    }
    else {
        $self->Successful($cb, { version => $VERSION });
    }
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

    foreach my $read (ref($q->{file}) eq 'ARRAY' ? @{$q->{file}} : $q->{file}) {
        unless (exists $files->{$read->{name}}) {
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'File "'.$read->{name}.'" not found in configuration files'
            ));
            return;
        }
    }
    
    foreach my $read (ref($q->{file}) eq 'ARRAY' ? @{$q->{file}} : $q->{file}) {
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
    $self->Successful($cb, $result);
}

=head2 function1

=cut

sub UpdateConfig {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig;
    my $result = {};

    foreach my $read (ref($q->{file}) eq 'ARRAY' ? @{$q->{file}} : $q->{file}) {
        unless (exists $files->{$read->{name}}) {
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'File "'.$read->{name}.'" not found in configuration files'
            ));
            return;
        }
    }

    foreach my $read (ref($q->{file}) eq 'ARRAY' ? @{$q->{file}} : $q->{file}) {
        my $file = $files->{$read->{name}};

        if ($file->{write} and defined (my $tmp = Lim::Util::TempFileLikeThis($file->{name}))) {
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
    
    unless ($self->{bin}->{softhsm}) {
        $self->Error($cb, 'No "softhsm" executable found or unsupported version, unable to continue');
        return;
    }
    
    my ($stderr, @slots, $slot, $data);
    Lim::Util::run_cmd
        [
            'softhsm',
            '--show-slots'
        ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $data .= $_[0];
                
                $cb->reset_timeout;
                
                while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                    my $line = $1;
                    
                    if ($line =~ /^Slot\s+([0-9]+)/o) {
                        if (defined $slot) {
                            push(@slots, $slot);
                        }
                        $slot = {
                            id => $1
                        };
                    }
                    elsif (!defined $slot) {
                        next;
                    }
                    elsif ($line =~ /Token\s+present:\s+(\w+)/o) {
                        if (lc($1) eq 'yes') {
                            $slot->{token_present} = 1;
                        }
                        else {
                            $slot->{token_present} = 0;
                        }
                    }
                    elsif ($line =~ /Token\s+initialized:\s+(\w+)/o) {
                        if (lc($1) eq 'yes') {
                            $slot->{token_initialized} = 1;
                        }
                        else {
                            $slot->{token_initialized} = 0;
                        }
                    }
                    elsif ($line =~ /User\s+PIN\s+initialized:\s+(\w+)/o) {
                        if (lc($1) eq 'yes') {
                            $slot->{user_pin_initialized} = 1;
                        }
                        else {
                            $slot->{user_pin_initialized} = 0;
                        }
                    }
                    elsif ($line =~ /Token\s+label:\s+(\w+)/o) {
                        # TODO spaces in token label??
                        $slot->{token_label} = $1;
                    }
                }
            }
        },
        '2>', \$stderr,
        timeout => 15,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to read slots');
            }
            else {
                if (defined $slot) {
                    push(@slots, $slot);
                }
                if (scalar @slots == 1) {
                    $self->Successful($cb, { slot => $slots[0] });
                }
                elsif (scalar @slots) {
                    $self->Successful($cb, { slot => \@slots });
                }
                else {
                    $self->Successful($cb);
                }
            }
        };
}

=head2 function1

=cut

sub CreateInitToken {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{softhsm}) {
        $self->Error($cb, 'No "softhsm" executable found or unsupported version, unable to continue');
        return;
    }
    
    my @tokens = ref($q->{token}) eq 'ARRAY' ? @{$q->{token}} : ($q->{token});
    if (scalar @tokens) {
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            if (my $token = shift(@tokens)) {
                my ($stdout, $stderr);
                unless (length($token->{so_pin}) >= 4 and length($token->{so_pin}) <= 255) {
                    $self->Error($cb, 'Unable to create token ', $token->{label}, ': so_pin not between 4 and 255 characters');
                    return;
                }
                unless (length($token->{pin}) >= 4 and length($token->{pin}) <= 255) {
                    $self->Error($cb, 'Unable to create token ', $token->{label}, ': pin not between 4 and 255 characters');
                    return;
                }
                Lim::Util::run_cmd
                    [
                        'softhsm',
                        '--init-token',
                        '--slot', $token->{slot},
                        '--label', $token->{label},
                        '--so-pin', $token->{so_pin},
                        '--pin', $token->{pin}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 10,
                    cb => sub {
                        unless (defined $self) {
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to create token ', $token->{label});
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                $self->Successful($cb);
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
        return;
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
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{softhsm}) {
        $self->Error($cb, 'No "softhsm" executable found or unsupported version, unable to continue');
        return;
    }
    
    my @slots = ref($q->{slot}) eq 'ARRAY' ? @{$q->{slot}} : ($q->{slot});

    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        if (my $slot = shift(@slots)) {
            my ($stdout, $stderr);
            Lim::Util::run_cmd
                [
                    'softhsm',
                    '--optimize',
                    '--slot', $slot->{id},
                    '--pin', $slot->{pin}
                ],
                '<', '/dev/null',
                '>', sub {
                    if (defined $_[0]) {
                        $cb->reset_timeout;
                        $stdout .= $_[0];
                    }
                },
                '2>', \$stderr,
                timeout => 10,
                cb => sub {
                    unless (defined $self) {
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to optimize softhsm');
                        return;
                    }
                    $cmd_cb->();
                };
        }
        else {
            $self->Successful($cb);
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
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

Please report any bugs or feature requests to L<https://github.com/jelu/lim-plugin-softhsm/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Plugin::SoftHSM

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim-plugin-softhsm/issues>

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
