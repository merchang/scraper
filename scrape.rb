token = ''

require 'rest-client'
require 'json'
require 'optparse'

def scraper(url, token)
  output = []
  fetch = RestClient.get url, {:Authorization => 'Bearer ' + token}
  output.push(JSON.parse(fetch))
  page_count = 1
  header_links = fetch.headers[:link]

  while header_links.include? 'rel="next"'
    next_page = header_links.split(',')[1].split(';')[0].gsub(/\<|\>/, "")
    fetch_next = RestClient.get next_page, {:Authorization => 'Bearer ' + token}
    header_links = fetch_next.headers[:link]
    output.push(JSON.parse(fetch_next))
    print '#'
    page_count += 1
  end

  puts " 100% – #{page_count} pages scraped"
  json = JSON.pretty_generate(output)
  filename = "scraper-#{Time.now.to_i}"
  File.open("#{filename}.json", 'w') {|f| f.write(json) }

  puts "output => #{filename}.json 👍 🍕"
end

def url_helper(url)
  if url.include? "https://"
    return url
  else
    return "https://" + url
  end
end

parser = OptionParser.new do|opts|
  opts.banner = <<-BANNER
  Usage: `scrape -u url.edu/api/v1/your/endpoint`

  1. Pageinates through *all* data of provided endpoint 
  2. Returns .json file of returned data

  NOTE:
  - A token must be set in this file. Edit line 1 of scraper.rb, setting your token to the token variable.
  - Special characters in your URL (ex: ? & []) will likely need to be escaped in your command line using a backshlash "\"
  
  BANNER

  opts.on('-u', '--url url', 'Accepts Canvas API URL [required]') do |url|
    scraper(url_helper(url), token)
    exit
  end
	opts.on('-h', '--help', 'Displays the help menu') do
		puts opts
		exit 
	end
end

parser.parse!
puts 'Please pass a valid URL using the -u argument. See --help for more info'