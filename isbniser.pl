#! /usr/bin/perl

#               Transform ISBN-10 <=> ISBN-13

#              by John Walker  --  January 2008
#                 Version 1.1  --  October 2015
#                 Version 1.2  --  October 2017
#                 Version 1.3  --  October 2017
#                 Version 1.4  --  October 2018
#                 Version 1.5  --  October 2018
#                 Version 1.6  --  May 2020
#                 Version 1.7  --  October 2021

    my $Version = '1.7 (October 2021)';

#   This program parses ISBN-10 and ISBN-13 specifications from
#   the command line (either, intermixed in any order), validates
#   them and, if valid, emits the code in both ISBN-10 and ISBN-13
#   form (an ISBN-13 which cannot be transformed into an ISBN-10
#   is identified as "Unmappable").  ISBNs may be specified with
#   any delimiter; the delimiter is preserved in the transformed
#   number.  Output is in both delimited and "canonical" form
#   without any delimiters.

#   Sample run:

#   ./isbniser.pl 0-309-09657-X 0.309.09657.X 1844135438 \
#       9780385611015 978-0-471-64877-2 978.0.471.64877.2 \
#       979-0-471-64877-1 1844135437
#ISBN-10:        0-309-09657-X     030909657X  ISBN-13:  9780309096577     978-0-309-09657-7
#ISBN-10:        0.309.09657.X     030909657X  ISBN-13:  9780309096577     978.0.309.09657.7
#ISBN-10:           1844135438     1844135438  ISBN-13:  9781844135431         9781844135431
#ISBN-13:        9780385611015  9780385611015  ISBN-10:     0385611013            0385611013
#ISBN-13:    978-0-471-64877-2  9780471648772  ISBN-10:     0471648779         0-471-64877-9
#ISBN-13:    978.0.471.64877.2  9780471648772  ISBN-10:     0471648779         0.471.64877.9
#ISBN-13:    979-0-471-64877-1  9790471648771  ISBN-10:     Unmappable
#Invalid ISBN: 1844135437
#
#   If you specify "-n" on the command line, subsequent ISBNs will not
#   be verified.  You can use this to generate URLs for Amazon ASINs.
#   Specifying "-v" turns ISBN verification back on for subsequent
#   arguments.

#   Set $Amazon to the site to which Amazon links should be
#   directed (www.amazon.com, www.amazon.co.uk, www.amazon.co.jp,
#   etc.).  If it's set to the null string, no Amazon links
#   are generated.  You can override this setting with the the
#   -a<sitename> option, which affects all subsequent arguments.

    my $Amazon = 'www.amazon.com';

#   If you have an Amazon associates account and you'd like the
#   Amazon link to credit it, specify it below.  Otherwise, leave
#   $credit set to the null string.  You can change the credit
#   account with the -c<account> option, which affects all
#   subsequent arguments.

    my $credit = 'fourmilabwwwfour';

