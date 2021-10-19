# Draft Makefile. You will need:
# - kramdown-rfc2629 (https://github.com/cabo/kramdown-rfc2629)
# - xml2rfc (https://xml2rfc.tools.ietf.org/)

DRAFT=draft-ietf-dprive-dnsoquic
VERSION=06

XML=$(DRAFT).xml
HTML=$(DRAFT)-$(VERSION).html
TXT=$(DRAFT)-$(VERSION).txt

.PHONY: clean

all: $(HTML) $(TXT) 

$(XML): $(DRAFT).md; kramdown-rfc2629 -3 $< > $@

$(HTML): $(XML) ; xml2rfc --html --v3 -o $@ $<
$(TXT): $(XML) ; xml2rfc --text --v3 -o $@ $<

clean: ; rm $(XML) $(HTML) $(TXT)