---
title: Specification of DNS over Dedicated QUIC Connections
abbrev: DNS over Dedicated QUIC
category: std
docName: draft-ietf-dprive-dnsoquic-03
    
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
        ins: S. Dickinson
        name: Sara Dickinson
        org: Sinodun IT
        street: Magdalen Centre
        street: Oxford Science Park
        city: Oxford
        code: OX4 4GA
        country: U.K.
        email: sara@sinodun.com
      -
        ins: A. Mankin
        name: Allison Mankin
        org: Salesforce
        email: allison.mankin@gmail.com


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

--- abstract

This document describes the use of QUIC to provide transport privacy for DNS.
The encryption provided by QUIC has similar properties to that provided by TLS,
while QUIC transport eliminates the head-of-line blocking issues inherent with
TCP and provides more efficient error corrections than UDP. DNS over QUIC
(DoQ) has privacy properties similar to DNS over TLS (DoT) specified in RFC7858,
and latency characteristics similar to classic DNS over UDP.

--- middle

# Introduction

Domain Name System (DNS) concepts are specified in "Domain names - concepts and
facilities" {{!RFC1034}}. The transmission of DNS queries and responses over
UDP and TCP is specified in "Domain names - implementation and specification"
{{!RFC1035}}. This document presents a mapping of the DNS protocol over the
QUIC transport {{!RFC9000}} {{!RFC9001}}. DNS over QUIC is referred here as DoQ,
in line with "DNS Terminology" {{!I-D.ietf-dnsop-rfc8499bis}}. The goals of the
DoQ mapping are:


1.  Provide the same DNS privacy protection as DNS over TLS (DoT)
    {{?RFC7858}}. This includes an option for the client to 
    authenticate the server by means of an authentication domain
    name as specified in "Usage Profiles for DNS over TLS and DNS
    over DTLS" {{!RFC8310}}.

2.  Provide an improved level of source address validation for DNS
    servers compared to classic DNS over UDP.

3.  Provide a transport that is not constrained by path MTU limitations on the 
    size of DNS responses it can send.

4.  Explore the characteristics of using QUIC as a DNS
    transport, versus other solutions like DNS over UDP {{!RFC1035}},
    DNS over TLS (DoT) {{?RFC7858}}, or DNS over HTTPS (DoH) {{?RFC8484}}.

In order to achieve these goals, and to support ongoing work on encryption of
DNS, the scope of this document includes 

* the "stub to recursive resolver" scenario
* the "recursive resolver to authoritative nameserver" scenario and 
* the "nameserver to nameserver" scenario (mainly used for zone transfers (XFR) {{!RFC1995}}, {{RFC5936}}). 

In other words, this document is intended to specify QUIC as a general purpose
transport for DNS.

The specific non-goals of this document are:

1.  No attempt is made to evade potential blocking of DNS over QUIC
    traffic by middleboxes.

3. No attempt to support server initiated transactions, which are used only in 
   DNS Stateful Operations (DSO) {{?RFC8490}}.

Specifying the transmission of an application over QUIC requires specifying how
the application's messages are mapped to QUIC streams, and generally how the
application will use QUIC. This is done for HTTP in "Hypertext Transfer
Protocol Version 3 (HTTP/3)"{{?I-D.ietf-quic-http}}. The purpose of this
document is to define the way DNS messages can be transmitted over QUIC.

In this document, {{design-considerations}} presents the reasoning that guided
the proposed design. {{specifications}} specifies the actual mapping of DoQ.
{{implementation-requirements}} presents guidelines on the implementation,
usage and deployment of DoQ.


# Key Words

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in BCP 14 {{!RFC8174}}.


# Document work via GitHub

(RFC EDITOR NOTE: THIS SECTION TO BE REMOVED BEFORE PUBLICATION)The Github
repository for this document is at https://github.com/huitema/dnsoquic.
Proposed text and editorial changes are very much welcomed there, but any
functional changes should always first be discussed on the IETF DPRIVE WG
(dns-privacy) mailing list.

# Design Considerations

This section and its subsections present the design guidelines that were used
for DoQ. This section is informative in nature.

## Provide DNS Privacy

