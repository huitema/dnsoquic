---
title: Specification of DNS over Dedicated QUIC Connections
abbrev: DNS over Dedicated QUIC
category: std
docName: draft-huitema-dprive-dnsoquic-00
    
stand_alone: yes

ipr: trust200902
area: Transport
kw: Internet-Draft

coding: us-ascii
pi: [toc, sortrefs, symrefs, comments]

author:
      -
        ins: C. Huitema
        name: Christian Huitema
        org: Private Octopus Inc.
        street: 427 Golfcourse Rd
        city: Friday Harbor
        code: WA 98250
        country: U.S.A
        email: huitema@huitema.net
      -
        ins: A. Mankin
        name: Allison Mankin
        org: Salesforce
        email: amankin@salesforce.com
      -
        ins: S. Dickinson
        name: Sara Dickinson
        org: Sinodun IT
        street: Magdalen Centre
        street: Oxford Science Park
        city: Oxford
        code: OX4 4GA
        country: U.K.
        email: sara@sinodun.com

informative:
  DNS0RTT:
    target: https://www.ietf.org/mail-archive/web/dns-privacy/current/msg01276.html
    title: DNS + 0-RTT
    author:
       -
        ins: D. Kahn Gillmor
        name: Daniel Kahn Gillmor
    date: 2016-04-06
    seriesinfo:
        Message: to DNS-Privacy WG mailing list

  TDNS:
    target: http://dx.doi.org/10.1109/SP.2015.18
    title: Connection-Oriented DNS to Improve Privacy and Security
    author:
       -
        ins: L. Zhu
        name: Liang Zhu
       -
        ins: Z. Hu
        name: Zi Hu
       -
        ins: J. Heidemann
        name: John Heidemann
       -
        ins: D. Wessels
        name: Duane Wessels
       -
        ins: A. Mankin
        name: Allison Mankin
       -
        ins: N. Somaiya 
        name: Nikita Somaiya
    date: 2015-05-21
    seriesinfo:
        2015: IEEE Symposium on Security and Privacy (SP)
        DOI: 10.1109/SP.2015.18

--- abstract

This document describes the use of QUIC to provide transport privacy for DNS.
The encryption provided by QUIC has similar properties to that provided by TLS,
while QUIC transport eliminates the head-of-line blocking issues inherent with
TCP and provides more efficient error corrections than UDP. DNS over QUIC
(DoQ) has privacy properties similar to DNS over TLS (DoT) specified in RFC7858,
and performance characteristics similar to classic DNS over UDP.

--- middle

# Introduction

Domain Name System (DNS) concepts are specified in {{!RFC1034}}.  This
document presents a mapping of the DNS protocol {{!RFC1035}} over QUIC
transport {{!I-D.ietf-quic-transport}} {{!I-D.ietf-quic-tls}}. DNS over QUIC is
refered here as DoQ, in line with the terminology presented in
{{!I-D.ietf-dnsop-terminology-ter}}. The
goals of the DoQ mapping are:

1.  Provide the same DNS privacy protection as DNS over TLS (DoT)
    {{?RFC7858}}. This includes an option for the client to 
    authenticate the server by means of an authentication domain
    name {{!RFC8310}}.

2.  Provide an improved level of source address validation for DNS
    servers compared to classic DNS over UDP {{!RFC1035}}.

3.  Provide a transport that is not constrained by path MTU limitations on the 
    size of DNS responses it can send.

4.  Explore the potential performance gains of using QUIC as a DNS
    transport, versus other solutions like DNS over UDP (DNS/UDP) {{!RFC1035}} or
    DoT {{?RFC7858}}.

In order to achieve these goals, the focus of this document is limited
to the "stub to recursive resolver" scenario also addressed by {{?RFC7858}}.
That is, the protocol described here works for queries and responses between
stub clients and recursive servers. The specific non-goals of this document are:

1.  No attempt is made to support zone transfers {{?RFC5936}}, as these
    are not relevant to the stub to recursive resolver scenario.

