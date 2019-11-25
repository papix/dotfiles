#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib 'lib';

use constant PYTHON_VERSION => '3.6.0';

use Dotfiles::Util;

# utility
sub home     { sprintf("%s%s", $ENV{HOME}, $_[0]) }
sub dotfiles { sprintf("%s%s", cwd, $_[0]) }

# anyenv
clone_repository(
    repos => 'riywo/anyenv',
    dest  => home('/.anyenv'),
);

# tmux
for (qw/ tmux.conf tmux-powerline-themes /) {
    create_symbolic_link(
        source => dotfiles('/config/' . $_),
        dest   => home('/.' . $_),
    );
}

# tmux-powerline
clone_repository(
    repos => 'erikw/tmux-powerline',
    dest  => home('/.tmux-powerline'),
);

# zsh
create_symbolic_link(
    source => dotfiles('/config/zshenv'),
    dest   => home('/.zshenv'),
);
create_symbolic_link(
    source => dotfiles('/config/zshrc'),
    dest   => home('/.zshrc'),
);
create_symbolic_link(
    source => dotfiles('/config/zshrc.alias'),
    dest   => home('/.zshrc.alias'),
);

# nvim
create_directory( home('/.config/nvim') );
for (qw/ autoload backup colors plugins swap undo /) {
    create_directory( home('/.config/nvim/' . $_) );
}
download(
    url  => 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim',
    dest => home('/.local/share/nvim/site/autoload/plug.vim'),
);
create_symbolic_link(
    source => dotfiles('/config/init.vim'),
    dest   => home('/.config/nvim/init.vim'),
);
for (qw/ rc snippets /) {
    create_symbolic_link(
        source => dotfiles('/config/vim/' . $_),
        dest   => home('/.config/nvim/' . $_),
    );
}

# peco
create_symbolic_link(
    source => dotfiles('/config/peco'),
    dest   => home('/.peco'),
);

# tig
create_symbolic_link(
    source => dotfiles('/config/tigrc'),
    dest   => home('/.tigrc'),
);

# labo
for (qw/ sandbox script /) {
    create_directory( home('/.labo/' . $_) );
}

# anyenv
for (qw/ plenv ndenv rbenv pyenv /) {
    info(sprintf('[install %s]', $_));

    my $env = home('/.anyenv/envs/'.$_);
    if (is_exists($env)) {
        success('already exists');
    } else {
        run('anyenv install ' . $_);
        success('complete')
    }
}

# vscode
create_directory( home('/Library/Application Support/Code/User') );
for (qw/ keybindings.json settings.json snippets/) {
    create_symbolic_link(
        source => dotfiles('/config/vscode/' . $_),
        dest   => home('/Library/Application Support/Code/User/' . $_),
    );
}

