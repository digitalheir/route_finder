require 'geokit'
require_relative '../helpers/sparql_queries'

class Event
  attr_reader :uri
  attr_reader :eventType
  attr_reader :titles
  attr_reader :start
  attr_reader :end
  attr_reader :venue
  attr_reader :production
  attr_reader :images

  def initialize(uri, eventType, titles, start_time, end_time, venue, production, images)
    @uri = uri
    @eventType = eventType
    @titles = titles
    @start = start_time
    @end = end_time
    @venue = venue
    @production = production
    @images = images
  end

  # Returns a map of venue uris to venues
  def self.get_events(venues, bounds, start_time, end_time)
    events_sparql = SparqlQueries.events(bounds, start_time, end_time)
    puts "Query events from #{SparqlQueries::SPARQL_ENDPOINT}"
    # Make query
    response = Net::HTTP.new(SparqlQueries::SPARQL_ENDPOINT.host, SparqlQueries::SPARQL_ENDPOINT.port).start do |http|
      request = Net::HTTP::Post.new(SparqlQueries::SPARQL_ENDPOINT)
      request.set_form_data({:query => events_sparql})
      request['Accept']='application/sparql-results+xml'
      http.request(request)
    end

    events = nil
    case response
      when Net::HTTPSuccess # Response code 2xx: success
        results = SparqlQueries::SPARQL_CLIENT.parse_response(response)
        events = create_from_sparql_results(venues, results)
      when Net::HTTPRedirection
        #TODO follow redirect
        puts 'redirect'
      else
        #TODO handle error
        puts 'error'
    end
    #Return events map
    events
  end

  def self.create_from_sparql_results(venues, results)
    events = {}
    values_map = {}
    results.each do |result|
      uri = result['event'].value
      event = values_map[uri]
      unless event
        # Note that we use sets, so duplicate values are not added
        event = {:titles => {}, :images => Set.new}
        values_map[uri] = event
      end

      if result['eventType']
        event[:eventType] = result['eventType']
      end
      if result['start']
        event[:start] = result['start']
      end
      if result['end']
        event[:end] = result['end']
      end
      if result['venue']
        venue = venues[result['venue'].to_s]
        unless venue
          puts "WARNING: venue #{result['venue'].to_s} not found."
        end
        event[:venue] = venue
      end
      if result['production']
        event[:production] = result['production']
      end

      if result['title']
        add_title event, result['title']
      end

      if result['imageUrl']
        event[:images] << result['imageUrl']
      end
    end

    values_map.each do |uri, vals|
      events[uri] = Event.new(uri, vals[:eventType], vals[:titles], vals[:start], vals[:end], vals[:venue], vals[:production], vals[:images])
    end
    return events
  end

  def self.add_title(map, title)
    titles_for_lang = map[title.language]
    unless titles_for_lang
      titles_for_lang=Set.new
      map[title.language] = titles_for_lang
    end
    titles_for_lang << title
  end
end