; base zone file for example.com
$TTL 2d    ; default TTL for zone
$ORIGIN example.com. ; base domain-name
; Start of Authority RR defining the key characteristics of the zone (domain)
@         IN      SOA   freebsd.example.com. root.example.com. (
                                2025070501 ; serial number
                                12h        ; refresh
                                15m        ; update retry
                                3w         ; expiry
                                2h         ; minimum
                                )
; name server RR for the domain
           IN      NS      freebsd.example.com.
           IN      A       172.16.1.14
freebsd    IN      A       172.16.1.14
; domain hosts includes NS and MX records defined above
; plus any others required
; for instance a user query for the A RR of joe.example.com will
; return the IPv4 address 192.168.254.6 from this zone file
xubuntu   IN      A       172.16.3.244
abaoaqu   IN      A       192.168.0.98
opnsense  IN      A       172.16.0.1
parrot    IN      A       172.16.0.42
debian    IN      A       172.16.2.53
rocky     IN      A       172.16.1.69

