while (true) do
        system "bundle exec ruby main.rb -c 29"
        sleep(3*60)

        system "bundle exec ruby main.rb -c 29 -o"        
        sleep(3*60)

        system "bundle exec ruby main.rb -c 28"
        #sleep(3*60)

        #system "bundle exec ruby main.rb -c 28 -o"
        
        sleep(60*360)
end
