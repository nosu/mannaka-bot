require 'sinatra'
require 'json'
require 'sinatra/cross_origin'

set :development, :production
set :port, 8080

configure do
      enable :cross_origin
end

class BirthdayApi
    def initialize
        @birth1 = 1
    end

    def error_400_param
        status = '400'
        "[error] Invalid parameters.\n"
    end

    def birth_calc(birth1, birth2)
        @birth1_type = validate_params(birth1)
        @birth2_type = validate_params(birth2)
        if @birth1_type == "year_date" && @birth2_type == "year_date"
            @result = {:type => "year_date", :date => year_date_calc(birth1, birth2)}
        elsif @birth1_type == "date" && @birth2_type == "date"
            @result = {:type => "date", :date => date_calc(birth1, birth2)}
        else
            error_400_param
        end
    end

    private

    def validate_params(birthday)
        reg_year_date = /[0-9]{4}-[01][0-9]-[0123][0-9]/
        reg_date = /[01][0-9]-[0123][0-9]/  
        if reg_year_date =~ birthday
            return "year_date"
        elsif reg_date =~ birthday
            return "date"
        else
            error_400_param
        end
    end

    def year_date_calc (birth1, birth2)
        @birth1 = Date.parse(birth1)
        @birth2 = Date.parse(birth2)
        @birth_array = judge_order_of_birthdays(@birth1, @birth2)
        @birth_array[0] + (@birth_array[1] - @birth_array[0])/2
    end
 
    def judge_order_of_birthdays (birth1, birth2)
        if @birth1 >= @birth2
            [@birth2, @birth1]
        else
            [@birth1, @birth2]
        end
    end
       
end

api = BirthdayApi.new

get '/result' do

    if !(params[:birth1] && params[:birth2]) then
        api.error_400_param
    else
        @result = api.birth_calc(params[:birth1], params[:birth2])
        @result.to_json
    end

end

