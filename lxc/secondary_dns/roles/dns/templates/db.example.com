; base zone file for example.com
$TTL 2d    ; default TTL for zone
$ORIGIN example.com. ; base domain-name
; Start of Authority RR defining the key characteristics of the zone (domain)
@         IN      SOA   secondarydns.example.com. root.example.com. (
                                2023070301 ; serial number
                                12h        ; refresh
                                15m        ; update retry
                                3w         ; expiry
                                2h         ; minimum
                                )
; name server RR for the domain
           IN      NS      secondarydns.example.com.
           IN      A       10.0.3.231
secondary IN      A       10.0.3.231
; domain hosts includes NS and MX records defined above
; plus any others required
; for instance a user query for the A RR of joe.example.com will
; return the IPv4 address 192.168.254.6 from this zone file
{{ servername }}   IN      A       192.168.0.178

