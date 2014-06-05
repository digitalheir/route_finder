require 'sparql/client'
require 'openssl'
require 'geokit'
require_relative 'sparql_queries'
require_relative '../models/travel_node'

module TourHelper
  def self.find_events(start_time, end_time, user_location)
    events = nil

    # Use user location to filter out events that are too far away (> 25 km)
    bounds = Geokit::Bounds::from_point_and_radius(user_location, 25, {units: :kms})
    query = SparqlQueries::events_that_have_lat_longs(start_time, end_time, bounds)

    # Make query against artsholland sparql endpoint
    # If we use the SPARQL client library, the server return a status 500 for some reason
    uri = URI('http://api.artsholland.com/sparql')
    response = Net::HTTP.new(uri.host, uri.port).start do |http|
      request = Net::HTTP::Post.new(uri)
      request.set_form_data({:query => query})
      request['Accept']='application/sparql-results+xml'
      http.request(request)
    end

    case response
      when Net::HTTPSuccess # Response code 2xx: success
        results = SparqlQueries::SPARQL_CLIENT.parse_response(response)
        events = ThingToDo.create_from_sparql_results(results).values
      when Net::HTTPRedirection
        #TODO follow redirect
        puts 'redirect'
      else
        #TODO handle error
        puts 'error'
    end
    #Return events array
    events
  end

  def self.generate_tour(events, at_time, tour_end, at_location, transportation=:walking)
    # Order events to distance from starting location
    events_with_distance = events.map do |event|
      distance = at_location.distance_to(event.latlng, {units: :kms})
      [distance, event]
    end
    events_with_distance.sort_by! do |event_with_distance|
      # Sort by distance
      event_with_distance[0]
    end

    events_with_distance.each do |event_with_distance|
      #TODO verify distances
      puts event[1].latlng
    end

    # Get route to closest event
    # TODO
    TravelNode.get_route(current_location, events_with_distance[0][1].latlng, transportation)
  end
end