DoT {{?RFC7858}} defines how to mitigate some of the issues described in "DNS
Privacy Considerations" {{?RFC7626}} by specifying how to transmit DNS messages
over TLS. The "Usage Profiles for DNS over TLS and DNS over DTLS" {{!RFC8310}}
specify Strict and Opportunistic Usage Profiles for DoT including how stub
resolvers can authenticate recursive resolvers.

QUIC connection setup includes the negotiation of security parameters using
TLS, as specified in "Using TLS to Secure QUIC" {{!RFC9001}},
enabling encryption of the QUIC transport. Transmitting DNS messages over QUIC
will provide essentially the same privacy protections as DoT {{?RFC7858}}
including Strict and Opportunistic Usage Profiles {{!RFC8310}}. Further
discussion on this is provided in {{privacy-considerations}}.

## Design for Minimum Latency

QUIC is specifically designed to reduce the delay between HTTP
queries and HTTP responses.  This is achieved through three main
components:

 1.  Support for 0-RTT data during session resumption.

 2.  Support for advanced error recovery procedures as specified in
     "QUIC Loss Detection and Congestion Control" {{?I-D.ietf-quic-recovery}}.

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
     to mitigate head-of-line blocking. This enables servers to respond
     to queries "out of order". It also enables clients to process
     responses as soon as they arrive, without having to wait for in
     order delivery of responses previously posted by the server.

These considerations will be reflected in the mapping of DNS traffic
to QUIC streams in {{stream-mapping-and-usage}}.

## No Specific Middlebox Bypass Mechanism

The mapping of DoQ is defined for minimal overhead and maximum
performance. This means a different traffic profile than HTTP3 over QUIC. This
difference can be noted by firewalls and middleboxes. There may be environments
in which HTTP3 over QUIC will be able to pass through, but DoQ will be blocked
by these middle boxes.

## No Server Initiated Transactions

As stated in {{introduction}}, this document does not specify support for
server initiated transactions. DSO is only applicable for DNS over TCP and DNS
over TLS. DSO is not applicable to DNS over HTTP since HTTP has its own
mechanism for managing sessions, and this is incompatible with the DSO; the
same is true for DoQ.


# Specifications

## Connection Establishment

DoQ connections are established as described in the QUIC transport
specification {{!RFC9000}}. During connection establishment, DoQ support is
indicated by selecting the ALPN token "doq" in the crypto handshake.

### Draft Version Identification

(RFC EDITOR NOTE: THIS SECTION TO BE REMOVED BEFORE PUBLICATION) Only
implementations of the final, published RFC can identify themselves as "doq".
Until such an RFC exists, implementations MUST NOT identify themselves using
this string.

Implementations of draft versions of the protocol MUST add the string "-" and
the corresponding draft number to the identifier. For example,
draft-ietf-dprive-dnsoquic-00 is identified using the string "doq-i00".

### Port Selection

By default, a DNS server that supports DoQ MUST listen for and accept QUIC
connections on the dedicated UDP port TBD (number to be defined in
{{iana-considerations}}), unless it has mutual agreement with its clients to
use a port other than TBD for DoQ. In order to use a port other than TBD, both
clients and servers would need a configuration option in their software.


By default, a DNS client desiring to use DoQ with a particular server MUST
establish a QUIC connection to UDP port TBD on the server, unless it has mutual
agreement with its server to use a port other than port TBD for DoQ. Such
another port MUST NOT be port 53. This recommendation against use of port 53
for DoQ is to avoid confusion between DoQ and the use of DNS over UDP
{{!RFC1035}}.

## Stream Mapping and Usage

The mapping of DNS traffic over QUIC streams takes advantage of the QUIC stream
features detailed in Section 2 of the QUIC transport specification {{!RFC9000}}.

DNS traffic follows a simple pattern in which the client sends a query, and the
server provides one or more responses (multiple can responses occur in zone
transfers).

The mapping specified here requires that the client selects a separate QUIC
stream for each query. The server then uses the same stream to provide all the
response messages for that query. In order that multiple responses can be
parsed, a 2-octet length field is used in exactly the same way as the 2-octet
length field defined for DNS over TCP {{RFC1035}}. The practical result of this
is that the content of each QUIC stream is exactly the same as the content of a
TCP connection that would manage exactly one query.

