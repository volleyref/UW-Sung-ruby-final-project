require 'rubygems'
require 'json'
require 'net/http'
require 'net/https'
require 'uri'


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
  #print JSON.pretty_generate(people_list), "\n"    
  #print people_list.keys, "\n"
  #print JSON.pretty_generate(people_list['listings'][1])

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




#### function to query the user for the search parameters.  Need to ensure that the inputs don't have newlines or spaces between words
def get_param ()
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



