#!/usr/bin/env perl

### My ASCII implementation of the game 2048
### Patrik Wallström <pawal@blipp.com> 2014-07-15

use strict;
use warnings;

use Term::ReadKey;
use Term::Cap;
use Term::ANSIColor;

my $DEBUG = 0;

my $score = 0;  # total score
my $moves = 0;  # total number of moves
my $board = [   # the game board
    [ 0, 0, 0, 0 ],
    [ 0, 0, 0, 0 ],
    [ 0, 0, 0, 0 ],
    [ 0, 0, 0, 0 ],
];

my $colors = {
    '0' => 'black on_black',
    '2' => 'bold blue on_black',
    '4' => 'magenta on_black',
    '8' => 'cyan on_black',
    '16' => 'yellow on_black',
    '32' => 'green on_black',
    '64' => 'red',
    '128' => 'bold yellow on_black',
    '256' => 'bold blue on_black',
    '512' => 'bold magenta on_black',
    '1024' => 'bold green on_blue',
    '2048' => 'bold red on_blue',
    '4096' => 'bold cyan on_blue',
    '8192' => 'bold magenta on_blue',
};

my $terminal = Term::Cap->Tgetent();

sub printBoard {
    print $terminal->Tputs('cl');
    print "\n\n";
    print  "+-----+-----+-----+-----+\n";
    printf("| Score: %-5d     %-4d |\n", $score, $moves);
    print  "+-----+-----+-----+-----+\n";
    for (my $y = 0; $y < 4; $y++) {
	print "|";
	for (my $x = 0; $x < 4; $x++) {
	    my $valstr = sprintf("%4d", @$board[$y]->[$x]);
	    my $value = colored($valstr, $colors->{@$board[$y]->[$x]});
#	    printf("%4d |", @$board[$y]->[$x]);
	    printf("%s |", $value);
	}
	print "\n";
    }
    print "+-----+-----+-----+-----+\n";
}

# returns an array of empty positions on the board
sub getEmptyArray {
    my @empty;
    for (my $y = 0; $y < 4; $y++) {
	for (my $x = 0; $x < 4; $x++) {
	    if (@$board[$y]->[$x] == 0) {
		push @empty, [$y, $x];
		print "Empty position: $x:$y\n" if $DEBUG;
	    }
	}
    }
    return \@empty;
}

# places a random value on a random position on a position from the "empty array"
sub placeRandom {
    my $empty = shift;
    my $max = @$empty;

    # random distribution
    my @values = (2,2,2,2,2,2,2,2,2,4);

    # set random position
    my $randPos = int(rand($max));
    print "Empty count: $max\n" if $DEBUG;

    my $x = @$empty[$randPos]->[1];
    my $y = @$empty[$randPos]->[0];

    # set random value from values array at random position
    my $randVal = $values[int(rand(@values))];
    @$board[$y]->[$x] = $randVal;
}

# remove empty (zero) blocks
sub _emptyUp {
    my $emptied = 0;
    my $moved;
    do {
	$moved = 0;
	for (my $y = 2; $y >= 0; $y--) {
	    for (my $x = 0; $x < 4; $x++) {
		next if @$board[$y]->[$x] != 0;
		if (@$board[$y]->[$x] = @$board[$y+1]->[$x]) {
		    @$board[$y+1]->[$x] = 0;
		    $moved++;
		    $emptied++;
		}
	    }
	}
    } while ($moved);
    return $emptied;
}

# move and merge the board upwards
sub moveUp {
    # first move epties
    my $movecount = _emptyUp;
    # make additions and merge
    for (my $y = 1; $y < 4; $y++) {
	for (my $x = 0; $x < 4; $x++) {
	    # we can merge
	    if (@$board[$y]->[$x] == @$board[$y-1]->[$x] && @$board[$y]->[$x]) {
		$score += @$board[$y]->[$x] * 2;
		@$board[$y-1]->[$x] = @$board[$y]->[$x] * 2;
		@$board[$y]->[$x] = 0;
		$movecount++;
	    }
	}
    }
    # also move emtpies after merge
    $movecount += _emptyUp;
    return $movecount;
}

# remove empty (zero) blocks
sub _emptyDown {
    my $emptied = 0;
    my $moved;
    do {
	$moved = 0;
	for (my $y = 1; $y <= 3; $y++) {
	    for (my $x = 0; $x < 4; $x++) {
		next if @$board[$y]->[$x] != 0;
		if (@$board[$y]->[$x] = @$board[$y-1]->[$x]) {
		    @$board[$y-1]->[$x] = 0;
		    $moved++;
		    $emptied++;
		}
	    }
	}
    } while ($moved);
    return $emptied;
}