All DNS messages (queries and responses) sent over DoQ connections MUST be
encoded as a 2-octet length field followed by the message content as specified
in {{RFC1035}}.

The client MUST select the next available client-initiated bidirectional stream
for each subsequent query on a QUIC connection, in conformance with the QUIC
transport specification {{!RFC9000}}.

The client MUST send the DNS query over the selected stream, and MUST indicate
through the STREAM FIN mechanism that no further data will be sent on that
stream.

The server MUST send the response(s) on the same stream and MUST indicate, after
the last response, through the STREAM FIN mechanism that no further data will be
sent on that stream.

Therefore, a single client initiated DNS transaction consumes a single stream.
This means that the client's first query occurs on QUIC stream 0, the second on
4, and so on.

For completeness it is noted that versions prior to -02 of this specification
proposed a simpler mapping scheme which omitted the 2 byte length field and
supported only a single response on a given stream. The more complex mapping
above was adopted to specifically cater for XFR support, however it breaks
compatibility with earlier versions.

### DNS Message IDs

When sending queries over a QUIC connection, the DNS Message ID MUST be set to
zero.

It is noted that this has implications for proxying DoQ message to other
transports in that a mapping of some form must be performed (e.g., from DoQ
connection/stream to unique Message ID).

## DoQ Error Codes

The following error codes are defined for use when abruptly terminating streams,
aborting reading of streams, or immediately closing connections:

DOQ_NO_ERROR (0x00):
: No error.  This is used when the connection or stream needs to be closed, but
  there is no error to signal.

DOQ_INTERNAL_ERROR (0x01):
: The DoQ implementation encountered an internal error and is incapable of
  pursuing the transaction or the connection.

DOQ_PROTOCOL_ERROR (0x02):
: The DoQ implementation encountered an protocol error and is forcibly aborting 
  the connection.

### Transaction Errors

Servers normally complete transactions by sending a DNS response (or responses)
on the transaction's stream, including cases where the DNS response indicates a
DNS error. For example, a Server Failure (SERVFAIL, {{!RFC1035}}) SHOULD be
notified to the client by sending back a response with the Response Code set to
SERVFAIL.

If a server is incapable of sending a DNS response due to an internal error, it
may issue a QUIC Stream Reset with error code DOQ_INTERNAL_ERROR. The
corresponding transaction MUST be abandoned.

### Protocol Errors 

Other error scenarios can occur due to malformed, incomplete or unexpected
messages during a transaction. These include (but are not limited to)

* a client or server receives a message with a non-zero Message ID
* a client or server receives a STREAM FIN before receiving all the bytes for a 
  message indicated in the 2-octet length field
* a client receives a STREAM FIN before receiving all the expected responses
* a server receives more than one query on a stream
* a client receives a different number of responses on a stream than expected
  (e.g. multiple responses to a query for an A record)
* an implementation receives a message containing the edns-tcp-keepalive 
  EDNS(0) Option {{!RFC7828}} (see
  {{resource-management-and-idle-timeout-values}})
* an implementation receives a message containing the
  EDNS(0) Padding Option {{!RFC7830}} (see
  {{padding}})

If a peer encounters such an error condition it is considered a fatal error. It
SHOULD forcibly abort the connection using QUIC's CONNECTION_CLOSE mechanism,
and use the DoQ error code DOQ_PROTCOL_ERROR.

It is noted that the restrictions on use of the above EDNS(0) options has
implications for proxying message from TCP/DoT/DoH over DoQ.

## Connection Management

Section 10 of the QUIC transport specification {{!RFC9000}} specifies that
connections can be closed in three ways:

* idle timeout
* immediate close
* stateless reset

Clients and servers implementing DoQ SHOULD negotiate use of the idle timeout.
Closing on idle timeout is done without any packet exchange, which minimizes
protocol overhead. Per section 10.1 of the QUIC transport specification, the
effective value of the idle timeout is computed as the minimum of the values
advertised by the two endpoints. Practical considerations on setting the idle
timeout are discussed in {{resource-management-and-idle-timeout-values}}.

Clients SHOULD monitor the idle time incurred on their connection to the
server, defined by the time spent since the last packet from the server has
been received. When a client prepares to send a new DNS query to the server, it
will check whether the idle time is sufficient lower than the idle timer. If it
is, the client will send the DNS query over the existing connection. If not,
the client will establish a new connection and send the query over that
connection.

