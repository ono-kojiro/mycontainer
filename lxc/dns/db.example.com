$TTL	86400
@	IN	SOA	dnsserver.example.com. root.example.com. (
			      1		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			  86400 )	; Negative Cache TTL
;
@	IN	NS	dnsserver.example.com.
    IN  A   192.168.10.1
dnsserver IN A 192.168.10.1

zaku  IN A  192.168.10.42
gufu  IN A  192.168.10.53

