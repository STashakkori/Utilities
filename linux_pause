#!/usr/bin/env perl
#
# $t@$h
# This script installs a pause menu mechanism to your Linux system
# Once installed, you can invoke pause by pressing the pause key
# Do NOT run as root, it will use, sudo when needed
# Why is this useful?
# On some cloud instances keepalive can be a real pain. Sessions terminated
# when all you wanted was to grab a glass of water. And you don't have full
# control to configure keepalive. So you can use this to keep the session open
# as it uses ncurses TUI to have the alternate screen up indefinately. Hit
# esc to close it. Ctrl + c also works for that. Enjoy and don't let this
# run up your bill too much. Don't say I didn't warn you

use strict;
use warnings;
use File::Temp qw(tempfile);
use File::Basename;
use Cwd qw(abs_path);

my $home         = $ENV{HOME};
my $bashrc       = "$home/.bashrc";
my $pause_dest   = "/usr/local/bin/pausemenu";
my $bind_marker  = "# --- pausemenu keybind ---";

# Ensure required build tools
sub ensure_build_tools {
    my $needed = 0;
    $needed ||= system("which make > /dev/null 2>&1") != 0;
    $needed ||= system("which curl > /dev/null 2>&1") != 0;

    if ($needed) {
        print "Installing build-essential and curl\n";
        system("sudo apt-get update && sudo apt-get install -y build-essential curl") == 0
            or die "Error: Failed to install required build tools\n";
    }
}

# Install cpanminus if missing
sub ensure_cpanm {
    return if qx(which cpanm) =~ /\S/;
    print "Installing cpanm...\n";
    system("curl -L https://cpanmin.us | sudo perl - App::cpanminus") == 0
        or die "Error: Failed to install cpanm\n";
}

# Install local::lib
sub ensure_local_lib {
    eval {
        require local::lib;
        1;
    } or do {
        print "Installing local::lib via cpanm...\n";
        system("sudo cpanm local::lib") == 0
            or die "Error: Failed to install local::lib\n";
    };
}

# Install Curses
sub ensure_curses {
    eval {
        require Curses;
        Curses->import();
        1;
    } or do {
        print "Installing Curses via cpanm\n";
        system("sudo cpanm Curses") == 0
            or die "Error: Failed to install Curses\n";
    };
    print "Curses installed\n";
}

# Setup
ensure_build_tools();
ensure_cpanm();
ensure_local_lib();
ensure_curses();

# pausemenu embedded script
my $pause_code = <<'EOF';
#!/usr/bin/env perl
use lib "$ENV{HOME}/perl5/lib/perl5";
use strict;
use warnings;
use Curses;
use Fcntl qw(:flock);

open(my $lock, ">", "/tmp/.pause.lock") or exit 1;
flock($lock, LOCK_EX | LOCK_NB) or exit 0;

initscr();
cbreak();
noecho();
timeout(-1);
clear();

my ($max_y, $max_x) = (getmaxy(), getmaxx());
my ($h, $w) = (7, 30);
my ($y, $x) = (int(($max_y - $h)/2), int(($max_x - $w)/2));

for my $i (0..$h-1) {
    for my $j (0..$w-1) {
        move($y + $i, $x + $j);
        if (($i == 0 || $i == $h-1) && ($j == 0 || $j == $w-1)) {
            addch('+');
        } elsif ($i == 0 || $i == $h-1) {
            addch('-');
        } elsif ($j == 0 || $j == $w-1) {
            addch('|');
        } else {
            addch(' ');
        }
    }
}

my $title = "== PAUSED ==";
my $hint  = "[Press ESC to resume]";
move($y + 2, $x + int(($w - length($title)) / 2)); addstr($title);
move($y + 4, $x + int(($w - length($hint)) / 2));  addstr($hint);
refresh();

while (1) {
    my $ch = getch();
    last if defined($ch) && ord($ch) == 27;
}

endwin();
EOF

# Write to temp file and install
my ($fh, $temp_path) = tempfile();
print $fh $pause_code;
close($fh);
chmod 0755, $temp_path;

print "Installing pausemenu to $pause_dest...\n";
system("sudo mv $temp_path $pause_dest") == 0 or die "Error: Failed to move pausemenu\n";
system("sudo chmod +x $pause_dest") == 0 or die "Error: chmod failed\n";

# Ensure ~/.bashrc exists
unless (-e $bashrc) {
    open(my $new, '>', $bashrc) or die "Error: Failed to create ~/.bashrc\n";
    print $new "# .bashrc created by pause_installer\n";
    close($new);
}

# Update .bashrc for keybinding
my $bind_cmd = qq{$bind_marker\nbind -x '"\\e[5~"':'$pause_dest'\n};
my $bashrc_content = do {
    open(my $in, '<', $bashrc) or die "Error: Cannot read $bashrc\n";
    local $/;
    <$in>;
};
$bashrc_content =~ s/\Q$bind_marker\E.*?bind -x.*?\n//s;

open(my $br_out, '>', $bashrc) or die "Error: Cannot write $bashrc\n";
print $br_out $bashrc_content;
print $br_out "\n$bind_cmd";
close($br_out);

print "pausemenu installed, local::lib configured, and Pause key binding set\n";
print "Run: source ~/.bashrc\n";