Clients MAY discard their connection to the server before the idle timeout
expires. If they do that, they SHOULD close the connection explicitly, using
QUIC's CONNECTION_CLOSE mechanism, and use the DoQ error code DOQ_NO_ERROR.

Clients and servers MAY close the connection for a variety of other
reasons, indicated using QUIC's CONNECTION_CLOSE. Client and servers
that send packets over a connection discarded by their peer MAY
receive a stateless reset indication. If a connection fails,
all queries in progress over the connection MUST be considered failed,
and a Server Failure (SERVFAIL, {{!RFC1035}}) SHOULD be notified
to the initiator of the transaction.

## Connection Resume and 0-RTT 

A client MAY take advantage of the connection resume mechanisms supported by
QUIC transport {{!RFC9000}} and QUIC TLS {{!RFC9001}}. Clients SHOULD consider
potential privacy issues associated with session resume before deciding to use
this mechanism. These privacy issues are detailed in
{{privacy-issues-with-session-resumption}} and {{privacy-issues-with-0-rtt-data}},
and the implementation considerations are discussed in
{{using-0-rtt-and-resumption}}.

The 0-RTT mechanism MUST NOT be used to send data that is
not "replayable" transactions. For example, a client MAY transmit a Query as
0-RTT, but MUST NOT transmit an Update. Servers that receive requests
for replayable transactions MUST NOT process them before the connection
handshake is confirmed, as defined in section 4.1.2 of {{!RFC9001}}; 
servers MAY close connections in which replayable transactions are
attempted with the error code DOQ_PROTOCOL_ERROR.

## Message Sizes

DoQ Queries and Responses are sent on QUIC streams, which in theory can carry
up to 2^62 bytes. However, DNS messages are restricted in practice to a maximum
size of 65535 bytes. This maximum size is enforced by the use of a two-octet
message length field in DNS over TCP {{!RFC1035}} and DNS over TLS
{{!RFC7858}}, and by the definition of the "application/dns-message" for DNS
over HTTP {{!RFC8484}}. DoQ enforces the same restriction.

The Extension Mechanisms for DNS (EDNS) {{!RFC6891}} allow peers to specify the
UDP message size. This parameter is ignored by DoQ. DoQ implementations always
assume that the maximum message size is 65535 bytes.


# Implementation Requirements

## Authentication

For the stub to recursive resolver scenario, the authentication requirements
are the same as described in DoT {{?RFC7858}} and "Usage Profiles for DNS over
TLS and DNS over DTLS" {{!RFC8310}}. There is no need to authenticate the
client's identity in either scenario.

For zone transfer, the requirements are the same as described in
{{!I-D.ietf-dprive-xfr-over-tls}}.

For the recursive resolver to authoritative nameserver scenario, authentication
requirements are unspecified at the time of writing and are the subject on
ongoing work in the DPRIVE WG.

## Fall Back to Other Protocols on Connection Failure

If the establishment of the DoQ connection fails, clients MAY attempt to
fall back to DoT and then potentially clear text, as specified in DoT
{{?RFC7858}} and "Usage Profiles for DNS over TLS and DNS over DTLS"
{{!RFC8310}}, depending on their privacy profile.

DNS clients SHOULD remember server IP addresses that don't support DoQ,
including timeouts, connection refusals, and QUIC handshake failures, and not
request DoQ from them for a reasonable period (such as one hour per server).
DNS clients following an out-of-band key-pinned privacy profile ({{?RFC7858}})
MAY be more aggressive about retrying DoQ connection failures.

## Address Validation

Section 8 of the QUIC transport specification {{!RFC9000}} defines Address
Validation procedures to avoid servers being used in address amplification
attacks. DoQ implementations MUST conform to this specification, which limits
the worst case amplification to a factor 3.

DoQ implementations SHOULD consider configuring servers to use the Address
Validation using Retry Packets procedure defined in section 8.1.2 of the QUIC
transport specification {{!RFC9000}}). This procedure imposes a 1-RTT delay for
verifying the return routability of the source address of a client, similar to
the DNS Cookies mechanism {{!RFC7873}}.

