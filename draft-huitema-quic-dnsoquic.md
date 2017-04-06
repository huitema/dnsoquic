%%%
    Title = "Specification of DNS over QUIC"
    abbrev = "DNS over QUIC"
    category = "std"
    docName= "draft-huitema-quic-dnsoquic-00"
    ipr = "trust200902"
    area = "Network"
    date = 2017-04-05T00:00:00Z
    [pi]
    toc = "yes"
    compact = "yes"
    symrefs = "yes"
    sortrefs = "yes"
    subcompact = "no"
    [[author]]
    initials="C."
    surname="Huitema"
    fullname="Christian Huitema"
    organization = "Private Octopus Inc."
      [author.address]
      email = "huitema@huitema.net"
      [author.address.postal]
      streets = ["Friday Harbor"]
      code = "WA  98250"
      country = "U.S.A"
    [[author]]
    initials="M."
    surname="Shore"
    fullname="Melinda Shore"
    organization = "No Mountain Software"
      [author.address]
      email = "melinda.shore@nomountain.net"
    [[author]]
    initials="A."
    surname="Mankin"
    fullname="Allison Mankin"
    organization = "Salesforce"
      [author.address]
      email = "amankin@salesforce.com"
    [[author]]
    initials="S."
    surname="Dickinson"
    fullname="Sara Dickinson"
    organization = "Sinodun IT"
      [author.address]
      email = "sara@sinodun.com"
      [author.address.postal]
      streets = ["Magdalen Centre", "Oxford Science Park"]
      city = "Oxford"
      code = "OX4 4GA"
      country = "U.K."

%%%


.# Abstract

This document describes the use of QUIC to provide transport privacy
for DNS.  The encryption provided by QUIC has similar properties to
that provided by TLS, while QUIC transport eliminates the end-of-
queue blocking issues inherent with TCP and provides more efficient
error corrections than UDP.  DNS over QUIC has privacy properties
similar to DNS over TLS specified in RFC 7858, and performance
similar to classic DNS over UDP.

{mainmatter}

# Introduction

Domain Name System (DNS) concepts are specified in [@!RFC1034].  This
document presents a mapping of the DNS protocol [@!RFC1035] over QUIC
transport [@!I-D.ietf-quic-transport].  The goals of this mapping are:

1.  Provide the same DNS privacy protection as DNS over TLS
    [@?RFC7858].

2.  Explore the potential performance gains of using QUIC as a DNS
    transport, versus other solutions like QUIC over UDP [@!RFC1035] or
    DNS over TLS [@?RFC7858].

3.  Participate in the definition of QUIC protocols and API, by
    outlining a use case for QUIC different from HTTP over QUIC
    [@?I-D.ietf-quic-http].

In order to achieve these goals, we will focus on the "stub to
recursive resolver" scenario also addressed by [@?RFC7858], and we will
list specific non-goals:

1.  We will not attempt to support zone transfers [@?RFC5936], as these
    are not relevant to the stub to recursive resolver scenario.

2.  We will not attempt to evade potential blocking of DNS over QUIC
    traffic by middle boxes.

Users interested in zone transfers should continue using TCP based
solutions, and users interested in evading middle-boxes should
consider using solutions like DNS over HTTPS or DNS over HTTP over
QUIC.

Specifying the transmission of an application over QUIC requires to
specify how the application messages are mapped to QUIC streams, and
generally how the application will use QUIC.  This is done for HTTP
in [@?I-D.ietf-quic-http].  The purpose of this document is to define
the way DNS can be transmitted over QUIC.

In this document, Section 2 presents the reasoning that guided our
design.  Section 3 specifies the actual mapping of DNS over QUIC.
Section 4 presents guidelines on the usage and deployment of DNS over
QUIC.


## Requirements

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in [@!RFC2119].

# Design Considerations

   This section and its subsection present the design guidelines that
   were used for the proposed mapping of DNS over QUIC.  This section is
   informative in nature.

