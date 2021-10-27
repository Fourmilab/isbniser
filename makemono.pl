
    #   Make monolithic program by in-line expanding all
    #   do includes in the development version.

    use strict;
    use warnings;

    open(FI, "<isbniser.pl") || die("Cannot open isbniser.pl");
    open(FO, ">isbniser") || die("Cannot create isbniser");

    while (my $l = <FI>) {
        if ($l =~ m/(\s*)do\s+"([^"]+)"\s*;/) {
            my ($indent, $ifn) = ($1, $2);

            open(II, "<$ifn") || die("Cannot open include file $ifn");
            print(FO "$indent# Included from $ifn\n");
            while (my $li = <II>) {
                print(FO $li);
            }
            print(FO "$indent# End include from $ifn\n");
            close(II);
            next;
        }
        print(FO $l);
    }

    close(FO);
    close(FI);

    chmod(0755, "isbniser");        # Make the monolithic file executable