DoQ implementations that configure Address Validation using Retry Packets
SHOULD implement the Address Validation for Future Connections procedure
defined in section 8.1.3 of the QUIC transport specification {{!RFC9000}}).
This defines how servers can send NEW TOKEN frames to clients after the client
address is validated, in order to avoid the 1-RTT penalty during subsequent
connections by the client from the same address.

## Padding {#padding}

There are mechanisms specified for padding individual DNS messages in "The
EDNS(0) Padding Option" {{?RFC7830}} and for padding within QUIC packets (see
Section 8.6 of the QUIC transport specification {{!RFC9000}}).

Implementations MUST NOT use DNS options for padding individual DNS messages,
because QUIC transport MAY transmit multiple STREAM frames containing separate
DNS messages in a single QUIC packet. Instead, implementations SHOULD use QUIC
PADDING frames to align the packet length to a small set of fixed sizes,
aligned with the recommendations of the "Padding Policies for Extension
Mechanisms for DNS (EDNS(0))" {{?RFC8467}}.

## Connection Handling

"DNS Transport over TCP - Implementation Requirements" {{?RFC7766}} provides
updated guidance on DNS over TCP, some of which is applicable to DoQ. This
section attempts to specify which and how those considerations apply to DoQ.

### Connection Reuse

Historic implementations of DNS clients are known to open and close TCP
connections for each DNS query. To avoid excess QUIC connections, each with a
single query, clients SHOULD reuse a single QUIC connection to the recursive
resolver.

In order to achieve performance on par with UDP, DNS clients SHOULD send their
queries concurrently over the QUIC streams on a QUIC connection. That is, when
a DNS client sends multiple queries to a server over a QUIC connection, it
SHOULD NOT wait for an outstanding reply before sending the next query.

### Resource Management and Idle Timeout Values

Proper management of established and idle connections is important to the
healthy operation of a DNS server. An implementation of DoQ SHOULD follow best
practices similar to those specified for DNS over TCP {{?RFC7766}}, in
particular with regard to:

* Concurrent Connections (Section 6.2.2)
* Security Considerations (Section 10)

Failure to do so may lead to resource exhaustion and denial of service.

Clients that want to maintain long duration DoQ connections SHOULD use the idle
timeout mechanisms defined in Section 10.1 of the QUIC transport specification
{{!RFC9000}}. Clients and servers MUST NOT send the edns-tcp-keepalive EDNS(0)
Option {{?RFC7828}} in any messages sent on a DoQ connection (because it is
specific to the use of TCP/TLS as a transport).

This document does not make specific recommendations for timeout values on idle
connections. Clients and servers should reuse and/or close connections
depending on the level of available resources. Timeouts may be longer during
periods of low activity and shorter during periods of high activity.

### Using 0-RTT and resumption

Using 0-RTT for DNS over QUIC has many compelling advantages. Clients
can establish connections and send queries without incurring a connection
delay. Clients and server can thus negotiate low values of the connection
timers, without incurring latency penalties for new queries, reducing
the number of simultaneous connections that servers need to manage.

Session resumption and 0-RTT data transmission create
privacy risks detailed in detailed in
{{privacy-issues-with-session-resumption}} and {{privacy-issues-with-0-rtt-data}}.
The following implementation recommendations are meant to reduce the privacy
risks while enjoying the performance benefits of 0-RTT data, with the
restriction specified in {{connection-resume-and-0-rtt}}.

Clients SHOULD use resumption tickets only once, to reduce risks of tracking by third parties.
Privacy conscious clients SHOULD NOT use session resumption if their IP address
or location has changed, to reduce risk of tracking by the servers.

Clients may receive address validation tokens from the server using the
NEW TOKEN mechanism; see section 8 of {{!RFC9000}}. The associated tracking
risks are mentioned in {{privacy-issues-with-new-tokens}}. Privacy conscious
clients SHOULD only use the NEW TOKEN mechanism when they are also using session
resumption, thus avoiding additional tracking risks.

Servers SHOULD implement the anti-replay mechanisms specified in section 8 of
{{?RFC8446}}. Servers that can enforce single use of resumption tickets for 0-RTT
per section 8.1 of {{?RFC8446}} SHOULD do so, as this is consistent with the above
recommendation that clients use resumption tickets only once. All servers MUST use
the Freshness Checks defined in section 8.2 of {{?RFC8446}} to assess the delay between
creation of the Client Hello at the client and the arrival at the server, 
and disable 0-RTT if that delay is larger than a threshold of at most 30 seconds.

