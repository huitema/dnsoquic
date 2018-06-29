# dnsoquic
DNS over QUIC

This draft uses mmark. To build you will need:

* [mmark](https://github.com/miekg/mmark)
* [xml2rfc](https://xml2rfc.tools.ietf.org)

To generate text and html versions of the draft from the markdown use
[GNUmake](https://www.gnu.org/software/make/):

    $ make

or use something like:

mmark -xml2 -page draft-huitema-quic-dnsoquic.md > x.xml && xml2rfc --text x.xml && rm x.xml && mv x.txt draft-huitema-quic-dnsoquic.txt
