
PROGRAMS = isbniser isbniser.pl \
	   parse_range_xml.pl isbn_range.pl makemono.pl

VERSION = 1.7

duh:
	@echo "Well, what'll it be?  dist lint check clean"

dist:
	./Generic
	rm -f isbn_range.pl isbniser
	make isbn_range.pl
	make isbniser
	tar cfvz isbniser-$(VERSION).tar.gz $(PROGRAMS) \
		Makefile expected.txt index.html log.txt XML
	./Specific

lint:
	perl -c isbniser.pl
	perl -c isbniser

check:
	perl isbniser.pl -p -cmyassocacct \
		0-309-09657-X 0.309.09657.X 1844135438 \
		9780385611015 978-0-471-64877-2 978.0.471.64877.2 \
		979-12-200-0852-5 1844135437 >received.txt
	perl isbniser.pl -cmyassocacct \
		0-309-09657-X 0.309.09657.X 1844135438 \
		9780385611015 978-0-471-64877-2 978.0.471.64877.2 \
		979-12-200-0852-5 1844135437 >>received.txt
	perl isbniser.pl -d -cmyassocacct \
		0-309-09657-X 0.309.09657.X 1844135438 \
		9780385611015 978-0-471-64877-2 978.0.471.64877.2 \
		979-12-200-0852-5 1844135437 >>received.txt
	@-diff expected.txt received.txt && \
	    ([ $$? -eq 0 ]) || \
	    echo 'Error(s) detected in results.'
	./isbniser -p -cmyassocacct \
		0-309-09657-X 0.309.09657.X 1844135438 \
		9780385611015 978-0-471-64877-2 978.0.471.64877.2 \
		979-12-200-0852-5 1844135437 >received.txt
	./isbniser -cmyassocacct \
		0-309-09657-X 0.309.09657.X 1844135438 \
		9780385611015 978-0-471-64877-2 978.0.471.64877.2 \
		979-12-200-0852-5 1844135437 >>received.txt
	./isbniser -d -cmyassocacct \
		0-309-09657-X 0.309.09657.X 1844135438 \
		9780385611015 978-0-471-64877-2 978.0.471.64877.2 \
		979-12-200-0852-5 1844135437 >>received.txt
	@-diff expected.txt received.txt && \
	    ([ $$? -eq 0 ]) || \
	    echo 'Error(s) detected in results.'

clean:
	rm -f *.tar.gz received.txt

#       Compile ISBN range database (download from:
#           https://www.isbn-international.org/range_file_generation
#       in XML format into XML/RangeMessage.xml) into
#       our isbn_range.pl include file.

isbn_range.pl:
	perl parse_range_xml.pl XML/RangeMessage.xml >isbn_range.pl

#       Build the monolithic executable from its components

isbniser: isbniser.pl isbn_range.pl
	perl makemono.pl


