#!/bin/sh

dig dns.sub.example.com @localhost +short
dig -x 10.0.3.231       @localhost +short

dig bygzam.sub.example.com @localhost +short
dig -x 10.0.3.8            @localhost +short

