# Codefights-Scraper
A web scraper/crawler that I built to pull my completed ruby code from Codefights and writes it to local file system 
in order to publish it on Github. Takes a command line argument for the desired path to the Codefights folder. 
Challenge explanations are either taken as already formatted readme.md's from https://github.com/Lintik/CodeFights-Arcade 
or if they are not present/not in expected url, the explanation is taken unformatted from codefights.
All content taken from Codefights is scraped with Selenium and mechanize is used to retrieve github readme's
