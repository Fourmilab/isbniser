
    #   Compile ISBN XML range file into isbniser range table
    
    #   Download the XML format ISBN Range file from:
    
    #   https://www.isbn-international.org/range_file_generation
    
    #   and process with this program.  Then paste the resulting
    #   Perl array definition into isbniser.pl.

    use strict;
    use warnings;

    use XML::Parser;
    
    if ((scalar(@ARGV) < 1) || (!(-f $ARGV[0]))) {
        print("Usage: perl parse_range_xml.pl RangeMessage.XML\n");
        exit(0);
    }
    
    my @elstack;
    my ($prefix, $agency, $range, $length, $messageDate);

    my $parser = XML::Parser->new(
        Handlers =>
            {
                Start => \&proc_start,
                End => \&proc_end,
                Char => \&proc_char
            }
        );
        
    $prefix = "";
    
    print("        \@ISBN_range = (\n");
    $parser->parsefile($ARGV[0]);
    print("        );\n");
    print("\n");
    print("        \$ISBN_database_date = \"$messageDate\";\n");
    
    sub proc_start {
        my ($expat, $element, %attrs) = @_;
        
        my $line = $expat->current_line;
#        print("Start $element on line $line\n");
        
        push(@elstack, $element);
    }
    
    sub proc_end {
        my ($expat, $element) = @_;
        
#        print("End $element\n");
        pop(@elstack);
    }

    sub proc_char {
        my ($expat, $content) = @_;
        
        if ($content !~ m/^\s*$/) {
#            print("Content: ($content)\n");
            
            my $tope = $elstack[$#elstack];
            
            if ($tope eq "Prefix") {
                if ($content =~ m/^\d\d\d\-\d/) {
                    $prefix = $content;
#print("Prefix ($prefix)\n");
                } else {
                    $prefix = "";
                }
                
            } elsif ($tope eq "Agency") {
                $agency = $content;
                
            } elsif ($tope eq "Range") {
                $range = $content;
                
            } elsif ($tope eq "Length") {
                $length = $content;
                if ($prefix ne '') {
                    print("            [ \"$prefix\", \"$agency\", \"$range\", $length ],\n");
                }
            } elsif ($tope eq "MessageDate") {
                $messageDate = $content;
            }
        }
    }