2.  No attempt is made to evade potential blocking of DNS/QUIC
    traffic by middleboxes.

Users interested in zone transfers should continue using TCP based
solutions and will also want to take note of work in progress to
encrypt zone transfers using DoT {{?I-D.ietf-dprive-xfr-over-tls}}.
Users interested in evading middleboxes should
consider using solutions like DNS/HTTPS {{?RFC8484}}.

Specifying the transmission of an application over QUIC requires
specifying how the application's messages are mapped to QUIC streams, and
generally how the application will use QUIC.  This is done for HTTP
in {{?I-D.ietf-quic-http}}.  The purpose of this document is to define
the way DNS messages can be transmitted over QUIC.

In this document, {{design-considerations}} presents the reasoning that guided
the proposed design. {{specifications}} specifies the actual mapping of DoQ.
{{implementation-requirements}} presents guidelines on the implementation, usage
and deployment of DoQ.


# Key Words

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in {{!RFC8174}}.


# Design Considerations

This section and its subsection present the design guidelines that
were used for DoQ.  This section is
informative in nature.

## Scope is Limited to the Stub to Resolver Scenario

Usage scenarios for the DNS protocol can be broadly classified in three
groups: stub to recursive resolver, recursive resolver to
authoritative server, and server to server.  This design focuses only on the 
"stub to recursive resolver" scenario following the approach taken in
{{?RFC7858}} and {{!RFC8310}}.

QUESTION: Should this document specify any aspects of configuration of
discoverability differently to DoT?

No attempt is made to address the recursive to authoritative scenarios.
Authoritative resolvers are discovered dynamically through NS records. It is
noted that at the time of writing work is ongoing in the DPRIVE working group to
attempt to address the analogous problem for DoT
{{?I-D.ietf-dprive-phase2-requirements}}. In the absence of an agreed way for
authoritative to signal support for QUIC transport, recursive resolvers would
have to resort to some trial and error process. At this stage of QUIC
deployment, this would be mostly errors, and does not seem attractive. This
could change in the future.

The DNS protocol is also used for zone transfers. In the zone transfer scenario
{{?RFC5936}}, the client emits a single AXFR query, and the server responds
with a series of AXFR responses. This creates a unique profile, in which a query
results in several responses. Supporting that profile would complicate the
mapping of DNS queries over QUIC streams. Zone transfers are not used in the
stub to recursive scenario that is the focus here, and seem to be currently well
served by using DNS over TCP. There is no attempt to support them in
this proposed mapping of DNS to QUIC.

## Provide DNS Privacy

DNS privacy considerations are described in {{?RFC7626}}. {{?RFC7858}} defines how
to mitigate some of these issues by transmitting DNS messages over TLS and TCP
and {{!RFC8310}} specifies Strict and Opportunistic Usage Profiles for DoT
including how stub resolvers can authenticate recursive resolvers.

QUIC connection setup includes the negotiation of security parameters using TLS,
as specified in {{!I-D.ietf-quic-tls}}, enabling encryption of the QUIC
transport. Transmitting DNS messages over QUIC will provide essentially the same
privacy protections as {{?RFC7858}} and {{!RFC8310}}. Further discussion on this
is provided in {{privacy-considerations}}.

## Design for Minimum Latency

QUIC is specifically designed to reduce the delay between HTTP
queries and HTTP responses.  This is achieved through three main
components:

 1.  Support for 0-RTT data during session resumption.

 2.  Support for advanced error recovery procedures as specified in
     {{?I-D.ietf-quic-recovery}}.

 3.  Mitigation of head-of-line blocking by allowing parallel
     delivery of data on multiple streams.

This mapping of DNS to QUIC will take advantage of these features in
three ways:

 1.  Optional support for sending 0-RTT data during session resumption
     (the security and privacy implications of this are discussed 
     in later sections).

 2.  Long-lived QUIC connections over which multiple DNS transactions
     are performed,
     generating the sustained traffic required to benefit from
     advanced recovery features.

 3.  Fast resumption of QUIC connections to manage the disconnect-on-idle
     feature of QUIC without incurring retransmission time-outs.

 4.  Mapping of each DNS Query/Response transaction to a separate stream,
     to mitigate head-of-line blocking.