## Focus on the stub to resolver scenario

   We can broadly classify the DNS protocol usage scenario in three
   groups: stub to recursive resolver, recursive resolver to
   authoritative, and server to server.  Our design focuses on the "stub
   to recursive resolver" scenario, and specifically to the scenario in
   which the choice of recursive resolver is manually configured in the
   stub.  In this case, the configuration will specify the name of the
   resolver, its address, how security credentials are verified, and of
   course the use of QUIC as a transport.

   We will not address the scenario in which the stub dynamically
   discovers the resolver using DHCP or IPv6 Router Advertisements.
   These scenarios would require a way to dynamically signal support for
   QUIC transport in these resolvers.  This is left for future study.

   We will also not address the recursive to authoritative scenarios.
   Authoritative resolvers are discovered dynamically through NS
   records.  In the absence of an agreed way for authoritative to signal
   support for QUIC transport, recursive resolvers would have to resort
   to some trial and error process.  At this stage of QUIC deployment,
   this would be mostly errors, and does not seem attractive.  This
   could change in the future.

   The DNS protocol is also used for zone transfers.  In the zone
   transfer scenario ([@?RFC5936]), the client emits a single AXFR query,
   and the server responds with a series of AXFR responses.  This
   creates a unique profile, in which a query results in several
   responses.  Supporting that profile would complicate the mapping of
   DNS queries over QUIC streams.  Zone transfers are not used in the
   stub to recursive scenario that we focus on, and seem to be currently
   well served by the DNS over TCP.  We will not attempt to support them
   in this proposed mapping of DNS to QUIC.

## Meet Privacy Requirements

  DNS privacy considerations are described in [@?RFC7626].  [@?RFC7858]
  defines how to mitigate these issues by transmitting DNS messages
  over TLS and TCP.  QUIC connection setup includes the negotiation of
  security parameters using TLS, as specified in [@!I-D.ietf-quic-tls],
  enabling encryption of the QUIC transport.  Transmitting DNS messages
  over QUIC will provide the same privacy protections as [@?RFC7858].

## Design for minimum latency

 QUIC is specifically designed to reduce the delay between HTTP
 queries and HTTP responses.  This is achieved through three main
 components:

 1.  Support for 0-RTT data during session resume,

 2.  Support for advanced error recovery procedures as specified in
     [@?I-D.ietf-quic-recovery].

 3.  Mitigation of head-of-queue blocking by allowing parallel
     delivery of data on multiple streams.

 The mapping of DNS to QUIC will take advantage of these features in
 three ways:

 1.  Optional support for sending 0-RTT data during session resume,

 2.  Long duration sessions carrying several DNS transactions,
     generating the sustained traffic required to benefit from
     advanced recovery features,

 3.  Mapping of each DNS Query/Response exchange to a separate stream,
     to mitigate head of queue blocking.

 These considerations will be reflected in the mapping of DNS traffic
 to QUIC streams in Section 3.2.

## Development of QUIC protocols and API

 QUIC is defined as a layered protocol, with application specific
 mapping layered on top of the generic QUIC transport.  The only
 mapping defined at this stage is HTTP over QUIC [@?I-D.ietf-quic-http].
 Adding a different mapping for a different application contributes to
 the development of QUIC.

 In the HTTP over QUIC mappings, the stream number 3 is used for
 control messages, in which client or server announce their intent to
 send headers and bodies of requests and responses and specify the
 number of the streams that will carry these headers and response.
 The advantage is that client and server can then schedule processing
 of the requests and responses according to various policies and
 priorities, and can tightly control the usage of streams.  This comes
 at the cost of some complexity, and also some performance since the
 control stream is exposed to head of queue blocking.

 We want to deliberately explore a different design, in which there is
 no control stream.  Clients and servers can initiate queries as
 determined by the DNS application logic, opening new streams as
 necessary.  This provides for maximum parallelism between queries, as
 noted in Section 2.3.  It also places constraints on the API.
 Instead of merely listening for control messages on a control stream,
 client and servers will have to be notified of the opening of a new
 stream by their peer.  Instead of orderly closing the control stream,
 client and server will have to use orderly connection closure
 mechanisms and manage the potential loss of data if closing on one
 end conflicts with opening of a stream on the other end.


