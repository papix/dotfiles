package Dotfiles::Util;
use strict;
use warnings;
use utf8;
use base 'Exporter';

use Term::ANSIColor;
use Cwd;

our @EXPORT = qw/
    is_exists
    is_file
    is_link
    is_dir
    is_link_to

    cwd
    run

    create_symbolic_link
    create_directory
    download
    clone_repository

    info
    stderr
    success
    warning
    error
/;

sub is_exists  { system(qq{test -e '$_[0]'}) ? 0 : 1 }
sub is_file    { system(qq{test -f '$_[0]'}) ? 0 : 1 }
sub is_link    { system(qq{test -L '$_[0]'}) ? 0 : 1 }
sub is_dir     { system(qq{test -d '$_[0]'}) ? 0 : 1 }
sub is_link_to { readlink($_[1]) eq $_[0] ? 1 : 0 }

sub cwd { Cwd::getcwd() }
sub run { system( join ' ', @_ ) }

sub create_symbolic_link {
    my %params = @_;

    my $source = $params{source} or die "'source' is required";
    my $dest   = $params{dest}   or die "'dest' is required";

    info("[create symbolic link]");
    info("  source: $source");
    info("  dest: $dest");

    if (is_link($dest)) {
        if (is_link_to($source, $dest)) {
            success('already exists');
        } else {
            system(qq{ln -nfs '$source' '$dest'});
            warning('overwritten');
        }
    } else {
        system(qq{ln -nfs '$source' '$dest'});
        success('complete');
    }
}

sub clone_repository {
    my %params = @_;

    my $repos = $params{repos} or die "'repos' is required";
    my $dest  = $params{dest}  or die "'dest' is required";

    info("[clone repository]");
    info("  repos: $repos");
    info("  dest: $dest");

    if (is_dir($dest)) {
        success('already exists');
    } else {
        system(qq{git clone git\@github.com:$repos.git $dest});
        success('complete');
    }
}

sub create_directory {
    my ($name) = @_;

    info("[create directory]");
    info("  name: $name");

    if (is_dir($name)) {
        success('already exists');
    } else {
        system(qq{mkdir -p '$name'});
        success('complete');
    }
}

sub download {
    my %params = @_;

    my $url  = $params{url} or die "'url' is required";
    my $dest = $params{dest} or die "'dest' is required";

    info("[download]");
    info("  url: $url");
    info("  dest: $dest");
    if (is_exists($dest)) {
        success('already exists');
    } else {
        system(qq{curl -fLo '$dest' '$url'});
        success('complete');
    }
}

# logger
sub info    { print "$_[0]\n" }
sub stderr  { print STDERR "$_[0]\n" }
sub success { print colored(['green'],  "  => $_[0]\n") }
sub warning { print colored(['yellow'], "  => $_[0]\n") }
sub error   { print colored(['red'],    "  => $_[0]\n"); exit 1 }

1;
