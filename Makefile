# Draft Makefile. You will need:
# - kramdown-rfc2629 (https://github.com/cabo/kramdown-rfc2629)
# - xml2rfc (https://xml2rfc.tools.ietf.org/)

DRAFT=draft-ietf-dprive-dnsoquic
VERSION=02

XML=$(DRAFT).xml
HTML=$(DRAFT)-$(VERSION).html
TXT=$(DRAFT)-$(VERSION).txt

.PHONY: clean

all: $(HTML) $(TXT) 

$(XML): $(DRAFT).md; kramdown-rfc2629 $< $@

$(HTML): $(XML) ; xml2rfc --html -o $@ $<
$(TXT): $(XML) ; xml2rfc --text -o $@ $<

clean: ; rm $(XML) $(HTML) $(TXT)