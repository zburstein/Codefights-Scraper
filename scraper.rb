#!/usr/local/bin/ruby
require "selenium-webdriver"
require 'pry-byebug'
require 'fileutils'
require 'mechanize'
require 'io/console'


file_extensions = {"Python3": "py", "Ruby": "rb"} 
mechanize = Mechanize.new
driver = Selenium::WebDriver.for :chrome
driver.navigate.to "https://app.codesignal.com/login"
wait = Selenium::WebDriver::Wait.new(:timeout => 20)

#click login, fill fields, and then login with user input. Does not handle fail at the moment
wait.until{driver.find_element(:name, "username")}
puts "enter email address"
email = STDIN.noecho(&:gets).chomp
driver.find_element(:name, "username").send_keys(email)
puts "enter password"
password = STDIN.noecho(&:gets).chomp
driver.find_element(:name, "password").send_keys(password)
driver.find_element(:css, "body > div:nth-child(10) > div > div.-margin-h-32.-full-height.-bg-white > div > div.-layout-v.-space-v-32 > div.-layout-v.-space-v-8 > div > div").click

#wait until login goes through adn then navigate to arcade intro, and then wait for that to load
element = wait.until { driver.find_element(:css, "body > div:nth-child(10) > div > div.page--header > div > div > div.header-navigation--logo-button.-layout-h.-center.-padding-h-24.-white") }

#since I have only done these two, I made a hash with their name and link
arcade = {"Intro"=> "https://app.codesignal.com/arcade/intro", "The Core"=> "https://app.codesignal.com/arcade/code-arcade"}

#for each arcade section
arcade.each do |arcade_section_name, arcade_section_link|
  #navigate to the section adn wait for it to load
  driver.navigate.to arcade_section_link
  wait.until { driver.find_element(:css, "body > paper-header-panel > div.paper-header-panel > div > div > div > div.arcade-map--wrapper.-layout-v.-space-v-32.-relative > div:nth-child(1) > div.-relative.-clickable > div") }

  #get the section elements and section names
  section_elements = driver.find_elements(:class, "arcade-map--topic")
  section_names = driver.find_elements(:class, "arcade-map--topic-title").map{|section| section.text}

  #create hash with key as section name and value will be another hash of challenge names and their links
  sections = Hash.new

  #issues with default expanding and breaking iteration below because it does not register click, so need to wait
  wait.until{driver.find_elements(:class, "-expanded")}
  sleep 5

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


  #once all the sections adn their challenges are logged, navigate to them and create files
  sections.each do |section_name, challenge_hash|
    challenge_hash.each do |challenge_name, link|

      #navigate to link and wait for it to load
      driver.navigate.to link
      wait.until{driver.find_element(:class, "header-navigation--title").text.include?(challenge_name)}

      #first ensure the directory where copying code exists, else create it
      #the root path to where user wants the CodeFights directory should be supplied as cmnd line arg
      directory_path = "#{ARGV[0]}/CodeFights/#{arcade_section_name}/#{section_name}/#{challenge_name}"
      unless File.directory?(directory_path)
        FileUtils.mkdir_p(directory_path)
      end

      #then get problem explanation from github in .md format with mechanize/nokogiri
      #not all match up properly so print when it gives 404 to fix manually  
      begin
        page = mechanize.get("https://raw.githubusercontent.com/Lintik/CodeFights-Arcade/master/#{arcade_section_name}/#{section_name == "Rains of Reason" ? "Rains of Reasons" : section_name}/#{challenge_name}/README.md")
        read_me = page.body
      rescue Mechanize::ResponseCodeError => e
        puts "#############**************#{challenge_name} gave error of #{e.response_code}***********##############"
        read_me = ""
      end
      
      #if could not find the readme on github or was blank, just pull the text from codefights
      #will not be in markdown if retrieved this way
      wait.until{driver.find_element(:class, "markdown")}
      read_me = driver.find_element(:class, "markdown").text if read_me.length < 5 || read_me.nil? || read_me.empty? 
      readme_path = directory_path + "/README.md"
      File.open(readme_path, 'w'){|file| file.puts(read_me)}

      #click drafts and wait for table to load
      driver.find_element(:css, "body > div:nth-child(10) > div > div.page--body.-margin-t-64.-flex > div > div.-layout.-stretch.-fit > div.split-panel--first.-layout.-vertical.-flex.-relative > div > div.-layout-v.-flex.-bg-white > div.tabs.-view-ide > div.-layout.-center > div > div > div:nth-child(2)").click
      wait.until{!driver.find_elements(:class, "rt-tr-group").empty?}


      #hash for languages and whether they have been copied
      copied = {"Python3": false, "Ruby": false}
      #iterate over each solution (row in table)
      driver.find_elements(:class, "rt-tr-group").each do |row|
        #if all languages done, can break
        break if copied.values.uniq.length == 1 && copied.values.uniq[0]

        #and for each language's most recent solution, copy the code
        #this method only works if no failed test of language more recent than a successful one
        #would be better to get proper column and index in copied, but struggling with selector
        copied.each do |language, completed|
          if !completed && row.text.include?(language.to_s)
            #click, wait until it loads, and then copy the code 
            row.click
            wait.until{driver.find_element(:css, "body > div:nth-child(10) > div > div.page--body.-margin-t-64.-flex > div > div.-layout.-stretch.-fit > div.split-panel--second.-layout.-vertical.-flex.-relative > div > div.-flex.-relative.task-view--coding-area > div.split-panel.-fit.-vertical > div.-layout.-stretch.-fit.-vertical > div.split-panel--first.-layout.-vertical.-flex.-relative > div > div.tabs.-view-ide.-theme-dark > div.-layout.-center > div.-layout.-center.-flex.-space.-margin-h-16.-self-stretch > div.-layout-h.-center.-space-h-8 > div:nth-child(1) > div > div").text == language.to_s}
            wait.until{!driver.find_elements(:class, "CodeMirror-line").empty?}
            code_lines = driver.find_elements(:class, "CodeMirror-line").map{|line| line.text}

            #get path of file on local system for this language and write to it. 
            code_path = directory_path + "/code." + file_extensions[language]
            File.open(code_path, 'w'){ |file| file.puts(code_lines) }

            #set copied to true and break from urrent loop to other solutions
            copied[language] = true
            break
          end
        end
      end
    end
  end
end