#   When the -r option is specified, the following alternative Amazon
#   associates account is used instead of $credit.  You can specify
#   any account with the -c<account> option, but the -r option allows
#   you to choose a frequently-used alternative account without having
#   to enter it on the command line.

    my $creditR = 'secondary-acct';

    use strict;
    use warnings;

    my $noval = 0;
    my $hyphenate = 1;
    my $showRegGroup = 0;
    my $csv = 0;

    #   Status codes
    #
    #       200     Normal, ISBN-13 and ISBN-10 returned
    #       201     Normal, ISBN-13 returned, 979- unmappable to ISBN-10
    #       300     Invalid registration group, unhyphenated ISBN-13 and ISBN-10 returned
    #       301     Invalid registration group, unhyphenated 979- ISBN-13 returned
    my $status = 200;               # Request processing status

    #       401     Incorrect length (not 10 or 13 characters)
    #       402     Illegal character
    #       403     "X" as other than last character of ISBN-10
    #       404     Checksum incorrect
    #       405     ISBN-13 prefix is not Bookland (978 or 979)
    my $auxstat10 = 0;              # ISBN-10 auxiliary status
    my $auxstat13 = 0;              # ISBN-13 auxiliary status

    our @ISBN_range;
    our $ISBN_database_date;
    define_ISBN_ranges();           # Load ISBN range table
    my $registrationGroup = '';     # Registration group returned by hyphenate()

    help() if scalar(@ARGV) == 0;

    for my $s (@ARGV) {
        if ($s =~ m/\-a(.*)$/) {
            $Amazon = $1;
            next;
        } elsif ($s =~ m/\-c(.*)$/) {
            $credit = $1;
            next;
        } elsif ($s eq '-d') {
            $csv = 1;
            next;
        } elsif ($s eq '-g') {
            $showRegGroup = 1;
            next;
        } elsif ($s eq '-n') {
            $noval = 1;
            next;
        } elsif ($s eq '-p') {
            $hyphenate = 0;
            next;
        } elsif ($s eq '-r') {
            $credit = $creditR;
            next;
        } elsif (($s eq '-u') || ($s =~ m/^\-\-h/)) {
            help();
        } elsif ($s eq '-v') {
            $noval = 0;
            next;
        }
        if ($noval) {
            printf("ISBN-10: %20s  %13s\n", $s, $s);
            if ($Amazon ne '') {
                printf("http://$Amazon/dp/$s/%s\n", credit());
            }
            next;
        }

        #   Test for ISBN-13 argument and process if so.

        my $n = validate_ISBN_13($s);
        if ($n ne '') {
            #   This is a valid ISBN-13
            if ($hyphenate) {
                #   Extract delimiter from given ISBN-13, if any
                my $delim = '-';
                $delim = $1 if ($s =~ m/([^\d])/);
                $s = hyphenate($n, $delim);
            }
            my ($isbn10, $esbn10);
            if (substr($n, 2, 1) eq '9') {
                $isbn10 = 'Unmappable';
                $esbn10 = 'Unmappable';
                $status += 1;
            } else {
                $isbn10 = substr($n, 3, 9);
                my $ckd = ISBN_10_check($isbn10);
                $isbn10 .= $ckd;
                $esbn10 = $s;
                $esbn10 =~ s/^9\D?7\D?[89]\D?//;
                $esbn10 =~ s/\d(\D*)$/$ckd$1/;
            }
            my $amazonURL = "";
            if (($Amazon ne '') && ($isbn10 ne 'Unmappable')) {
                $amazonURL = "http://$Amazon/dp/$isbn10/" . credit();
            }

            if ($csv) {
                #   CSV output fields
                #
                #       1.  Status
                #       2.  ISBN-13, no delimiters
                #       3.  ISBN-13, with delimiters
                #       4.  ISBN-10, no delimiters  ("Unmappable" if 979-)
                #       5.  ISBN-10, with delimiters    ("Unmappable" if 979-)
                #       6.  Registration group
                #       7.  Amazon associates URL
                #       8.  ISBN registration group database date
                printf("$status,$n,\"$s\",$isbn10,\"$esbn10\",\"$registrationGroup\",\"$amazonURL\",\"$ISBN_database_date\"\n");
            } else {
                printf("ISBN-13: %20s  %13s  ISBN-10:  %13s  %20s\n", $s, $n, $isbn10, $esbn10);
                if (($Amazon ne '') && ($isbn10 ne 'Unmappable')) {
                    print("$amazonURL\n");
                }
                if ($showRegGroup && ($registrationGroup ne '')) {
                    print("ISBN Registration Group: $registrationGroup\n");
                }
            }

        #   Not ISBN-13.  Test for valid ISBN-10 and process if so.

        } elsif (($n = validate_ISBN_10($s)) ne '') {
            #   This is a valid ISBN-10
            my $isbn13 = "978". substr($n, 0, 9);
            my $ckd = ISBN_13_check($isbn13);
            $isbn13 .= $ckd;
            my $esbn13;
            if ($hyphenate) {
                #   Extract delimiter from given ISBN-10, if any
                my $delim = '-';
                $delim = $1 if ($s =~ m/([^\dxX])/);
                $esbn13 = hyphenate($isbn13, $delim);
                #   We now have a hyphenated ISBN-13 in $esbn13.  Synthesise a
                #   hyphenated ISBN-10 from it into $s.
                if (length($esbn13) > 13) {
                    #   Hyphenation succeeded: we're on
                    $s = $esbn13;
                    $s =~ s/....//;         # Peel off Bookland prefix
                    $s =~ s/.$//;           # Peel off ISBN-13 check digit
                    $n =~ m/(.)$/;          # Extract ISBN-10 check digit
                    $s .= $1;               # Append check digit to hyphenated ISBN-10
                }
            } else {
                my $delim = '';
                $delim = $1 if ($s =~ m/([^\dxX])/);
                $esbn13 = "978$delim$s";
                $esbn13 =~ s/[\dxX]([^\dxX]*)$/$ckd$1/;
            }

            my $amazonURL = "";
            if ($Amazon ne '') {
                $amazonURL = "http://$Amazon/dp/$n/" . credit();
            }

            if ($csv) {
                printf("$status,$isbn13,\"$esbn13\",$n,\"$s\",\"$registrationGroup\",\"$amazonURL\",\"$ISBN_database_date\"\n");
            } else {
                printf("ISBN-10: %20s  %13s  ISBN-13:  %13s  %20s\n", $s, $n, $isbn13, $esbn13);
                if ($Amazon ne '') {
                    print("$amazonURL\n");
                }
                if ($showRegGroup && ($registrationGroup ne '')) {
                    print("ISBN Registration Group: $registrationGroup\n");
                }
            }

        #   It's neither ISBN-13 nor ISBN-10.  Bounce it.

        } else {
            if ($csv) {
                my $cstat = 401;
                if ($auxstat10 != 401) {
                    $cstat = $auxstat10;
                } elsif ($auxstat13 != 401) {
                    $cstat = $auxstat13;
                }
                #   Return error status and void result
                print("$cstat,,\"\",,\"\",\"\",\"\",\"$ISBN_database_date\"\n");
            } else {
                print("Invalid ISBN: $s\n");
            }
        }
    }

    #   Construct credit string for Amazon links

    sub credit {
        my $c = $credit;

        if ($c ne '') {
            $c = "?tag=$credit";
        }
        return $c;
    }

    #   Compute ISBN-13 check digit from a canonical ISBN-13.  Only
    #   the first 12 characters of the ISBN are examined.

    sub ISBN_13_check {
        my ($s) = @_;
        my (@digits, $sum, $d, $i, $f);

        @digits = unpack('C12', $s);
        $sum = 0;
        $f = 1;
        for ($i = 0; $i < 12; $i++) {
            $d = $digits[$i] - ord('0');
            $sum += $f * $d;
            $f = ($f + 2) & 3;
        }
        $sum %= 10;
        return (10 - $sum) % 10;
    }

    #   Test whether the argument is a valid ISBN-13.  Punctuation
    #   is ignored.  The function returns the canonical 13 digit
    #   ISBN-13 if valid and the null string otherwise.

    sub validate_ISBN_13 {
        my ($s) = @_;
        my (@digits, $sum, $d, $i, $f);

        $s =~ tr/0-9//cd;       # Delete any non-digits
        if (length($s) != 13) {
            $auxstat13 = 401;   # Incorrect length
            return '';          # All valid ISBN-13s are thirteen characters
        }
        @digits = unpack('C13', $s);
        $sum = 0;
        $f = 1;
        for ($i = 0; $i < 13; $i++) {
            $d = $digits[$i] - ord('0');
            $sum += $f * $d;
            $f = ($f + 2) & 3;
        }
        $sum %= 10;
        if ($sum != 0) {
            $auxstat13 = 404;   # Checksum incorrect
            return '';          # ISBN-13 checksum is incorrect
        }
        if ($s !~ m/^97[89]/) {
            $auxstat13 = 405;   # Prefix is neither 978 or 979
            return '';          # This is a valid EAN-13, but not in Bookland
        }
        $auxstat13 = 0;         # ISBN-13 is valid
        return $s;
    }

    #   Compute ISBN-10 check digit from a canonical ISBN-10.  Only
    #   the first 9 characters of if the ISBN are examined.

    sub ISBN_10_check {
        my ($s) = @_;
        my (@digits, $sum, $d, $i);

        @digits = unpack('C9', $s);
        $sum = 0;
        for ($i = 0; $i < 9; $i++) {
            $d = $digits[$i] - ord('0');
            $sum += (10 - $i) * $d;
        }
        $sum %= 11;
        $sum = 11 - $sum;
        return ($sum == 10) ? 'X' :
            (($sum == 11) ? 0 : $sum);
    }

    #   Test whether the argument is a valid ISBN-10.  Punctuation
    #   is ignored and the "X" checksum may be either upper or
    #   lower case.  The function returns the canonical 10 character
    #   ISBN-10 if valid and the null string otherwise.

    sub validate_ISBN_10 {
        my ($s) = @_;
        my (@digits, $sum, $d, $i);

        $s = uc($s);            # Actually, just for "X"
        $s =~ tr/0-9A-Z//cd;    # Delete any punctuation
        if (length($s) != 10) {
            $auxstat10 = 401;   # Incorrect length
            return '';          # All valid ISBNs are ten characters
        }
        if ($s =~ m/A-WYZ/) {
            $auxstat10 = 402;   # Illegal character
            return '';          # "X" is the only letter permitted in an ISBN
        }
        if (substr($s, 0, 9) =~ m/X/) {
            $auxstat10 = 403;   # ISBN-10 checksum not last character
            return '';          # "X" may only appear as the last, checksum, character
        }
        @digits = unpack('C10', $s);
        $sum = 0;
        for ($i = 0; $i < 10; $i++) {
            if ($digits[$i] == ord('X')) {
                $d = 10;
            } else {
                $d = $digits[$i] - ord('0');
            }
            $sum += (10 - $i) * $d;
        }
        $sum %= 11;
        if ($sum != 0) {
            $auxstat10 = 404;   # Checksum incorrect
            return '';          # ISBN checksum is incorrect
        }
        $auxstat10 = 0;         # ISBN-10 is correct
        return $s;
    }

    #   Hyphenate an ISBN-13 in canonical form (no delimiters)

    #   Division of ISBNs into registration group, registrant,
    #   publication, and checksum is deliciously baroque
    #   (although checksum is always a single character).
    #   The ISBN bureaucracy publishes a database:
    #       https://www.isbn-international.org/range_file_generation
    #   which lists all the registration groups and ranges
    #   (determined by each) which determine how many
    #   digits within that range identify the registrant
    #   (publisher).  A range with zero registrant digits
    #   is invalid.  The ISBN is divided into its components
    #   and separated by the delimiter given as the second
    #   argument.

    #   We assume the first argument is an already-validated
    #   ISBN-13 with no delimiters.  The second argument will be
    #   used as the delimiter to be inserted within elements in
    #   the ISBN-13 returned.  If the ISBN cannot be hyphenated
    #   (its prefix is not in the range group database), a
    #   warning message is issued and it is returned unmodified.

    sub hyphenate {
        my ($isbn, $delim) = @_;

        die("Argument ($isbn) is not an ISBN-13")
            if ($isbn !~ m/^\d{13}$/);

        #   Check digit is always the last

        $isbn =~ m/(\d\d\d)(\d+)(\d)$/;
        my ($ean, $regpub, $check) = ($1, $2, $3);
        my ($registrant, $publication);

        #   Now we walk through the ISBN_range table searching
        #   for the actual prefix in the ISBN argument.  We
        #   match on the prefix plus registration group element,
        #   then test the remainder of the ISBN (less check digit)
        #   for within range.

        for (my $i = 0; $i < scalar(@ISBN_range); $i++) {
            my $r = $ISBN_range[$i];
            my $rp = @$r[0];
            $rp =~ s/\D//g;

            my $earp = "$ean$regpub";
            if ($earp =~ m/^$rp(\d+)$/) {
                my $balance = $1;
                my $brange = $balance . "0000000";
                $brange =~ m/^(\d{7})/;
                $brange = $1;
                my $irange = @$r[2];
                $irange =~ m/^(\d+)\-(\d+)$/;
                my ($irlow, $irhigh) = ($1, $2);
                if (($brange >= $irlow) && ($brange <= $irhigh)) {
                    $registrationGroup = @$r[1];
                    my $reglength = @$r[3];     # Length of registrant
                    if ($reglength > 0) {       # Registrant length == 0 means invalid
                        #   Now, to extract the registrant and publication,
                        #   we take the complete ISBN, strip off the
                        #   prefix we found, and then divide the
                        #   remainder into registrant and publication,
                        #   discarding the check digit.
                        $isbn =~ m/^$rp(\d{$reglength})(\d+)\d$/;
                        ($registrant, $publication) = ($1, $2);

                        #   OK, we've got it.  Return the hyphenated
                        #   components of the ISBN.

                        my $prefix = @$r[0];
                        $prefix =~ s/\D/$delim/g;   # Use requested delimiter after prefix
                        return "$prefix$delim$registrant$delim$publication$delim$check";
                    }
                }
            }
        }

        if ($csv) {
            $status = 300;
            $registrationGroup = 'Invalid';
        } else {
            print(STDERR "Unable to hyphenate ISBN $isbn.\n");
            $registrationGroup = '';
        }
        return $isbn;
    }

    #   Print help message if called with no arguments or
    #   the -u or --help options.

    sub help {
        print("usage: isbniser arg...\n");
        print("  Arguments can be an ISBN-10 or ISBN-13 in any of the\n");
        print("  following forms:\n");
        print("    0-309-09657-X        ISBN-10 with delimiters\n");
        print("    0.309.09657.X        ISBN-10 with alternative delimiters\n");
        print("    1844135438           ISBN-10 without delimiters\n");
        print("    978-0-471-64877-2    ISBN-13 with delimiters\n");
        print("    978.0.471.64877.2    ISBN-13 with alternative delimiters\n");
        print("    9780385611015        ISBN-13 without delimiters\n");
        print("  Options:\n");
        print("    -a<URL>          Specify URL of site for Amazon links\n");
        print("    -c<account>      Specify Amazon associates account\n");
        print("    -d               Database (CSV) format output\n");
        print("    -g               Show ISBN registration group\n");
        print("    -n               Do not validate subsequent ISBNs/ASINs\n");
        print("    -p               Preserve original delimiters (do not re-hyphenate)\n");
        print("    -r               Use built-in alternative Amazon associates account\n");
        print("    -u --help        Print this message\n");
        print("    -v               Validate subsequent ISBNs\n");
        print("  Sample output:\n");
        print("    ISBN-13: 978-0-471-64877-2  9780471648772    ISBN-10: 0471648779  0-471-64877-9\n");
        print("    http://www.amazon.com/dp/0471648779/?tag=fourmilabwwwfour\n");
        print("  Configuration (edit program to change):\n");
        print("    Amazon site: \"$Amazon\"\n");
        print("    Default associates account: \"$credit\"\n");
        print("    Alternative associates account: \"$creditR\"\n");
        print("  ISBN range database date: $ISBN_database_date\n");
        print("Version $Version\n");
        exit(0);
    }

    #   Define the ISBN ranges

    #   We do this in a subroutine purely to put it at the bottom
    #   of the source file so it doesn't distract from the code,
    #   which is what most people will be interested in.

    sub define_ISBN_ranges {

        #   ISBN range definitions

        #   Compiled from:
        #       https://www.isbn-international.org/range_file_generation
        #   by the parse_range_xml.pl program included in the source
        #   distribution.

        do "./isbn_range.pl";
    }
