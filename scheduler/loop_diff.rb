require 'date'
while (true) do

base_day = Date.new(2021, 1, 14)
now_day = Date.today
total_day = now_day - base_day
total_hour = total_day.to_i * 24

#base_day2 = Date.new(2020, 12, 14)
#total_day2 = now_day - base_day2
#total_hour_new = total_day2.to_i * 24

        system "bundle exec ruby diff_main.rb -c 29 -h 24"
        sleep(2*60)
       
        system "bundle exec ruby diff_main.rb -c 29 -h 168"
        sleep(2*60)
        
        system "bundle exec ruby diff_main.rb -c 29 -h #{total_hour}"
        sleep(60*720)
end
