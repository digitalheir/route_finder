require 'chronic'
require 'openssl'
require 'geokit'
require_relative 'models/venue'
require_relative 'models/event'
require_relative 'models/production'
require_relative 'helpers/application_helper'
require_relative 'helpers/tour_helper'

tour_start = Chronic::parse('now')
tour_end = Chronic::parse('6 hours from now')
user_location = Geokit::LatLng.new(52.3693745, 4.8955443) # Somewhere in Amsterdam

bounds = Geokit::Bounds::from_point_and_radius(user_location, 25, {units: :kms})
venues = Venue::get_venues(bounds)
puts "Found #{venues.length} nearby venues"

productions = Production::get_productions(bounds, tour_start, tour_end)
puts "Found #{productions.length} nearby productions with posible events"

# Find events
events = Event::get_events(venues, productions, bounds, tour_start, tour_end)
puts "Found #{events.length} things to do between #{tour_start} and #{tour_end}"

# Run algorithm to combine a location (latitude/longitude-pair) with these events to make a tour
tour = TourHelper::generate_tour(events.values, tour_start, tour_end, user_location)

event_count = 0
travel_count = 0
tour.each do |node|
  if node.class == Event
    event_count += 1
  else
    travel_count += 1
  end
end
puts "Calculated a tour with #{event_count} things to do and #{travel_count} travels"