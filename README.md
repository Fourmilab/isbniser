# Fourmilab ISBNiser

[Fourmilab ISBNiser](https://www.fourmilab.ch/webtools/isbniser/)
is a command line utility which can be run on any system which supports
the Perl language. It accepts arguments which can be either ISBN-13s or
ISBN-10s, with or without delimiters, checks them for validity, and
displays the ISBN in all valid forms including, if configured, an
Amazon associate link ready to go _ka-ching_ into your reading budget
every time a visitor to your site clicks it.

## Sample Output

    $ isbniser.pl -cmyassocacct \
            0-309-09657-X 0.309.09657.X 1844135438 \
            9780385611015 978-0-471-64877-2 978.0.471.64877.2 \
            979-12-200-0852-5 1844135437
    ISBN-10:        0-309-09657-X     030909657X  ISBN-13:  9780309096577     978-0-309-09657-7
    http://www.amazon.com/dp/030909657X/?tag=myassocacct
    ISBN-10:        0.309.09657.X     030909657X  ISBN-13:  9780309096577     978.0.309.09657.7
    http://www.amazon.com/dp/030909657X/?tag=myassocacct
    ISBN-10:        1-84413-543-8     1844135438  ISBN-13:  9781844135431     978-1-84413-543-1
    http://www.amazon.com/dp/1844135438/?tag=myassocacct
    ISBN-13:    978-0-385-61101-5  9780385611015  ISBN-10:     0385611013         0-385-61101-3
    http://www.amazon.com/dp/0385611013/?tag=myassocacct
    ISBN-13:    978-0-471-64877-2  9780471648772  ISBN-10:     0471648779         0-471-64877-9
    http://www.amazon.com/dp/0471648779/?tag=myassocacct
    ISBN-13:    978.0.471.64877.2  9780471648772  ISBN-10:     0471648779         0.471.64877.9
    http://www.amazon.com/dp/0471648779/?tag=myassocacct
    ISBN-13:    979-12-200-0852-5  9791220008525  ISBN-10:     Unmappable
    Invalid ISBN: 1844135437


## Details

You can download the complete source code distribution, including
ready-to-run versions of all of the programs, from the
[Fourmilab ISBNiser](https://www.fourmilab.ch/webtools/isbniser/)
home page.

All of this software is licensed under the Creative Commons
Attribution-ShareAlike license.  Please see [LICENSE.md](LICENSE.md) in
this repository for details.

Please see the
[Fourmilab ISBNiser User Guide](https://www.fourmilab.ch/webtools/isbniser/)
for details.
