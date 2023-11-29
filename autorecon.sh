#! /usr/bin/bash

if [ $# -lt 1 ]
then
    echo "USAGE: $0 <domain>"
    exit
fi

# Run amass with active, passive, and bruteforce mode
amass enum -d $1 -w ~/Pentest/SecLists/Discovery/DNS/subdomains-top1million-100000.txt -active -brute -passive >>subdomains 2>/dev/null

# Run Gobster to get VHosts
gobuster vhost -u http://$1 -q -w ~/Pentest/SecLists/Discovery/DNS/subdomains-top1million-110000.txt | grep -v 403 >> x && cat x | cut -d ' ' -f 2 | sed 's/$/.$1/' >> subdomains && rm x 2>/dev/null
gobuster vhost -u https://$1 -q -w ~/Pentest/SecLists/Discovery/DNS/subdomains-top1million-110000.txt | grep -v 403 >> x && cat x | cut -d ' ' -f 2 | sed 's/$/.$1/' >> subdomains && rm x 2>/dev/null

# Test for subdomain takeover
subjack -w subdomains >> takeover 2>/dev/null

# uniq subdomains
sort subdomains | uniq >> x && rm subdomains && mv x subdomains
    
# running haktrails
cat subdomains | haktrails subdomains >>subdomains 2>/dev/null
    
# filtering active subs
httpx -l subdomains -o activeurls -threads 200 -status-code -follow-redirects -p 443,80,8888,8080,8443
cat activesubs | grep -oP "(([^/]+)\.)+$1" | grep $1 | sort -u >> activesubs

# crawling 
cat subdomains | httpx | hakrawler >> urls
cat subdomains | gau >> urls
cat subdomains | httpx | katana >> urls

# Get wayback machine URLs
cat subdomains | waybackurls >> urls&

# extract JS
cat urls | grep js | httpx -mc 200 >> js

# Run Nuclei on JS files
nuclei -l js -t ~/nuclei-templates/exposures/ -o js_bugs

# Possible SQLi endpoints
cat urls | uro | grep "\?" | sed "s/=.*/=A\'/" | uniq > params.txt; cat params.txt | httpx -mr ".*SQL.*|.*syntax.*|.*error.*" >> errors

# param enumerate
cat subdomains | httpx | arjun -i -oT arjun.txt
paramspider -l subdomains
cat urls | grep -Ev "\.js|\.css|\.jpg|\.png" | grep "=" >> params
