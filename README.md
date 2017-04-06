# dnsoquic
DNS over QUIC

This draft uses mmark which can be found here:
mmark can be found here https://github.com/miekg/mmark


To generate the txt from the markdown use something like:

mmark -xml2 -page draft-huitema-quic-dnsoquic.md > x.xml && xml2rfc --text x.xml && rm x.xml && mv x.txt draft-huitema-quic-dnsoquic.txt