These considerations will be reflected in the mapping of DNS traffic
to QUIC streams in {{stream-mapping-and-usage}}.

## No Specific Middlebox Bypass Mechanism

The mapping of DNS over QUIC is defined for minimal overhead and
maximum performance. This means a different traffic profile than HTTP over 
QUIC. This difference can be
noted by firewalls and middleboxes.  There may be environments in
which HTTP/QUIC will be allowed, but DoQ will be
disallowed and blocked by these middle boxes.

It is recognized that this might be a problem, but there is currently no
indication on how widespread that problem might be. The problem might be
acute enough that the only realistic solution would
be to communicate with independent recursive resolvers using DNS/HTTPS,
or maybe DNS/HTTP/QUIC.  Or the problem might be rare enough and the
performance gains significant enough
that the appropriate solution would be to use DoQ most of the time,
and fall back to DNS/HTTPS some of the time. Measurements
and experimentation will inform that decision.  

It may indeed turn out that the complexity and overhead concerns are
negligible compared to the potential advantages of DNS/HTTPS, such
as integration with web services or firewall traversal, and that DoQ
does not provide sufficient performance gains to justify a new protocol. We
will evaluate that once implementations are available and can be compared.

# Specifications

## Connection Establishment

DoQ connections are established as described in
{{!I-D.ietf-quic-transport}}.  During connection establishment, DoQ
support is indicated by selecting the ALPN token "dq" in the crypto
handshake.

### Draft Version Identification

**RFC Editor's Note:** Please remove this section prior to
 publication of a final version of this document.

Only implementations of the final, published RFC can identify
themselves as "doq".  Until such an RFC exists, implementations MUST
NOT identify themselves using this string.

Implementations of draft versions of the protocol MUST add the string
"-" and the corresponding draft number to the identifier.  For
example, draft-huitema-dprive-dnsoquic-00 is identified using the
string "doq-h00".

### Port Selection

