require 'date'
require 'parsedate'

module EventCalendarTags
  include Radiant::Taggable
  
  desc %{  <r:calendar>...</r:calendar>
           Calendar module root node. This global tag can be used anywhere on your site or within a Event Calendar page type context. In each 
           of these two contexts the tag does a slightly different thing. In particular when in the EventCalendar page type context the calendar
           events are queried based on request parameters following the page with that type.
           
           The attributes on the calendar node itself will override any request parameters.

           <r:calendar 
              [category=""] 
              [slugs="youth|adult"] 
              [period="week(month or year)"] 
              [periods=1]
              [begin-date="5-5-2007"] 
              [end-date="7-10-2007"] >
            <r:calendar />              

            * If a begin-date is set it will use it, if an end-date is set it will be used but ignored if there is a period.name set.
  }
  tag "calendar" do |tag|    
    es = EventSearch.new
    if self.class == EventCalendar
      es.category = tag.attr['category'] || @request.parameters[:url][1] || @request.parameters["category"]
      es.slugs = tag.attr['slugs'] || @request.path_parameters[:url][2] || @request.parameters["slugs"]
      es.period.begin_date = tag.attr['begin-date'] || @request.parameters["begin-date"]
      es.period.end_date = tag.attr['end-date'] || @request.parameters["end-date"]
      es.period.amount = tag.attr['periods'] || @request.parameters["periods"].to_i
      es.period.name = tag.attr['period'] || @request.path_parameters[:url][3] || @request.parameters["period"]
    else
      es.category = tag.attr['category']
      es.slugs = tag.attr['slugs']
      es.period.amount = tag.attr['periods']
      es.period.name = tag.attr['period']
    end    
    tag.locals.event_search = es
    tag.locals.events = es.execute
    tag.locals.calendars = tag.locals.events.collect { |e| e.calendar }.uniq unless tag.locals.events.nil?
    tag.expand
  end
  
  desc %{  <r:calendar:category />
          The category which the current event calendar is in. }    
  tag "calendar:category" do |tag|
    tag.locals.event_search.category
  end

  desc %{  <r:calendar:slugs />
          The comma separated list of "slugs" included in the current set of events.  }    
  tag "calendar:slugs" do |tag|
    # unless tag.locals.event_search.slugs.downcase == "all" || tag.locals.event_search.slugs.blank? || tag.locals.event_search.slugs.
      tag.locals.calendars.collect { |c| c.slug }.join(", ")
    # else
    #   "all"
    # end 
  end
   
  desc %{  <r:calendar:names />
          The comma separated list of calendar names included in the current set of events ("all" if all).  }    
  tag "calendar:names" do |tag|
    unless tag.locals.event_search.slugs.downcase == "all"
      tag.locals.calendars.collect { |c| c.name }.join(", ") unless tag.locals.calendars.nil?
    else
      "all"
    end
  end
   
  desc %{  <r:calendar:period />
          The name of the period for the current set of events.  }    
  tag "calendar:period" do |tag|
    tag.locals.event_search.period
  end

  desc %{  <r:calendar:periods />
          The number of periods the set of events spans.  }    
  tag "calendar:periods" do |tag|
    tag.locals.event_search.period.amount
  end
  
  desc %{  <r:calendar:begin_date format="" />
          The beginning date of the period of the currently selected events.  }    
  tag "calendar:begin_date" do |tag|
    format = tag.attr['format'].nil? ? "%d %b %y" : tag.attr['format']
    tag.locals.event_search.period.begin_date.strftime(format)
  end
   
  desc %{  <r:calendar:end_date format="" />
          The end date of the period of the currently selected events.  }    
  tag "calendar:end_date" do |tag|
    format = tag.attr['format'].nil? ? "%d %b %y" : tag.attr['format']
    tag.locals.event_search.period.end_date.strftime(format)    
  end

  desc %{  <r:calendar:nav format="" class="" />
          Container for calendar navigation links. Append :week, :month or :year to the end of 
          this tag to generate a link for each respective period which will always be relative to the 
          currently selected begin date. }      
  tag "calendar:nav" do |tag|
    tag.expand
  end

  ["week","month","year"].each do |period|
    tag "calendar:nav:#{period}_link" do |tag|
      %{
        <a href="#{period}" class="#{tag.attr['class']}#{' here' if tag.locals.event_search.period == period}">
          #{tag.expand.blank? ? period : tag.expand }
        </a>
      }
    end
  end

  tag "calendar:event" do |tag|      
    tag.expand
  end
  
  desc %{  <r:calendar:event:each />
          The main container tag / iterator for all events in the currently selected period and calendar set. }        
  tag "calendar:event:each" do |tag|
    events = tag.locals.events
    content = ''
    # To prime the header tag as per page_context page:children:each:header code...
    tag.locals.previous_headers = {}
    if tag.locals.events.length > 0 
      tag.locals.events.each do |event|
        tag.locals.event = event
        content << tag.expand
      end
    else
      content = "No events found."
    end
    content
  end
  
  desc %{  <r:calendar:event:each:header />
          Repeat the content between these tags once everytime it changes. }        
  tag 'calendar:event:each:header' do |tag|
    previous_headers = tag.locals.previous_headers
    name = tag.attr['name'] || :unnamed
    restart = (tag.attr['restart'] || '').split(';')
    header = tag.expand
    unless header == previous_headers[name]
      previous_headers[name] = header
      unless restart.empty?
        restart.each do |n|
          previous_headers[n] = nil
        end
      end
      header
    end
  end
   
  desc %{  <r:calendar:event:each:calendar_name />
          The name of the calendar which this event is associated with. }        
  tag "calendar:event:each:calendar_name" do |tag|
    tag.locals.event.calendar.name
  end
   
  desc %{  <r:calendar:event:each:calendar_description />
          The description of the calendar assocociated with this event. }
  tag "calendar:event:each:calendar_description" do |tag|
    tag.locals.event.calendar.description
  end
   
  desc %{  <r:calendar:event:each:id />
          The id of the current event. }
  tag "calendar:event:each:id" do |tag|
    tag.locals.event.id
  end
   
  desc %{  <r:calendar:event:each:title />
          The title of the event. }
  tag "calendar:event:each:title" do |tag|
    tag.locals.event.title
  end
   
  desc %{  <r:calendar:event:each:description />
          The full description of the event. }
  tag "calendar:event:each:description" do |tag|
    tag.locals.event.description
  end
   
  desc %{  <r:calendar:event:each:location />
          The location of the event. }
  tag "calendar:event:each:location" do |tag|
    tag.locals.event.location
  end


  desc %{  <r:calendar:event:each:start format=""/>
          The begin date of this event formatted according to the format attribute (there is no default value). }
  tag "calendar:event:each:start" do |tag|
    start_date = tag.locals.event.start_date.strftime(tag.attr['format'])
  end
   
  desc %{  <r:calendar:event:each:end format="" />
          The begin date of this event formatted according to the format attribute (there is no default value). }
  tag "calendar:event:each:end" do |tag|
    end_date = tag.locals.event.end_date.strftime(tag.attr['format'])
  end

   desc %{  <r:calendar:event:each:timeperiod format="" separator="" />
           The daterange of the event. Outputs "All Day" if 12-12 otherwise the begin_date - end_date range 
           formatted according to the format string (no default). The separator between begin and end date 
           defaults to - but can be set with the separator attribute. }
   tag "calendar:event:each:daterange" do |tag|
     if tag.locals.event.start_date.strftime("%x") == tag.locals.event.end_date.strftime("%x") then
       daterange = tag.locals.event.start_date.strftime(tag.attr['format'])
     else
       daterange = tag.locals.event.start_date.strftime(tag.attr['format']) << (tag.attr["separator"] || " - ") << tag.locals.event.end_date.strftime(tag.attr['format'])
     end
     daterange
   end


   # desc %{  <r:calendar:event:each:timeperiod format="">...</r:calendar:event:each:timeperiod>
   #         The timeperiod of the event. "All Day" or the formatted range e.g. begin_date - end_date }
   # tag "calendar:event:each:timeperiod" do |tag|
   #   if tag.locals.event.allday then
   #     timeperiod = "All Day"
   #   else
   #     timeperiod = tag.locals.event.start_date.strftime(tag.attr['format']) << " - " << tag.locals.event.end_date.strftime(tag.attr['format'])
   #   end
   #   timeperiod 
   # end
   
end