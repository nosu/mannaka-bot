# -- coding: utf-8

require 'nokogiri'
require 'open-uri'
require 'json'

class BirthCrawler
    @@number_of_days = {
        "1" => 31,
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

    def initialize()
    end

    def crawl (month)
        @days = getNumberOfDays(month)
        p "call getBrithdayList: "
        p month
        p @days
        @list = getBirthdayList(month, @days)
    
        File.open("./temp.json","w") do |f|
            f.write(@list.to_json)
        end
    end

    private

    def getNumberOfDays(month)
        @@number_of_days[month]
    end

    def getBirthdayList(month, days)
        @birthday_list = {}
        (1..days).each do |day|
            @url = URI.escape("http://ja.wikipedia.org/wiki/#{month}月#{day}日")
            @names_urls = getNamesWithUrls(extractBirthdayNodes(downloadPage(@url)))
            @birthday_list[day] = @names_urls
        end
        @birthday_list
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
        @names_urls = []
        nodes.each do |node|
            @name = getNameFromNode(node)
            @namenode = node.xpath("a[text()='#{@name}']")
            if @namenode.empty?
                @url = ""
            else
                @url = @namenode.attribute("href").text
            end
            @names_urls.push({:name => @name, :url => @url})
        end
        @names_urls
    end

end


arg = ARGV[0]
cr = BirthCrawler.new

if arg == "all"
    (1..12).each do |m|
        cr.crawl(m)
    end
elsif /[1-12]/ =~ arg
    cr.crawl(arg)
else
    puts "Input 'all' or a target month"
end