By default, a DNS server that supports DoQ MUST listen for and
accept QUIC connections on the dedicated UDP port TBD (number to be
defined in {{iana-considerations}}, unless it has mutual
agreement with its clients to use a port other than TBD for DoQ.
In order to use a port other than TBD, both clients and
servers would need a configuration option in their software.

By default, a DNS client desiring to use DoQ with a
particular server MUST establish a QUIC connection to UDP port TBD on
the server, unless it has mutual agreement with its server to use a
port other than port TBD for DoQ.  Such another port MUST
NOT be port 53 or port 853.  This recommendation against use of port
53 for DoQ is to avoid confusion between DoQ and
DNS/UDP as specified in {{!RFC1035}}.  Similarly, using port 853
would cause confusion between DoQ and DNS/DTLS as
specified in {{?RFC8094}}.

## Stream Mapping and Usage

The mapping of DNS traffic over QUIC streams takes advantage of the
QUIC stream features detailed in Section 2 of {{!I-D.ietf-quic-transport}}.

The stub to resolver DNS traffic follows a simple pattern in which
the client sends a query, and the server provides a response.  This design
specifies that for each subsequent query on a QUIC connection the client MUST 
select the next available client-initiated bidirectional stream, in
conformance with {{!I-D.ietf-quic-transport}}.

The client MUST send the DNS query over the selected stream, and MUST
indicate through the STREAM FIN mechanism that no further data will
be sent on that stream.

The server MUST send the response on the same stream, and MUST
indicate through the STREAM FIN mechanism that no further
data will be sent on that stream.

Therefore, a single client initiated DNS transaction consumes a single stream.
This means that the client's first query occurs on QUIC stream 0, the second on 4,
and so on.

### Server Initiated Transactions

There are planned traffic patterns in which a server sends
unsolicited queries to a client, such as for example PUSH messages
defined in {{?I-D.ietf-dnssd-push}}. 
These occur when a client subscribes to
changes for a particular DNS RRset or resource record type. When a 
PUSH server wishes to send such
updates it MUST select the next available server initiated
bidirectional stream, in
conformance with {{!I-D.ietf-quic-transport}}.  

The server MUST send the DNS query over the selected stream, and MUST indicate
through the STREAM FIN mechanism that no further data will be sent on
that stream.

The client MUST send the response on the same stream, and MUST
indicate through the STREAM FIN mechanism that no further
data will be sent on that stream.

Therefore a single server initiated DNS transaction consumes a single stream. 
This means that the 
servers's first query occurs on QUIC stream 1, the second on 5, and so on.

### Transaction Errors

Peers normally complete transactions by sending a DNS response on the
transaction's stream, including in cases where the DNS response indicates an
error. There are two exceptions: internal errors, and cancelled transactions.

If a peer is incapable of sending a DNS response due to an internal
error, it may issue a QUIC Stream Reset indicating with error code DOQ_INTERNAL_ERROR.
The corresponding transaction MUST be abandoned.  A Server
Failure (SERVFAIL, {{!RFC1035}}) SHOULD be notified to the initiator of
the transaction.

### Cancelling a Transaction

The initiator of a Transaction MAY indicate that it is not interesting any
more in receiving the response by either:

* Sending a QUIC Stream Reset frame on the transaction specific stream if the STREAM FIN has not yet been sent,

* or, sending a QUIC Stop Sending frame on the transaction specific stream.

In both case, the error code DOQ_TRANSACTION_CANCELLED is used.

There is no guarantee that the peer will receive the Stop Sending frame before completing the transaction.
If it does, it SHOULD send a QUIC Stream Reset on the transaction specific stream, using the 
error code DOQ_TRANSACTION_CANCELLED.

## Connection Management

Section 10 of the QUIC transport specifications {{!I-D.ietf-quic-transport}}
specifies that connections can be closed in three ways:

* idle timeout
* immediate close
* stateless reset

Clients and servers implementing DNS over QUIC SHOULD negotiate use of
the idle timeout. Closing on idle-timeout is done without any packet exchange,
which minimizes protocol overhead. This document does not recommend 
a specific value of the idle timer. 

Clients SHOULD monitor the idle time incurred on their connection to
the server, defined by the time spend since the last packet from
the server has been received. When a client prepares to send a new DNS
query to the server, it will check whether the idle time is sufficient
lower than the idle timer. If it is, the client will send the DNS
query over the existing connection. If not, the client will establish
a new connection and send the query over that connection. 

Clients MAY discard their connection to the server before the idle
timeout expires. If they do that, they SHOULD close the connection
explicitly, using QUIC's CONNECTION_CLOSE mechanisms, and indicating
the Application reason "No Error".

Clients and servers may close the connection for a variety of other
reasons, indicated using QUIC's CONNECTION_CLOSE. Client and servers
that send packets over a connection discarded by their peer MAY
receive a stateless reset indication. If a connection fails,
all queries in progress over the connection MUST be considered failed,
and aServer Failure (SERVFAIL, {{!RFC1035}}) SHOULD be notified
to the initiator of the transaction.

## Connection Resume and 0-RTT 

A stub resolver MAY take advantage of the connection resume
mechanisms supported by QUIC transport {{!I-D.ietf-quic-transport}} and
QUIC TLS {{!I-D.ietf-quic-tls}}.  Stub resolvers SHOULD consider
potential privacy issues associated with session resume before
deciding to use this mechanism.  These privacy issues are detailed in
{{privacy-issues-with-session-resume}}.

When resuming a session, a stub resolver MAY take advantage of the
0-RTT mechanism supported by QUIC.  The 0-RTT mechanism MUST NOT be
used to send data that is not "replayable" transactions.  For
example, a stub resolver MAY transmit a Query as 0-RTT, but MUST NOT
transmit an Update.

## DoQ Error Codes

The following error codes are defined for use when abruptly terminating streams,
aborting reading of streams, or immediately closing connections:

DOQ_NO_ERROR (0x00):
: No error.  This is used when the connection or stream needs to be closed, but
  there is no error to signal.

DOQ_INTERNAL_ERROR (0x01):
: The DoQ implementation encountered an internal error and is incapable of
  pursuing the transaction or the connection.

DOQ_TRANSACTION_CANCELLED (0x02):
: Used in a Stop Sending request to signal that the originator of the query is
  not anymore interested by the result. Also used by the recipient of the
  request when issuing a Stream Reset in response to a Stop Sending request.

DOQ_TRANSPORT_PARAMETER_ERROR (0x03):
: One or some of the transport parameters proposed by the peer are not acceptable.

# Implementation Requirements

## Authentication

For the stub to recursive resolver scenario, the authentication
requirements are the same as described in {{?RFC7858}} and
{{!RFC8310}}.  There is no need to
authenticate the client's identity in either scenario.

## Fall Back to Other Protocols on Connection Failure

If the establishment of the DoQ connection fails, clients
SHOULD attempt to fall back to DoT and then potentially clear 
text, as specified in {{?RFC7858}} and 
{{!RFC8310}}, depending on their privacy
profile.

DNS clients SHOULD remember server IP addresses that don't support
DoQ, including timeouts, connection refusals, and QUIC
handshake failures, and not request DoQ from them for a
reasonable period (such as one hour per server).  DNS clients
following an out-of-band key-pinned privacy profile ({{?RFC7858}}) MAY
be more aggressive about retrying DoQ connection failures.

## Address Validation

The QUIC transport specification defines Address Validation procedures
to avoid servers being used in address amplification attacks (see
section 8 of {{!I-D.ietf-quic-transport}}). DoQ implementations
MUST conform to this specification, which limits the worst case
amplification to a factor 3.

DoQ implementations SHOULD consider configuring servers to use
the Address Validation using Retry Packets procedure defined in
section 8.1.2 of {{!I-D.ietf-quic-transport}}). This procedure
imposes a 1-RTT delay for verifying the return routability of the
source address of a client, similar to the DNS Cookies mechanism
defined in {{!RFC7873}}.

