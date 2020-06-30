# dnsoquic
DNS over QUIC

This is the github project for the IETF draft [DNS over QUIC](https://datatracker.ietf.org/doc/draft-ietf-dprive-dnsoquic/).
If you have comments or issues on this draft, please send a mail to the [DPRIVE WG](https://datatracker.ietf.org/wg/dprive/about/)

This draft uses `kramdown-rfc2629`. To build you will need:

* [kramdown-rfc2629](https://github.com/cabo/kramdown-rfc2629)
* [xml2rfc](https://xml2rfc.tools.ietf.org)

To generate text and html versions of the draft from the markdown use
[GNUmake](https://www.gnu.org/software/make/):

    $ make

or use something like:
~~~
kramdown-rfc2629 draft-ietf-dprive-dnsoquic.md > x.xml &&
     xml2rfc --text x.xml && rm x.xml &&
     mv x.txt draft-ietf-dprive-dnsoquic.txt
~~~
