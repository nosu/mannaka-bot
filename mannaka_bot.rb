require 'twitter'
require 'yaml'
require 'net/https'
require 'uri'
require 'json'

class MannakaBot
    def initialize(since_id, config)
        @since_id = since_id if since_id
        @config = config
        @client = Twitter::REST::Client.new do |conf|
          conf.consumer_key        = @config['twitter']['consumer_key']
          conf.consumer_secret     = @config['twitter']['consumer_secret']
          conf.access_token        = @config['twitter']['access_token']
          conf.access_token_secret = @config['twitter']['access_token_secret']
        end
    end

    def reply()
        mentions = getRecentMentions(@since_id)
        mentions.each do |mention|
            dates = findDatesInText(mention.text)
            p "those dates founded:"
            p dates
            case dates.length
            when 1
                type = "famousName"
                text = createReplyText(type, getFamousName(dates[0]))
                postReply(@client, mention.in_reply_to_screen_name, text, mention.id)
            when 2
                type = "mannakaDate"
                text = createReplyText(type, calcDate(dates[0], dates[1]))
                postReply(@client, mention.in_reply_to_screen_name, text, mention.id)
            else
                p "found #{dates.length} dates in the tweet. skip..."
                dates.each do |date|
                    p "date: #{date}"
                end
                p "original tweet: #{mention.text}"
                
            end
        end
        { :status => "success", :last_id => mentions[0].id }
    end

    private

    def getRecentMentions(since_id)
        tweets = @client.mentions({
            :since_id => since_id
        })
    end

    def findDatesInText(text)
        result = morphAnalysis(text, "DAT")
        p result['ne_list']
        dates = result['ne_list'].select { |word| 
            word[1] == "DAT" 
        }.map { |word|
            word[0]
        }
        dates.map { |date| parseDate(date) }
    end
    
    def parseDate(text)
        dummy_year = 1990
        case text
        when /([01][0-9]|[1-9])月([0-3][0-9]|[1-9])日/
            Date.new(dummy_year, $1.to_i, $2.to_i)
        else
        end
    end

    def findNamesInText(text)
        result = morphAnalysis(text, "PSN")
        words = result['ne_list'].map { |word| word[0] if word[1] == "PSN" }
    end

    def morphAnalysis(text, types)
        uri = URI.parse(@config['goo_api_url'])
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        req = Net::HTTP::Post.new(uri.request_uri)
        req["Content-Type"] = "application/json"
        params = {
            :app_id => @config['goo_api_key'],
            :class_fileter => types,
            :sentence => text
        }.to_json
        req.body = params
        res = https.request(req)
        
        if res.code == "200" && res.message == "OK"
            JSON.parse(res.body)
        else
           fail("response from goo-api is invalid")
        end
    end

    def getFamousName(date)
    end

    def calcDate(date1, date2)
        uri = URI.parse('http://localhost:9393/result')
        http = Net::HTTP.new(uri.host, uri.port)
        http.set_debug_output($stderr)
        format = "%Y-%m-%d"
        query_string = "birth1=#{date1.strftime(format)}&birth2=#{date2.strftime(format)}"
        req = Net::HTTP::Get.new(uri.path + (query_string.empty? ? "" : "?#{query_string}"))
        res = http.request(req)
        if res.code == "200"
            res_json = JSON.parse(res.body)
            Date.parse(res_json['date'])
        else
            p res
            fail("calc api error")
        end
    end

    def createReplyText(type, data)
        case type
        when "mannakaDate"
            "真ん中誕生日は#{data.month}月#{data.day}日です。 #mannaka_bot"
        when "famousName"
        else
        end
    end

    def postReply(client, user_id, text, reply_id)
        # client.update("@#{user_id} #{text}", in_reply_to_status_id: reply_id)
        p "update: @#{user_id} #{text}"
    end

end

conf = YAML.load_file('config/config.yml')
secret = YAML.load_file('config/secret.yml')
config = conf.merge(secret)

status_file_path = 'config/status'
if File.exist?(status_file_path)
    status = File.read(status_file_path, :encoding => Encoding::UTF_8)
    bot = MannakaBot.new(status, config)
else
    bot = MannakaBot.new(1, config)
end
result = bot.reply
File.write(status_file_path, result['last_id']) if result['status'] == "success"
