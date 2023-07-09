; base zone file for example.com
$TTL 2d    ; default TTL for zone
$ORIGIN main.example.com. ; base domain-name
; Start of Authority RR defining the key characteristics of the zone (domain)
@         IN      SOA   dns.main.example.com. root.example.com. (
                                2023070901 ; serial number
                                12h        ; refresh
                                15m        ; update retry
                                3w         ; expiry
                                2h         ; minimum
                                )
; name server RR for the domain
           IN      NS      dns.main.example.com.
dns        IN      A       10.0.3.230
; domain hosts includes NS and MX records defined above
; plus any others required
; for instance a user query for the A RR of joe.example.com will
; return the IPv4 address 192.168.254.6 from this zone file
zeong      IN      A       10.0.3.2

