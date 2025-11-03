# OPNSense Web Application Firewall

https://docs.opnsense.org/manual/how-tos/nginx.html

## Plugin

System -> Firmware -> Plugins

ckeck "show community plugins"
search "os-nginx"
install "os-nginx"

### TCP Port

System -> Settings -> Administration

+---------------+------------------------------+---------+
| Name          | Value                        | Remarks |
+===============+==============================+=========+
| TCP Port      | 8443                         |         |
+---------------+------------------------------+---------+
| HTTP Redirect | Disable web GUI redirect: ON |         |
+---------------+------------------------------+---------+

press save button.

### Allow 8443 port access


## Nginx

Service -> Nginx -> Configuration

### Upstream Server

+---------------------+------------------+---------+
| Name                | Value            | Remarks |
+=====================+==================+=========+
| Description         | MyUpstreamServer |         |
+---------------------+------------------+---------+
| Server              | 172.16.1.63      |         |
+---------------------+------------------+---------+
| Port                | 80               |         |
+---------------------+------------------+---------+
| Server Priority     | 1                |         |
+---------------------+------------------+---------+
| Maximum Connections | 100              |         |
+---------------------+------------------+---------+
| Maximum Failures    | 10               |         |
+---------------------+------------------+---------+
| Fail Timeout        | 5                |         |
+---------------------+------------------+---------+

### Upstream

+--------------------------+----------------------+---------+
| Name                     | Value                | Remarks |
+==========================+======================+=========+
| Description              | MyUpstream           |         |
+--------------------------+----------------------+---------+
| Server Entries           | MyUpstreamServer     |         |
+--------------------------+----------------------+---------+
| Load Balancing Algorithm | Weighted Round Robin |         |
+--------------------------+----------------------+---------+

### HTTP(S) Location

+-----------------------+------------+---------+
| Name                  | Value      | Remarks |
+=======================+============+=========+
| Description           | MyLocation |         |
+-----------------------+------------+---------+
| URL Pattern           | /          |         |
+-----------------------+------------+---------+
| Upstream Servers      | MyUpstream |         |
+-----------------------+------------+---------+

### HTTPS(S) HTTP Server


+-------------------------------------+--------------+---------+
| Name                                | Value        | Remarks |
+=====================================+==============+=========+
| HTTP Listen Address                 | 80           |         |
+-------------------------------------+--------------+---------+
| HTTPS Listen Address                | (empty)      |         |
+-------------------------------------+--------------+---------+
| Server Name                         | MyHTTPServer |         |
+-------------------------------------+--------------+---------+
| Locations                           | MyLocation   |         |
+-------------------------------------+--------------+---------+
| Enable Let's Encrypt Plugin Support | Off          |         |
+-------------------------------------+--------------+---------+

### General Settings

+--------------+-------+---------+
| Name         | Value | Remarks |
+==============+=======+=========+
| Enable nginx | On    |         |
+--------------+-------+---------+

Press "Apply" button.

## Check reverse proxy

From Parrot OS, access to http://172.16.1.1 and confirm transfered to http://172.16.1.63 .

## Web Application Firewall

Service -> Nginx -> Configuration

### HTTP(S) Location

+------------------------+--------------+---------+
| Name                   | Value        | Remarks |
+========================+==============+=========+
| Enable Security Rules  | On           |         |
+------------------------+--------------+---------+
| Custom Security Policy | (Select ALL) |         |
+------------------------+--------------+---------+

### Naxsi WAF Policy

HTTPS(S) -> Naxsi WAF Policy

"It looks like you are not having any rules installed.
You may want to download the NAXSI core rules."

Press "Download" button.
Press "Accept And Download" button.

### Naxsi WAF Rule
HTTPS(S) -> Naxsi WAF Rule

(no need to configure)