DoQ implementations that configure Address Validation using Retry
Packets SHOULD implement the Address Validation for Future Connections
procedure defined in section 8.1.3 of {{!I-D.ietf-quic-transport}}).
This define how servers can send NEW TOKEN frames to clients after the
client address is validated, in order to avoid the 1-RTT penalty during
subsequent connections by the client from the same address.

## Response Sizes

DoQ does not suffer from the same limitations on the size of queries and
responses that as DNS/UDP {{!RFC1035}} does. Queries and Responses are sent
on QUIC streams, which in theory can carry up to 2^62 bytes. However,
clients or servers MAY impose a limit on the maximum size of data that
they can accept over a given stream. This is controlled in QUIC by
the transport parameters:

* initial_max_stream_data_bidi_local: when set by the client, specifies
  the amount of data that servers can send on a "response" stream without
  waiting for a MAX_STREAM_DATA frame.

* initial_max_stream_data_bidi_remote: when set by the server, specifies
  the amount of data that clients can send on a "query" stream without
  waiting for a MAX_STREAM_DATA frame.

Clients and servers SHOULD treat these parameters as the practical maximum
of queries and responses. If the EDNS parameters of a Query indicate a lower
message size, servers MUST comply with that indication.

## DNS Message IDs

When sending queries over a QUIC connection, the DNS Message ID MUST be set to
zero.

## Padding {#padding}

There are mechanisms specified for both padding individual DNS messages
{{?RFC7830}}, {{?RFC8467}} and padding within QUIC
packets (see Section 8.6 of {{!I-D.ietf-quic-transport}}), which may contain
multiple frames.

Implementations SHOULD NOT use DNS options for
padding individual DNS messages, because QUIC transport
MAY transmit multiple STREAM frames containing separate DNS messages in
a single QUIC packet. Instead, implementations SHOULD use QUIC PADDING frames
to align the packet length to a small set of fixed sizes, aligned with
the recommendations of {{?RFC8467}}.

