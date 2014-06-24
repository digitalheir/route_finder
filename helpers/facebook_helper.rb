require 'koala'

require_relative '../models/venue'
require_relative '../models/event'

class FacebookHelper
    attr_reader :token

    def initialize()
        user = self.GetFacebookTestUser()

        @token = user["access_token"]
        
    end
    #Superhacky way to get around openssl errors. Not fit for any production code
    OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

    APP_ID = "483468301796568"
    SECRET = "5b321735caca4690e61fda1e47210f05"
    
    def GetFacebookTestUser()
        test_users = Koala::Facebook::TestUsers.new(:app_id => APP_ID, :secret => SECRET)
        
        user = test_users.create(true, "user_events")
        
        return user      
    end

    def GatherVenuesAndEvents()
        graph = Koala::Facebook::API.new(self.token)

        events_raw = []
        
        #Find all possible venues
        results = graph.search("*", {'type' => "place","center" => "52.3758, 4.9022", "distance" => "5000", "fields" => "location,name,cover"}) 
        puts "Venues:  #{results.length}"
        
        proc_venues = []

        results.each {|result| 
            #Check if the places we found are connected to any events
            events = graph.get_object("#{result['id']}/events", {"fields" => "id, name, start_time, end_time, cover, description"})
            
            if events.length != 0
                #Gather coordinates
                lat  = Float(result["location"]["latitude"])
                long = Float(result["location"]["longitude"])

                latlng = Geokit::LatLng.new(lat, long)
                
                #Check for cover photo
                if result.key?("cover")
                    cover_photo = result["cover"]["source"]
                else
                    cover_photo = ""
                end

                name = result["name"]

                titles = {":en" => name, ":nl" => name}
                images = [cover_photo]

                #Use facebook page as a URI
                venue = Venue.new("https://www.facebook.com/#{name}", titles, images, latlng, lat, long)
                
                proc_venues << venue
                
                #we add events to the events_raw data
                events.each { |event| events_raw << {"event" => event,"venue" => venue} }                
                
            end
                       
        }
        proc_events = []
        puts "Events:  #{events_raw.length}"
        
        events_raw.each{ |event|
            uri = "https://www.facebook.com/events/#{event['id']}"
            titles = {":nl" => event["name"]}

            if event.key?("cover")
                cover_photo = event["cover"]["source"]
            else
                cover_photo = ""
            end

            images = [cover_photo]
            start_time = event["start_time"]
            
            if event.key?("end_time")
                end_time = event["end_time"]
            else
                end_time = nil
            end
            production = ""

            if event.key?("description")
                descriptions = [event["description"]]
                short_descriptions = [event["description"][0,100]]
            else
                descriptions = [""]
                short_descriptions = [""]
            end

            venue = event["venue"]
            event = Event.new(uri, titles, start_time, end_time, venue, production, images, descriptions, short_descriptions)
            proc_events << event
            
        }

        return {"events" => proc_events, "venues" => proc_venues}
        
    end

end