Servers SHOULD issue session resumption tickets as soon as possible after the handshake
is confirmed, to maximize chances that the client can use resumption and 0-RTT if a
session breaks. Session resumption tickets SHOULD have a sufficient long life time (e.g. 6 hours),
so that clients are not tempted to either keep connection alive or frequently poll the server
to renew session resumption tickets.

## Processing Queries in Parallel

As specified in Section 7 of "DNS Transport over TCP - Implementation
Requirements" {{!RFC7766}}, resolvers are RECOMMENDED to support the preparing
of responses in parallel and sending them out of order. In DoQ, they do that by
sending responses on their specific stream as soon as possible, without waiting
for availability of responses for previously opened streams.

## Zone transfer

{{!I-D.ietf-dprive-xfr-over-tls}} specifies zone transfer over TLS (XoT)
and includes updates to {{!RFC1995}} (IXFR), {{!RFC5936}} (AXFR) and
{{!RFC7766}}. Considerations relating to the re-use of XoT connections
described there apply analogously to zone transfers performed using DoQ
connections. For example:

* DoQ servers MUST be able to handle multiple concurrent IXFR requests on a
  single QUIC connection
* DoQ servers MUST be able to handle multiple concurrent AXFR requests on a
  single QUIC connection
* DoQ implementations SHOULD 
     * use the same QUIC connection for both AXFR and IXFR requests to the same
       primary
     * pipeline such requests (if they pipeline XFR requests in general) and
       MAY intermingle them
     * send the response(s) for each request as soon as they are available i.e.
       responses MAY be sent intermingled

## Flow Control Mechanisms

Servers and Clients manage flow control as specified in QUIC.

Servers MAY use the "maximum stream ID" parameter of the QUIC transport to limit
the number of streams opened by the client. This mechanism will effectively
limit the number of DNS queries that a client can send on a single DoQ
connection. The initial value of this parameter is specified by the transport
parameter `initial_max_streams_bidi`. For better performance, it is RECOMMENDED
that servers chose a sufficiently large value for this parameter.

The flow control mechanisms of QUIC control how much data can be sent by QUIC
nodes at a given time. The initial values of per stream flow control parameters
is defined by two transport parameters:

* initial_max_stream_data_bidi_local: when set by the client, specifies the
  amount of data that servers can send on a "response" stream without waiting
  for a MAX_STREAM_DATA frame.

* initial_max_stream_data_bidi_remote: when set by the server, specifies the
  amount of data that clients can send on a "query" stream without waiting for
  a MAX_STREAM_DATA frame.

For better performance, it is RECOMMENDED that clients and servers set each of
these two parameters to a value of 65535 or greater.

# Implementation Status

(RFC EDITOR NOTE: THIS SECTION TO BE REMOVED BEFORE PUBLICATION) This section
records the status of known implementations of the protocol defined by this
specification at the time of posting of this Internet-Draft, and is based on a
proposal described in {{?RFC7942}}.

