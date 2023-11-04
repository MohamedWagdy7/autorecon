import subprocess
from sys import argv

if len(argv) < 2:
    print("USAGE: autorecon <domain>")
    exit()
    
def run(cmd):
    try:
        proccess = subprocess.Popen(cmd,shell=True,stdout=subprocess.PIPE)
        proccess.wait()
    except InterruptedError:
        exit()
def main():
    # running amass CMDs
    run(f"amass enum -d {argv[1]} -w ~/Pentest/SecLists/Discovery/DNS/subdomains-top1million-100000.txt -active -brute -passive >>subdomains 2>/dev/null")
            
    # running gobuster
    run(f"gobuster vhost -u http://{argv[1]} -q -w ~/Pentest/SecLists/Discovery/DNS/subdomains-top1million-110000.txt | grep -v 403 >> x && cat x | cut -d ' ' -f 2 | sed 's/$/.{argv[1]}/' >> subdomains && rm x ")
    run(f"gobuster vhost -u https://{argv[1]} -q -w ~/Pentest/SecLists/Discovery/DNS/subdomains-top1million-110000.txt | grep -v 403 >> x && cat x | cut -d ' ' -f 2 | sed 's/$/.{argv[1]}/' >> subdomains && rm x ")
        
    # uniq subdomains
    run("sort subdomains | uniq >> x && rm subdomains && mv x subdomains")
    
    # running haktrails
    run("cat subdomains | haktrails subdomains >>subdomains 2>/dev/null")
    
    # filtering active subs
    run("httpx -l subdomains -o activesubs -threads 200 -status-code -follow-redirects -p 443,80,8888,8080,8443")
        
    # crawling 
    run("cat subdomains | httpx | hakrawler >> urls")
    run("cat subdomains | gau >> urls")
    run("cat subdomains | katana >> urls")
        
    # extract JS
    run("cat urls | grep js | httpx -mc 200 | tee js")
    
    # param enumerate
    run("cat subdomains | httpx | arjun -i")
    
if __name__ == "__main__":
    main()