## No specific middlebox bypass mechanism

 Being different from HTTP over QUIC is a design choice.  The
 advantage is that the mapping can be defined for minimal overhead and
 maximum performance.  The downside is that the difference can be
 noted by firewall and middleboxes.  There may be environments in
 which HTTP over QUIC will be allowed, but DNS over QUIC will be
 disallowed and blocked by these middle boxes.

 We are conscious that this might be a problem, but we have no
 indication on how widespread that problem might be.  It might be that
 the problem will be so acute that the only realistic solution would
 be to communicate with independent recursive resolvers using DNS over
 HTTPS, or maybe DNS over HTTP over QUIC.  Or it might be that the
 problem is rare enough and the performance gains significant enough
 that the correct solution is to use DNS over QUIC most of the time,
 and to fall back on DNS over HTTPS some of the time.  Measurements
 and experimentations will inform that decision.  In between, we
 believe that a clean design is most likely to inform the QUIC
 development, as explained in (#development-of-quic-protocols-and-api).


# Specifications

## Connection Establishment

DNS/QUIC connections are established as described in
[@!I-D.ietf-quic-transport].  During connection establishment, DNS/QUIC
support is indicated by selecting the ALPN token "dq" in the crypto
handshake.

### Draft Version Identification

**RFC Editor's Note:** Please remove this section prior to
 publication of a final version of this document.

Only implementations of the final, published RFC can identify
themselves as "dq".  Until such an RFC exists, implementations MUST
NOT identify themselves using this string.

Implementations of draft versions of the protocol MUST add the string
"-" and the corresponding draft number to the identifier.  For
example, draft-huitema-quic-dnsoquic-00 is identified using the
string "hq-h00".

### Port Selection

By default, a DNS server that supports DNS/QUIC MUST listen for and
accept QUIC connections on UDP port 853, unless it has mutual
agreement with its clients to use a port other than 853 for DNS over
QUIC.  In order to use a port other than 853, both clients and
servers would need a configuration option in their software.

By default, a DNS client desiring to use DNS over QUIC with a
particular server MUST establish a QUIC connection to UDP port 953 on
the server, unless it has mutual agreement with its server to use a
port other than port 953 for DNS over QUIC.  Such another port MUST
NOT be port 53 or port 853.  This recommendation against use of port
53 for DNS over QUIC is to avoid confusion between DNS over QUIC and
DNS over UDP as specified in [@!RFC1035].  Similarly, using port 853
would cause confusion between DNS over QUIC and DNS over DTLS as
specified in [@!RFC1035].

## Stream Mapping and Usage

The mapping of DNS traffic over QUIC streams takes advantage of the
QUIC stream features detailed in section 10 of
[@!I-D.ietf-quic-transport].

The stub to resolver DNS traffic follows a simple pattern in which
the client emits a query, and the server provides a response.  In
this case the client MUST select the next available client stream, in
conformance with section 10.2 of [@!I-D.ietf-quic-transport].

The client MUST send the DNS query over the selected stream, and MUST
indicate through the STREAM FIN mechanism that no further data will
be sent on that stream.

The server MUST send the response on the same stream, and MUST
indicate through the STREAM FIN mechanism mechanism that no further
data will be sent on that stream.

DNS query and responses are formatted as specified in [@!RFC1035].  In
contrast with DNS over TCP [@?RFC7766] and DNS over TLS [@?RFC7858],
these messages are sent without a two bytes length field prepended.

### Server initiated transactions

There are planned traffic patterns in which a server sends
unsolicited queries to a client, such as for example PUSH messages
defined in [@?I-D.ietf-dnssd-push].  When a server wishes to send such
queries it MUST select the next available server stream, in
conformance with section 10.2 of [@!I-D.ietf-quic-transport].  It will
then send the DNS query over the selected stream, and MUST indicate
through the STREAM FIN mechanism that no further data will be sent on
that stream.

The client MUST send the response on the same stream, and MUST
indicate through the STREAM FIN mechanism mechanism that no further
data will be sent on that stream.

### Stream Reset

Stream transmission may be abandoned by either party, using the
stream "reset" facility.  A stream reset indicates that one party is
unwilling to continue processing the transaction associated with the
stream.  The corresponding transaction MUST be abandoned.  A Server
Failure (ServFail, [@!RFC1035]) SHOULD be notified to the initiator of
the transaction.

TODO: should there be timers?  What if a client sends a query and the
server never sends a response?

## Closing the DNS over QUIC connection

QUIC connections are closed using the CONNECTION_CLOSE mechanisms
specified in [@!I-D.ietf-quic-transport].  Connections can be closed at
the initiative of either the client or the server.  The party
initiating the connection closure SHOULD use the QUIC GOAWAY
mechanism to initiate a graceful shutdown of a connection.

The transactions corresponding to stream number higher than indicated
in the GO AWAY frames MUST be considered failed.  Similarly, if
streams are still open when the CONNECTION_CLOSE is received, the
corresponding transactions MUST be considered failed.  In both cases,
a Server Failure (ServFail, [@!RFC1035]) SHOULD be notified to the
initiator of the transaction.

## Connection Resume and 0-RTT

A stub resolver MAY take advantage of the connection resume
mechanisms supported by QUIC transport [@!I-D.ietf-quic-transport] and
QUIC TLS [@!I-D.ietf-quic-tls].  Stub resolvers SHOULD consider
potential privacy issues associated with session resume before
deciding to use this mechanism.  These privacy issues are detailed in
Section 6.4.

When resuming a session, a stub resolver MAY take advantage of the
0-RTT mechanism supported by QUIC.  The 0-RTT mechanism MUST NOT be
used to send data that is not "replayable" transactions.  For
example, a stub resolver MAY transmit a Query as 0-RTT, but MUST NOT
transmit an Update.

# Usage and deployment

TODO: add deployment considerations here, such as how to provision
the service, how to verify certificates, how to manage fallbacks.

## Authentication

We envisage using DNS over QUIC in two main scenarios, client to to
recursive resolver and recursive resolver to authoritative resolver.
In the client to recursive resolver scenario, the authentication
requirements are the same as described in [@?RFC7858] and
[@!I-D.ietf-dprive-dtls-and-tls-profiles].  There is no need to
authenticate the client's identity in either scenario.

In the recursive resolver to authoritative server scenario, the
server's identity can be verified using the usual TLS mechanisms,
using either X.509 certificate or the DANE mechanisms [@?RFC6698].  The
server's authority to provide answers for the client's queries can be
verified using DNS Security Extensions (DNSSEC) [@?RFC4033], and there
is not much point to replicate that mechanism using QUIC security
negotiation.

## Fall Back to other protocols

If the establishment of the DNS over QUIC session fails, clients
SHOULD attempt to fall back to DNS over TLS, as specified in
[@?RFC7858].

DNS clients SHOULD remember server IP addresses that don't support
DNS over QUIC, including timeouts, connection refusals, and QUIC
handshake failures, and not request DNS over QUIC from them for a
reasonable period (such as one hour per server).  DNS clients
following an out-of-band key-pinned privacy profile ([@?RFC7858]) MAY
be more aggressive about retrying DNS-over-QUIC connection failures.

## Guidance on Connection Reuse, Close, and Reestablishment

For DNS clients that use library functions such as "getaddrinfo()"
and "gethostbyname()", current implementations are known to open and
close TCP connections for each DNS query.  To avoid excess QUIC
connections, each with a single query, clients SHOULD reuse a single
QUIC connection to the recursive resolver.  Alternatively, they may
prefer to use UDP to a DNS-over-QUIC-enabled caching resolver on the
same machine that then uses a system-wide QUIC connection to the
recursive resolver.

In order to amortize QUIC and TLS connection setup costs, clients and
servers SHOULD NOT immediately close a connection after each
response.  Instead, clients and servers SHOULD reuse existing
connections for subsequent queries as long as they have sufficient
resources.  In some cases, this means that clients and servers may
need to keep idle connections open for some amount of time.

Proper management of established and idle connections is important to
the healthy operation of a DNS server.  An implementor of DNS over
QUIC SHOULD follow best practices for DNS over TCP, as described in
[@?RFC7766].  Failure to do so may lead to resource exhaustion and
denial of service.

This document does not make specific recommendations for timeout
values on idle connections.  Clients and servers should reuse and/or
close connections depending on the level of available resources.
Timeouts may be longer during periods of low activity and shorter
during periods of high activity.  Current work in this area may also
assist DNS-over-TLS clients and servers in selecting useful timeout
values [@?RFC7828] [@TDNS].

Clients and servers that keep idle connections open MUST be robust to
termination of idle connection by either party.  As with current DNS
over TCP, DNS servers MAY close the connection at any time (perhaps
due to resource constraints).  As with current DNS over TCP, clients
MUST handle abrupt closes and be prepared to reestablish connections
and/or retry queries.

When reestablishing a DNS-over-QUIC connection that was terminated,
clients and servers SHOULD take advantage of the QUIC "resume"
mechanisms.

TODO: QUIC provides an efficient mechanism for resuming connections,
including the possibility of sending 0-RTT data.  Does that change
the tradeoff?  Is it plausible to use shorter timers than specified
for TCP?

# Security Considerations

The security considerations of DNSover QUIC should be comparable to
those of DNS over TLS [@?RFC7858].

# Privacy Considerations

QUIC over TLS is specifically designed to protect the DNS traffic
between stub and resolver from observations by third parties, and
thus protect the privacy of the stub's users.  However, the recursive
resolver has full visibility of the stub's traffic, and could be used
as an observation point, as discussed in Section 6.1.  Also, the
requests sent by the stub resolver may generate corresponding
requests from the recursive resolver to authoritative servers.
Adversaries can try to infer the stub to resolver traffic from their
observation of the resolver to authoritative traffic, as disccused in
Section 6.2.

QUIC incorporates the mechanisms of TLS 1.3 [@?I-D.ietf-tls-tls13] and
this enables QUIC enables transmission of "Zero RTT" data.  This can
provide interesting latency gains, but it raises two concerns:

1.  Adversaries could replay the zero-RTT data and infer its content
    from the behavior of the receiving server.

2.  The zero-RTT mechanism relies on TLS resume, which can provide
    linkability between successive client sessions.

We develop these issues in Section 6.3 and Section 6.4.

## Privacy of Resolver Data

The recursive resolver could easily capture a log of the traffic sent
by the stub resolver, and make it available to third parties.  This
would negate the privacy benefits of encrypting the data between stub
and resolver.

A first mitigation against that risk is the publication by the
operator of the resolver of a satisfactory privacy policy, explaining
to potential users how the data will be protected.  For example, a
resolver may decide to not keep logs or to only keep them for short
periods, and may commit to not disclose the stub's data to third
parties.

A policy voluntarily adopted by the resolver may not be sufficient if
adversaries manage to somehow gain control of the resolver, for
example using some kind of computer virus.  Mitigations against such
attacks will protective actions by the stubs.  Stubs may for example
add cover traffic to the normal set of DNS queries, or they may split
their traffic between several resolvers.  Such mitigations will
require further study.

## Backend observation of DNS traffic

Queries sent by the stub to the recursive may be served from the
recursive's cache, or may be served by forwarding the query to an
authoritative server.  Adversaries could observe the outgoing queries
and try to correlate them with the encrypted traffic received by the
recursive resolver.  In the extreme case of a resolver with only one
active stub client, this correlation is trivial.  It gets
progressively harder when resolvers serve larger number of clients.

Recursive resolvers MAY consider techniques like proactive caching to
reduce the effectiveness of this attack.  Stub clients MAY prefer
using resolvers that manage a large number of other clients, as this
will make the adversaries job harder.  In the future, stub clients
MAY attempt to mitigate this issue by using the cover traffic and
split traffic strategies discussed in Section 6.1.

## Privacy Issues With 0RTT data

The zero-RTT data can be replayed by adversaries.  That data may
triggers a request by a recursive resolver to an authoritative
resolvers.  Adversaries may be able to pick a time at which the
recursive resolver outgoing traffic is observable, and thus find out
what name was queried for in the 0-RTT data.

This risk is in fact a subset of the general problem of observing the
behavior of the recursive resolver discussed in Section 6.2.  The
attack is partially mitigated by reducing the observability of this
traffic.  However, the risk is amplified for 0-RTT data, because the
attacker might replay it at chosen times, several times.

The recommendation in [@?I-D.ietf-tls-tls13] is that the capability to
use 0-RTT data should be turned off by default, on only enabled if
the user clearly understands the associated risks.

## Privacy Issues With Session Resume

The QUIC session resume mechanism reduces the cost of reestablishing
sessions and enables zero-RTT data.  There is a linkability issue
associated with session resume, if the same resume token is used

several times, but this risk is mitigated by the mechanisms
incorporated in QUIC and in TLS 1.3.  With these mechanisms, clients
and servers can cooperate to avoid linkability by third parties.
However, the server will always be able to link the resumed session
to the initial session.  This creates a virtual long duration
session.  The series of requests in that section can be used by the
server to identify the client.

Enabling the server to link client sessions through session resume is
probably not a large addiional risk if the client's connectivity did
not change between the sessions, since the two sessions can probably
be correlated by comparing the IP addresses.  On the other hand, if
the addresses did change, the client SHOULD consider whether the
linkability risk exceeds the privacy benefits.  This evaluation will
obviously depend on the level of trust between stub and recursive.


# IANA Considerations

## Registration of DNS over QUIC Identification String

   This document creates a new registration for the identification of
   DNS over QUIC in the "Application Layer Protocol Negotiation (ALPN)
   Protocol IDs" registry established in [@!RFC7301].

   The "dq" string identifies DNS over QUIC:

   Protocol:  DNS over QUIC

   Identification Sequence:  0x64 0x71 ("dq")

   Specification:  This document

## Reservation of port 953

   IANA is required to add the following value to the "Service Name and
   Transport Protocol Port Number Registry" in the System Range.  The
   registry for that range requires IETF Review or IESG Approval
   [@?RFC6335], and such a review was requested using the early allocation
   process [@?RFC7120] for the well-known TCP port in this document.

       Service Name           domain-s
       Port Number            953
       Transport Protocol(s)  TCP/UDP
       Assignee               IESG
       Contact                IETF Chair
       Description            DNS query-response protocol run over QUIC
       Reference              This document

# Acknowledgements

This document liberally borrows text from [@?I-D.ietf-quic-http]
authored by Mike Bishop, and from [@?RFC7858] authored by Zi Hu, Liang
Zhu, John Heidemann, Allison Mankin, Duane Wessels, and Paul Hoffman.

The privacy issue with 0-RTT data and session resume were analyzed by
Daniel Kahn Gillmor (DKG) in a message to the IETF "DPRIV" working
group [@DNS0RTT].

Thanks to our wide cast of supporters.

<reference anchor="DNS0RTT" target="https://www.ietf.org/mail-archive/web/dns-privacy/current/msg01276.html">
  <front>
    <title>DNS + 0-RTT</title>
    <author initials="D." surname="Kahn Gillmor" fullname="Daniel Kahn Gillmor">
      <organization/>
    </author>
    <date year="2016" month="April" day="06" />
  </front>
  <seriesInfo name="Message" value="DNS-Privacy WG mailing list"/>
</reference>

<reference anchor="TDNS" target="http://dx.doi.org/10.1109/SP.2015.18">
        <front>
          <title>Connection-Oriented DNS to Improve Privacy and Security</title>
          <author initials="L." surname="Zhu" fullname="Liang Zhu"/>
          <author initials="Z." surname="Hu" fullname="Zi Hu"/>
          <author initials="J." surname="Heidemann" fullname="John Heidemann"/>
          <author initials="D." surname="Wessels" fullname="Duane Wessels"/>
          <author initials="A." surname="Mankin" fullname="Allison Mankin"/>
          <author initials="N." surname="Somaiya" fullname="Nikita Somaiya"/>
          <date/>
        </front>
        <seriesInfo name="2015 IEEE Symposium" value="on Security and Privacy (SP)" />
   <seriesInfo name="DOI" value="10.1109/SP.2015.18" />
      </reference>

{backmatter}


