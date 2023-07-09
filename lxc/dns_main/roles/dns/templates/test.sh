#!/bin/sh

dig dns.main.example.com @localhost +short
dig zeong.main.example.com @localhost +short

dig -x 10.0.3.230        @localhost +short
dig -x 10.0.3.2          @localhost +short