## Connection Handling

{{?RFC7766}} provides updated
guidance on DNS/TCP much of which is applicable to DoQ. This 
section attempts to specify how those considerations apply to DoQ.

### Connection Reuse

Historic implementations of DNS stub resolvers are known to open and
close TCP connections for each DNS query. To avoid excess QUIC
connections, each with a single query, clients SHOULD reuse a single
QUIC connection to the recursive resolver. 

In order to achieve performance on par with UDP, DNS clients SHOULD
send their queries concurrently over the QUIC streams on a QUIC connection.
That is, when a DNS client 
sends multiple queries to a server over a QUIC connection, it SHOULD NOT wait
for an outstanding reply before sending the next query.

### Connection Close

In order to amortize QUIC and TLS connection setup costs, clients and
servers SHOULD NOT immediately close a QUIC connection after each
response.  Instead, clients and servers SHOULD reuse existing
QUIC connections for subsequent queries as long as they have sufficient
resources.  In some cases, this means that clients and servers may
need to keep idle connections open for some amount of time.

Under normal operation DNS clients typically initiate connection
closing on idle connections; however, DNS servers can close the
connection if the idle timeout set by local policy is exceeded.
Also, connections can be closed by either end under unusual
conditions such as defending against an attack or system failure/
reboot.

Clients and servers that keep idle connections open MUST be robust to
termination of idle connection by either party.  As with current DNS
over TCP, DNS servers MAY close the connection at any time (perhaps
due to resource constraints).  As with current DNS/TCP, clients
MUST handle abrupt closes and be prepared to reestablish connections
and/or retry queries.

### Idle Timeouts

Proper management of established and idle connections is important to
the healthy operation of a DNS server.  An implementation of DoQ
SHOULD follow best practices for DNS/TCP, as described in
{{?RFC7766}}.  Failure to do so may lead to resource exhaustion and
denial of service.

This document does not make specific recommendations for timeout
values on idle connections.  Clients and servers should reuse and/or
close connections depending on the level of available resources.
Timeouts may be longer during periods of low activity and shorter
during periods of high activity.  Current work in this area may also
assist DoT clients and servers in selecting useful timeout
values {{?RFC7828}} {{?RFC8490}} {{TDNS}}.

Clients that are willing to use QUIC's 0-RTT mechanism can reestablish
connections and send transactions on the new connection with minimal
delay overhead. These clients MAY chose low values of the idle timer,
but SHOULD NOT pick value lower than 20 seconds.

Per section 10.2 of QUIC transport specification, the effective value of
the idle timeout is  computed as the minimum of the values advertised by
the two endpoints.

## Flow Control Mechanisms

Servers and Clients manage flow control as specified in QUIC.

Servers MAY use the "maximum stream ID" option of the QUIC
transport to limit the number of streams opened by the
client. This mechanism will effectively limit the number of 
DNS queries that a client can send.

# Security Considerations

The security considerations of DoQ should be comparable to
those of DoT {{?RFC7858}}.

# Privacy Considerations

DoQ is specifically designed to protect the DNS traffic
between stub and resolver from observations by third parties, and
thus protect the privacy of queries from the stub.  However, the recursive
resolver has full visibility of the stub's traffic, and could be used
as an observation point, as discussed in {{?I-D.ietf-dprive-rfc7626-bis}}. These considerations
do not differ between DoT and DoQ and are not discussed
further here. 

QUIC incorporates the mechanisms of TLS 1.3 {{?RFC8446}} and
this enables QUIC transmission of "Zero-RTT" data.  This can
provide interesting latency gains, but it raises two concerns:

1.  Adversaries could replay the zero-RTT data and infer its content
    from the behavior of the receiving server.

2.  The zero-RTT mechanism relies on TLS resume, which can provide
    linkability between successive client sessions.

These issues are developed in {{privacy-issues-with-zero-rtt-data}} and 
{{privacy-issues-with-session-resume}}.

## Privacy Issues With Zero RTT data