1. AdGuard launched a DoQ recursive resolver service in December 2020. They have
   released a suite of open source tools that support DoQ:
    1. [AdGuard C++ DNS libraries](https://github.com/AdguardTeam/DnsLibs) A
       DNS proxy library that supports all existing DNS protocols including
       DNS-over-TLS, DNS-over-HTTPS, DNSCrypt and DNS-over-QUIC (experimental).
    2. [DNS Proxy](https://github.com/AdguardTeam/dnsproxy) A simple DNS proxy
       server that supports all existing DNS protocols including DNS-over-TLS,
       DNS-over-HTTPS, DNSCrypt, and DNS-over-QUIC. Moreover, it can work as a
       DNS-over-HTTPS, DNS-over-TLS or DNS-over-QUIC server.
    3. [CoreDNS fork for AdGuard DNS](https://github.com/AdguardTeam/coredns)
       Includes DNS-over-QUIC server-side support.
    3. [dnslookup](https://github.com/ameshkov/dnslookup) Simple command line
       utility to make DNS lookups. Supports all known DNS protocols: plain DNS,
       DoH, DoT, DoQ, DNSCrypt.
2. [Quicdoq](https://github.com/private-octopus/quicdoq) Quicdoq is a simple
    open source implementation of DoQ. It is written in C, based on
   [Picoquic](https://github.com/private-octopus/picoquic).
3. [Flamethrower](https://github.com/DNS-OARC/flamethrower/tree/dns-over-quic)
   is an open source DNS performance and functional testing utility written in
   C++ that has an experimental implementation of DoQ.
4. [aioquic](https://github.com/aiortc/aioquic) is an implementation of QUIC in
   Python. It includes example client and server for DoQ.

## Performance Measurements

To our knowledge, no benchmarking studies comparing DoT, DoH and DoQ are
published yet. However anecdotal evidence from the [AdGuard DoQ recursive
resolver deployment](https://adguard.com/en/blog/dns-over-quic.html) indicates
that it performs well compared to the other encrypted protocols, particularly
in mobile environments. Reasons given for this include that DoQ

* Uses less bandwidth due to a more efficient handshake (and due to less per
  message overhead when compared to DoH).
* Performs better in mobile environments due to the increased resilience to
  packet loss
* Can maintain connections as users move between mobile networks via its
  connection management


# Security Considerations

The security considerations of DoQ should be comparable to those of DoT
{{?RFC7858}}.


# Privacy Considerations

The general considerations of encrypted transports provided in "DNS Privacy
Considerations" {{?I-D.ietf-dprive-rfc7626-bis}} apply to DoQ. The specific
considerations provided there do not differ between DoT and DoQ, and are not
discussed further here.

QUIC incorporates the mechanisms of TLS 1.3 {{?RFC8446}} and this enables QUIC
transmission of "0-RTT" data. This can provide interesting latency gains, but
it raises two concerns:

1.  Adversaries could replay the 0-RTT data and infer its content
    from the behavior of the receiving server.

2.  The 0-RTT mechanism relies on TLS resume, which can provide
    linkability between successive client sessions.

These issues are developed in {{privacy-issues-with-0-rtt-data}} and 
{{privacy-issues-with-session-resumption}}.

## Privacy Issues With 0-RTT data

The 0-RTT data can be replayed by adversaries. That data may trigger queries by
a recursive resolver to authoritative resolvers. Adversaries may be able to
pick a time at which the recursive resolver outgoing traffic is observable, and
thus find out what name was queried for in the 0-RTT data.

This risk is in fact a subset of the general problem of observing the behavior
of the recursive resolver discussed in "DNS Privacy Considerations"
{{?RFC7626}}. The attack is partially mitigated by reducing the observability
of this traffic. However, the risk is amplified for 0-RTT data, because the
attacker might replay it at chosen times, several times.

The recommendation for TLS 1.3 {{?RFC8446}} is that the capability to use 0-RTT
data should be turned off by default, and only enabled if the user clearly
understands the associated risks. In our case, allowing 0-RTT data
provides significant performance gains, and we are concerned that a
recommendation to not use it would simply be ignored. Instead, we provide
a set of practical recommendations in {{connection-resume-and-0-rtt}}
and {{using-0-rtt-and-resumption}}.

The prevention on allowing replayable transactions in 0-RTT data
expressed in {{connection-resume-and-0-rtt}} blocks the most obvious
risks of replay attacks, as it only allows for transactions that will
not change the long term state of the server. 

Attacks trying to assess the state of the cache are more powerful if
the attacker can choose the time at which the 0-RTT data will be replayed.
We believe that the freshness tests recommended in {{connection-resume-and-0-rtt}}
significantly reduce the time range in which 0-RTT data can be
replayed, and thus significantly reduce the potential of such
attacks. The maximum delay parameter stated in {{connection-resume-and-0-rtt}}
is 30 seconds. We believe this is consistent with commonly used values
of the cached records TTL, and thus sufficiently small to impede
most replay attacks.

## Privacy Issues With Session Resumption

The QUIC session resume mechanism reduces the cost of re-establishing sessions
and enables 0-RTT data. There is a linkability issue associated with session
resume, if the same resume token is used several times. Attackers on path
between client and server could observe repeated usage of the token and
use that to track the client over time or over multiple locations. 

The session resume mechanism allows servers to correlate the resumed sessions
with the initial sessions, and thus to track the client. This creates a virtual
long duration session. The series of queries in that session can be used by the
server to identify the client. Servers can most probably do that already if
the client address remains constant, but session resume tickets also enable
tracking after changes of the client's address.

The recommendations in {{connection-resume-and-0-rtt}} are designed to
mitigate these risks. Using session tickets only once mitigates
the risk of tracking by third parties. Refusing to resume session if addresses
change mitigates the risk of tracking by the server.

## Privacy Issues With New Tokens

QUIC specifies address validation mechanisms in section 8 of {{!RFC9000}}.
Use of an address validation token allows QUIC servers to avoid an extra RTT
for new connections. Address validation tokens are typically tied to an IP address. QUIC
clients normally only use these tokens when setting a new connection
from a previously used address. However, due to the prevalence of NAT,
clients are not always aware that they are using a new address. There
is a linkability risk if clients mistakenly use address validation tokens after
unknowingly moving to a new location.

The recommendations in {{connection-resume-and-0-rtt}} mitigates
this risk by tying the usage of the NEW TOKEN to that of session resumption.

## Traffic Analysis

Even though QUIC packets are encrypted, adversaries can gain information from
observing packet lengths, in both queries and responses, as well as packet
timing. Many DNS requests are emitted by web browsers. Loading a specific web
page may require resolving dozen of DNS names. If an application adopts a
simple mapping of one query or response per packet, or "one QUIC STREAM frame
per packet", then the succession of packet lengths may provide enough
information to identify the requested site.

Implementations SHOULD use the mechanisms defined in {{padding}} to mitigate
this attack.


# IANA Considerations

## Registration of DoQ Identification String

This document creates a new registration for the identification of DoQ in the
"Application Layer Protocol Negotiation (ALPN) Protocol IDs" registry
{{!RFC7301}}.

    The "doq" string identifies DoQ:

        Protocol:                 DoQ  
        Identification Sequence:  0x64 0x6F 0x71 ("doq")  
        Specification:            This document  

## Reservation of Dedicated Port

Port 853 is currently reserved for 'DNS query-response protocol run over
TLS/DTLS' {{!RFC7858}}. However, the specification for DNS over DTLS (DoD)
{{!RFC8094}} is experimental, limited to stub to resolver, and no
implementations or deployments currently exist to our knowledge (even though
several years have passed since the specification was published).

This specification proposes to additionally reserve the use of port 853 for
DoQ. Whilst {{!RFC8094}} did not specify the use of an ALPN for DoD, DoQ
requires the use of the `doq` ALPN and is therefore de-muxable from DoD.

IANA is requested to add the following value to the "Service Name and Transport
Protocol Port Number Registry" in the System Range. The registry for that range
requires IETF Review or IESG Approval {{?RFC6335}}.

       Service Name           dns-over-quic  
       Port Number            853  
       Transport Protocol(s)  UDP  
       Assignee               IESG  
       Contact                IETF Chair  
       Description            DNS query-response protocol run over QUIC  
       Reference              This document  

### Port number 784 for experimentations

(RFC EDITOR NOTE: THIS SECTION TO BE REMOVED BEFORE PUBLICATION) Early
experiments MAY use port 784. This port is marked in the IANA registry as
unassigned.

(Note that version in -02 of this draft experiments were directed to use port
8853.)

# Acknowledgements

This document liberally borrows text from the HTTP-3 specification
{{?I-D.ietf-quic-http}} edited by Mike Bishop, and from the DoT specification
{{?RFC7858}} authored by Zi Hu, Liang Zhu, John Heidemann, Allison Mankin,
Duane Wessels, and Paul Hoffman.

The privacy issue with 0-RTT data and session resume were analyzed by Daniel
Kahn Gillmor (DKG) in a message to the IETF "DPRIVE" working group {{DNS0RTT}}.

Thanks to Tony Finch for an extensive review of the initial version of this
draft, and to Robert Evans for the discussion of 0-RTT privacy issues.
Reviews by Paul Hoffman and Martin Thomson and interoperability tests
conducted by Stephane Bortzmeyer helped improve the definition of the protocol.

--- back