# move and merge the board downwards
sub moveDown {
    my $movecount = _emptyDown;

    # make additions and merge
    for (my $y = 2; $y >= 0; $y--) {
	for (my $x = 0; $x < 4; $x++) {
	    # we can merge
	    if (@$board[$y]->[$x] == @$board[$y+1]->[$x] && @$board[$y]->[$x]) {
		$score += @$board[$y]->[$x] * 2;
		@$board[$y+1]->[$x] = @$board[$y]->[$x] * 2;
		@$board[$y]->[$x] = 0;
		$movecount++;
	    }
	}
    }
    # also move emtpies after merge
    $movecount += _emptyDown;
    return $movecount;
}

# remove empty (zero) blocks
sub _emptyRight {
    my $emptied = 0;

    # move empties
    my $moved;
    do {
	$moved = 0;
	for (my $y = 0; $y < 4; $y++) {
	    for (my $x = 1; $x < 4 ; $x++) {
		next if @$board[$y]->[$x];
		if (@$board[$y]->[$x] = @$board[$y]->[$x-1]) {
		    @$board[$y]->[$x-1] = 0;
		    $moved++;
		    $emptied++;
		}
	    }
	}
    } while ($moved);
    return $emptied;
}

# move and merge the board to the right
sub moveRight {
    my $movecount = _emptyRight;;

    # make additions and merge
    for (my $y = 0; $y < 4; $y++) {
	for (my $x = 2; $x >= 0; $x--) {
	    # we can merge
	    if (@$board[$y]->[$x] == @$board[$y]->[$x+1] && @$board[$y]->[$x]) {
		$score += @$board[$y]->[$x] * 2;
		@$board[$y]->[$x+1] = @$board[$y]->[$x] * 2;
		@$board[$y]->[$x] = 0;
		$movecount++;
	    }
	}
    }
    # also move emtpies after merge
    $movecount += _emptyRight;
    return $movecount;
}

# remove empty (zero) blocks
sub _emptyLeft {
    my $emptied = 0;
    # move empties
    my $moved;
    do {
	$moved = 0;
	for (my $y = 0; $y < 4; $y++) {
	    for (my $x = 2; $x >= 0 ; $x--) {
		next if @$board[$y]->[$x];
		if (@$board[$y]->[$x] = @$board[$y]->[$x+1]) {
		    @$board[$y]->[$x+1] = 0;
		    $moved++;
		    $emptied++;
		}
	    }
	}
    } while ($moved);
    return $emptied;
}

# move and merge the board to the left
sub moveLeft {
    my $movecount = _emptyLeft;

    # make additions and merge
    for (my $y = 0; $y < 4; $y++) {
	for (my $x = 1; $x < 4; $x++) {
	    # we can merge
	    if (@$board[$y]->[$x] == @$board[$y]->[$x-1] && @$board[$y]->[$x]) {
		$score += @$board[$y]->[$x] * 2;
		@$board[$y]->[$x-1] = @$board[$y]->[$x] * 2;
		@$board[$y]->[$x] = 0;
		$movecount++;
	    }
	}
    }
    # also move emtpies after merge
    $movecount += _emptyLeft;
    return $movecount;
}

sub main {
    # set input read mode for keyboard
    ReadMode 'cbreak';

    # initial move, two random values
    my $empty = getEmptyArray;
    placeRandom($empty);
    $empty = getEmptyArray;
    placeRandom($empty);

MAINLOOP: { do {
	printBoard;
	print "|  Your move (u/d/l/r)  |\n";

	# make a move
	my $key = ReadKey(0);
	my $movecount;
	$movecount = moveLeft  if $key eq 'l';
	$movecount = moveRight if $key eq 'r';
	$movecount = moveUp    if $key eq 'u';
	$movecount = moveDown  if $key eq 'd';
	
	# Arrow keys send 3 characters, the last one can be used to determine which arrow
	$movecount = moveLeft  if ord($key) == 68;
        $movecount = moveRight if ord($key) == 67;
        $movecount = moveUp    if ord($key) == 65;
        $movecount = moveDown  if ord($key) == 66;
	
	last MAINLOOP if $key eq 'q';
	$moves++ if $movecount;

	# are we done?
	$empty = getEmptyArray;
	placeRandom($empty) if @$empty and $movecount;
    } while (@$empty); } # continue while there is an empty position

    # game over
    print "\nGAME OVER\n";
    print "Total moves: $moves\n";
    print "Total score: $score\n";
}

main();

# todo - make use of cursor keys