The zero-RTT data can be replayed by adversaries.  That data may
triggers a query by a recursive resolver to an authoritative
resolvers.  Adversaries may be able to pick a time at which the
recursive resolver outgoing traffic is observable, and thus find out
what name was queried for in the 0-RTT data.

This risk is in fact a subset of the general problem of observing the
behavior of the recursive resolver discussed in  {{?RFC7626}}. The
attack is partially mitigated by reducing the observability of this
traffic.  However, the risk is amplified for 0-RTT data, because the
attacker might replay it at chosen times, several times.

The recommendation in {{?RFC8446}} is that the capability to
use 0-RTT data should be turned off by default, on only enabled if
the user clearly understands the associated risks.

QUESTION: Should 0-RTT only be used with Opportunistic profiles (i.e.
disabled by default for Strict only)?

## Privacy Issues With Session Resume

The QUIC session resume mechanism reduces the cost of reestablishing
sessions and enables zero-RTT data.  There is a linkability issue
associated with session resume, if the same resume token is used
several times, but this risk is mitigated by the mechanisms
incorporated in QUIC and in TLS 1.3.  With these mechanisms, clients
and servers can cooperate to avoid linkability by third parties.
However, the server will always be able to link the resumed session
to the initial session.  This creates a virtual long duration
session.  The series of queries in that session can be used by the
server to identify the client.

Enabling the server to link client sessions through session resume is
probably not a large additional risk if the client's connectivity did
not change between the sessions, since the two sessions can probably
be correlated by comparing the IP addresses.  On the other hand, if
the addresses did change, the client SHOULD consider whether the
linkability risk exceeds the privacy benefits.  This evaluation will
obviously depend on the level of trust between stub and recursive.

## Traffic Analysis

Even though QUIC packets are encrypted, adversaries can gain information from
observing packet lengths, in both queries and responses, as well as packet
timing. Many DNS requests are emitted by web browsers. Loading a specific
web page may require resolving dozen of DNS names. If an application
adopts a simple mapping of one query or response per packet, or "one 
QUIC STREAM frame per packet", then the succession of packet lengths may
provide enough information to identify the requested site.

Implementations SHOULD use the mechanisms defined in {{padding}} to
mitigate this attack.

# IANA Considerations

## Registration of DoQ Identification String

   This document creates a new registration for the identification of
   DoQ in the "Application Layer Protocol Negotiation (ALPN)
   Protocol IDs" registry established in {{!RFC7301}}.

   The "doq" string identifies DoQ:

   Protocol:  DoQ

   Identification Sequence:  0x64 0x71 ("dq")

   Specification:  This document

## Reservation of Dedicated Port

   IANA is required to add the following value to the "Service Name and
   Transport Protocol Port Number Registry" in the System Range.  The
   registry for that range requires IETF Review or IESG Approval
   {{?RFC6335], and such a review was requested using the early allocation
   process {{?RFC7120] for the well-known UDP port in this document. Since
   port 853 is reserved for 'DNS query-response protocol run over TLS' 
   consideration is requested for reserving port TBD for 'DNS query-response  
   protocol run over QUIC'.

       Service Name           domain-s
       Transport Protocol(s)  TCP/UDP
       Assignee               IESG
       Contact                IETF Chair
       Description            DNS query-response protocol run over QUIC
       Reference              This document

### Port number 784 for experimentations

**RFC Editor's Note:** Please remove this section prior to
 publication of a final version of this document.

Early experiments MAY use port 784. This port is marked in the IANA 
registry as unassigned.

# Acknowledgements

This document liberally borrows text from {{?I-D.ietf-quic-http}}
edited by Mike Bishop, and from {{?RFC7858}} authored by Zi Hu, Liang
Zhu, John Heidemann, Allison Mankin, Duane Wessels, and Paul Hoffman.

The privacy issue with 0-RTT data and session resume were analyzed by
Daniel Kahn Gillmor (DKG) in a message to the IETF "DPRIV" working
group {{DNS0RTT}}.

Thanks to our wide cast of supporters.


--- back


