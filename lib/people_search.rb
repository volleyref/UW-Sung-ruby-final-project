require 'rubygems'
require 'json'
require 'net/http'
require 'net/https'
require 'uri'
require 'sinatra'

# search for a person based on first name, last name and location.  Location can be city and state or state or zip
def person_search(fname, lname, where)

  base_url = "https://proapi.whitepages.com/find_person/1.0/?api_key=8249b41718b02c013694000c6900061e;outputtype=JSON"
  url = "#{base_url};firstname=#{fname};lastname=#{lname};where=#{where}"
  uri = URI.parse(url)
  connection = Net::HTTP.new(uri.host, 443)
  connection.use_ssl = true

  resp = connection.request_get(uri.path + '?' + uri.query)

  ### make sure to throw an error if we get a 200 returned
  raise "web service error" if resp.code != '200'

  data = resp.body

  # we convert the returned JSON data to native Ruby
  # data structure - a hash
  result = JSON.parse(data)

  # if the hash has 'Error' as a key, we raise an error
  raise "web service error" if result.has_key? 'Error'

  result
end

#
# Convert the Hash response to a multiline output to be displayed on the screen
# and the web.
# 
# @param [Hash] hash is the data in the format of a response from the WhitePages
#   API.
#
def render_results(people_list)
  
  people = people_list['listings'].map do |people| 
    
    person_information = people['displayname'] + "\n" +
      people['address']['fullstreet'] + "\n" +
      people['address']['city'] + ", " + 
      people['address']['state'] + " " +
      people['address']['zip'] + "\n"

    ### need to test to make sure that nothing is null:  not everyone has a telephone
    if people['phonenumbers'] and people['phonenumbers'][0] and people['phonenumbers'][0]['fullphone']
      person_information += people['phonenumbers'][0]['fullphone'] + "\n"
    end
      
    person_information
  end
  
  people.join("\n")
  
end

def print_persons(people_list)
  puts "\e[H\e[2J"
  puts "List of results matching your query\n\n"
  puts render_results(people_list)
  puts "\n\n"
end

## print the output to the website
def print_web(people_list)
  get '/' do
    "<html><body><pre>#{render_results(people_list)}</pre></body></htmml>"
  end
end  




#### function to query the user for the search parameters.  Need to ensure that the inputs don't have newlines or spaces between words
def get_param
  puts "\e[H\e[2J"
  puts "Enter the first name:  "
  firstname = gets.chomp!                   #chomp to remove the newline from the input
  firstname.gsub!(/\s/,'+')                 # need to replace spaces with +
  puts "Enter the last name:  "
  lastname = gets.chomp!

  ## need to ensure that the user enters a last name.  This is a requirement
  while lastname.strip == ""
    puts "You can't have an empty lastname"
    puts "Enter the last name:  "
    lastname = gets.chomp!
  end

  lastname.gsub!(/\s/,'+')                  # need to replace spaces with +
  
  puts "Enter the location (zip, city/state or state)"
  location = gets.chomp!
  location.gsub!(/\s/,'+')                  # need to replace spaces with +

  [ firstname, lastname, location ]
end



firstname, lastname, location = get_param
persons = person_search(firstname, lastname, location)
print_persons(persons)
print_web(persons)
