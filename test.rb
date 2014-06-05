require 'chronic'
require 'openssl'
require 'geokit'
require_relative 'models/thing_to_do'
require_relative 'helpers/application_helper'
require_relative 'helpers/tour_helper'

tour_start = Chronic::parse('now')
tour_end = Chronic::parse('4 hours from now')
user_location = Geokit::LatLng.new(52.3693745, 4.8955443) # Somewhere in Amsterdam

events = TourHelper::find_events(tour_start, tour_end, user_location)

puts "Found #{events.length} things to do between #{tour_start} and #{tour_end}"

# Run algorithm to combine a location (latitude/longitude-pair) with these events to make a tour
tour = TourHelper::generate_tour(events, tour_start, tour_end, user_location)

event_count = 0
travel_count = 0
tour.each do |node|
  if node.class == ThingToDo
    event_count += 1
  else
    travel_count += 1
  end
end
puts "Calculated a tour with #{event_count} things to do and #{travel_count} travels"