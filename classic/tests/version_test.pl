use strict;
use warnings;

my ($gui, $console, $header) = @ARGV;
die "usage: perl version_test.pl GUI.bin CONSOLE.bin version.h\n"
    unless defined $header;

open my $hf, '<', $header or die "$header: $!\n";
my ($version) = map { /^#define RSYNCOPE_VERSION "([^"]+)"$/ ? $1 : () } <$hf>;
defined $version && $version =~ /^(\d+)\.(\d)\.(\d)$/
    or die "invalid version in $header\n";
my ($major, $minor, $bugfix) = ($1, $2, $3);
$major <= 99 or die "major version cannot be encoded in a vers resource\n";

sub u16 { return unpack 'n', substr($_[0], $_[1], 2); }
sub u32 { return unpack 'N', substr($_[0], $_[1], 4); }

sub resources {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "$path: $!\n";
    local $/;
    my $bin = <$fh>;
    my $start = 128 + ((u32($bin, 83) + 127) & ~127);
    my $fork = substr($bin, $start, u32($bin, 87));
    my $data = u32($fork, 0);
    my $map = u32($fork, 4);
    my $types = $map + u16($fork, $map + 24);
    my %resources;

    for my $i (0 .. u16($fork, $types)) {
        my $entry = $types + 2 + 8 * $i;
        my $type = substr($fork, $entry, 4);
        my $refs = $types + u16($fork, $entry + 6);
        for my $j (0 .. u16($fork, $entry + 4)) {
            my $ref = $refs + 12 * $j;
            my $id = u16($fork, $ref);
            my $pos = $data + (u32($fork, $ref + 4) & 0xffffff);
            $resources{"$type:$id"} = substr($fork, $pos + 4, u32($fork, $pos));
        }
    }
    return %resources;
}

sub check_app {
    my ($path, $name, $about) = @_;
    my %resources = resources($path);
    my $prefix = pack('C6', int($major / 10) * 16 + $major % 10,
        $minor * 16 + $bugfix, 0x80, 0, 0, 0)
        . pack('C', length($version)) . $version;

    for my $id (1, 2) {
        my $long = $id == 1
            ? "$version, Copyright (c) 2026 The rsyncope contributors"
            : "$name $version";
        my $expected = $prefix . pack('C', length($long)) . $long;
        defined $resources{"vers:$id"} && $resources{"vers:$id"} eq $expected
            or die "$path: incorrect vers $id\n";
    }
    if ($about) {
        my $title = "rsyncope $version";
        defined $resources{'STR :128'} &&
            $resources{'STR :128'} eq pack('C', length($title)) . $title
            or die "$path: incorrect About title\n";
    }
    print "ok - $name version resources\n";
}

check_app($gui, 'rsyncope', 1);
check_app($console, 'rsync console', 0);
