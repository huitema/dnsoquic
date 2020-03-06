# dnsoquic
DNS over QUIC

This draft uses `kramdown-rfc2629`. To build you will need:

* [kramdown-rfc2629](https://github.com/cabo/kramdown-rfc2629)
* [xml2rfc](https://xml2rfc.tools.ietf.org)

To generate text and html versions of the draft from the markdown use
[GNUmake](https://www.gnu.org/software/make/):

    $ make

or use something like:
~~~
kramdown-rfc2629 draft-huitema-dprive-dnsoquic.md > x.xml &&
     xml2rfc --text x.xml && rm x.xml &&
     mv x.txt draft-huitema-dprive-dnsoquic.txt
~~~
