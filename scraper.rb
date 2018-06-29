#!/usr/local/bin/ruby
require "selenium-webdriver"
require 'pry-byebug'
require 'fileutils'
require 'mechanize'
require 'io/console'



mechanize = Mechanize.new
driver = Selenium::WebDriver.for :chrome
driver.navigate.to "https://codefights.com/"
wait = Selenium::WebDriver::Wait.new(:timeout => 20)

#click login, fill fields, and then login
wait.until{driver.find_element(:css, "body > div:nth-child(10) > div > div > div.-relative > div.-layout-h.-center.-padding-h-32.-margin-t-32.-hide-xs-lte > div > div > div")}
driver.find_element(:css, "body > div:nth-child(10) > div > div > div.-relative > div.-layout-h.-center.-padding-h-32.-margin-t-32.-hide-xs-lte > div > div > div").click
wait.until{driver.find_element(:name, "username")}
puts "enter email address"
email = STDIN.noecho(&:gets).chomp
driver.find_element(:name, "username").send_keys(email)
puts "enter password"
password = STDIN.noecho(&:gets).chomp
driver.find_element(:name, "password").send_keys(password)
driver.find_element(:css, "body > div.modals-container > div > div > div > div > div > div > div > div.modal--body > div > div.-layout-v.-space-v-16 > div.button.-type-green-fresh.-size-32.-font-size-20 > div").click

#wait until login goes through adn then navigate to arcade intro, and then wait for that to load
element = wait.until { driver.find_element(:css, "body > div:nth-child(10) > div > div.page--header > div > div > div.header-navigation--logo-button.-layout-h.-center.-padding-h-24.-white") }
driver.navigate.to "https://codefights.com/arcade/intro"
element = wait.until { driver.find_element(:css, "body > paper-header-panel > div.paper-header-panel > div > div > div > div.arcade-map--wrapper.-layout-v.-space-v-32.-relative > div:nth-child(1) > div.-relative.-clickable > div") }

#get the section elements and section names
section_elements = driver.find_elements(:class, "arcade-map--topic")
section_names = driver.find_elements(:class, "arcade-map--topic-title").map{|section| section.text}

#create hash of with key as section name and 
sections = Hash.new

#issues with a default expanding and breaking iteration below because it does not register click
wait.until{driver.find_elements(:class, "-expanded")}

#for each section
for i in 0..section_elements.length - 1
  challenges = Hash.new

  #click the section, wait until loaded, get challenge names and links and store in hash
  section_elements[i].click #click
  wait.until{section_elements[i].attribute("class").include?("-expanded")} #wait until loaded

  #iterate over the links to solved challenged, create array with uniq values
  driver.find_elements(:css, "div.-expanded a.-solved").map{|a| a.attribute("href")}.uniq.each do |link|
    #then do css search with url to get name of challenvge and make hash[challenge_name] = link
    challenges[driver.find_element(:css, "a[href='#{link.split(".com")[1]}'] h3").text] = link ########need to cut out domain#####
  end

  #finally set the section[section_name] = hash of challenge names and their links
  sections[section_names[i]] = challenges
end


#need to fix above first
sections.each do |section_name, challenge_hash|
  challenge_hash.each do |challenge_name, link|
    #navigate to link and once loaded, create string of code and explanation
    driver.navigate.to link
    wait.until{driver.find_element(:class, "header-navigation--title").text == challenge_name}
    #explanation = wait.until{driver.find_element(:class, "markdown")} #i think im going to seperate this and take it from the github cause its formatted there in .md
    wait.until{!driver.find_elements(:class, "CodeMirror-line").empty?}
    code_lines = driver.find_elements(:class, "CodeMirror-line").map!{|line| line.text}
    
    #get path of file on local system and write to it. First create directories if they dont exist 
    directory_path = "#{ARGV[0]}/CodeFights/Intro/#{section_name}/#{challenge_name}"
    code_path = directory_path + "/code.rb"
    unless File.directory?(directory_path)
      FileUtils.mkdir_p(directory_path)
    end
    File.open(code_path, 'w'){ |file| file.puts(code_lines) }

  
    #tehn get problem explanation from github with mechanize/nokogiri
    #not all match up properly so print when it gives 404 to fix manually  
    begin
      page = mechanize.get("https://raw.githubusercontent.com/Lintik/CodeFights-Arcade/master/Intro/#{section_name == "Rains of Reason" ? "Rains of Reasons" : section_name}/#{challenge_name}/README.md")
      read_me = page.body
      readme_path = directory_path + "/README.md"
      File.open(readme_path, 'w'){|file| file.puts(read_me)}
    rescue Mechanize::ResponseCodeError => e
      puts "#############**************#{challenge_name} gave error of #{e.response_code}***********##############"
    end
  end
end