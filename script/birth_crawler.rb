# -- coding: utf-8

require 'nokogiri'
require 'open-uri'
require 'json'

class BirthCrawler
    @@number_of_days = {
        # "1" => 31,
        "1" => 3,
        "2" => 29,
        "3" => 31,
        "4" => 30,
        "5" => 31,
        "6" => 30,
        "7" => 31,
        "8" => 31,
        "9" => 30,
        "10" => 31,
        "11" => 30,
        "12" => 31
    }

    def initialize(file_dir)
        @file_dir = file_dir
    end

    def crawl (month)
        @days = getNumberOfDays(month)
        p "call getBrithdayList: "
        p month
        p @days
        @list = getBirthdayList(month, @days)
        File.write("#{@file_dir}/../data/#{month}.json", @list.to_json)  
    end

    private

    def getNumberOfDays(month)
        @@number_of_days[month]
    end

    def getBirthdayList(month, days)
        birthday_list = {}
        (1..days).each do |day|
            url = URI.escape("http://ja.wikipedia.org/wiki/#{month}月#{day}日")
            names_urls = getNamesWithUrls(extractBirthdayNodes(downloadPage(url)))
            birthday_list[day] = names_urls
            sleep(10)
        end
        birthday_list
    end

    def downloadPage(url)
        html = open(url)
        page = Nokogiri::HTML.parse(html, nil, "UTF-8")
    end 

    def extractBirthdayNodes(page)
        page.xpath('(//h2/span[text()="誕生日"]/parent::*/following::ul)[1]/li')
    end

    def getNameFromNode(node)
        /-\s(.+?)、/.match(node.inner_text)
        $1
    end

    def getNamesWithUrls(nodes)
        names_urls = []
        nodes.each do |node|
            name = getNameFromNode(node)
            namenode = node.xpath("a[text()='#{name}']")
            if namenode.empty?
                url = ""
            else
                url = namenode.attribute("href").text
            end
            score = getNameScore(name)
            names_urls.push({ :name => name, :url => url, :score => score })
        end
        names_urls
    end

    def getNameScore(name)
        url = URI.escape("http://www.google.com/search?q=#{name}")
        nodeset = downloadPage(url)
        number_node = nodeset.css("#resultStats")
        if number_node.empty?
            result = 0
        else
            number_node.text.match(/About\s(([0-9]|,)*)\sresults/)
            $1.to_i
        end
    end

end


arg = ARGV[0]
file_dir = File.dirname(__FILE__)
cr = BirthCrawler.new(file_dir)

if arg == "all"
    (1..12).each do |m|
        cr.crawl(m)
    end
elsif /[1-12]/ =~ arg
    cr.crawl(arg)
else
    puts "Input 'all' or a target month"
end

