require 'rubygems'
require 'json'
require 'net/http'
require 'net/https'
require 'uri'
require 'sinatra'
require 'haml'

# search for a person based on first name, last name and location.  Location can be city and state or state or zip
def person_search(fname, lname, where)

  base_url = "https://proapi.whitepages.com/find_person/1.0/?api_key=8249b41718b02c013694000c6900061e;outputtype=JSON"
  url = "#{base_url};firstname=#{fname};lastname=#{lname};where=#{where}"
  uri = URI.parse(url)
  connection = Net::HTTP.new(uri.host, 443)
  connection.use_ssl = true

  resp = connection.request_get(uri.path + '?' + uri.query)

### make sure to throw an error if we get a 200 returned
  if resp.code != '200'
     raise "web service error"
  end

  data = resp.body

  # we convert the returned JSON data to native Ruby
  # data structure - a hash
  result = JSON.parse(data)

  # if the hash has 'Error' as a key, we raise an error
  if result.has_key? 'Error'
    raise "web service error"
  end

  return result
end



def print_persons (hash)
  people_list = hash
  puts "\e[H\e[2J"
  print "\nList of results matching your query \n\n"
  people_list['listings'].each do
    |people| 
    print people['displayname'], "\n"
    print people['address']['fullstreet'], "\n" 
    print people['address']['city'], ", "
    print people['address']['state'], " "
    print people['address']['zip'], "\n"

### need to test to make sure that nothing is null:  not everyone has a telephone
    if (!(people['phonenumbers'].nil? || people['phonenumbers'][0].nil? || people['phonenumbers'][0]['fullphone'].nil?) )
      print people['phonenumbers'][0]['fullphone'], "\n"
      end
    print "\n"
  end

end


## print the output to the website
def print_web (hash)
  people_list = hash
  display = []
  get '/' do
    people_list['listings'].each do
      |people| 
      display << people['displayname']
      display << people['address']['fullstreet'] 
      display << people['address']['city'] + ' ' + people['address']['state'] + ', ' + people['address']['zip']

### need to test to make sure that nothing is null:  not everyone has a telephone
      if (!(people['phonenumbers'].nil? || people['phonenumbers'][0].nil? || people['phonenumbers'][0]['fullphone'].nil?) )
        display << people['phonenumbers'][0]['fullphone']
      end
      display << "\n"
    end
    "<thml><body><pre>#{display.join("\n")}</pre></body></htmml>"
  end
end  




#### function to query the user for the search parameters.  Need to ensure that the inputs don't have newlines or spaces between words
def get_param ()
  puts "\e[H\e[2J"
  puts "Enter the first name:  "
  firstname = gets.chomp!                   #chomp to remove the newline from the input
  firstname.gsub!(/\s/,'+')                 # need to replace spaces with +
  puts "Enter the last name:  "
  lastname = gets.chomp!
  lastname.gsub!(/\s/,'+')                  # need to replace spaces with +

## need to ensure that the user enters a last name.  This is a requirement
  while lastname == ""
    puts "You can't have an empty lastname"
    puts "Enter the last name:  "
    lastname = gets.chomp!
    lastname.gsub!(/\s/,'+')                 # need to replace spaces with +
    end

  puts "Enter the location (zip, city/state or state)"
  location = gets.chomp!
  location.gsub!(/\s/,'+')                  # need to replace spaces with +

  params = [firstname, lastname, location]
end



search_param = get_param
persons = person_search(search_param[0],search_param[1],search_param[2])
print_persons (persons)
print_web(persons)



