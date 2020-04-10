token = ''

require 'rest-client'
require 'json'
require 'optparse'

def scraper(url, token, utility)
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

  return output if utility == true

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

def quiz_timeline(url, token)
  print "Grabing quiz... "
  quiz = JSON.parse(RestClient.get url, {:Authorization => 'Bearer ' + token})
  puts "✅"
  version = quiz["quiz_version"]
  # get assignment object inforamtion
  a_id = quiz["assignment_id"]
  print "Checking assignment object... "

  unless a_id.nil?
    a_url = url.split("quizzes")[0] + "assignments/#{a_id}"
    a_json = JSON.parse(RestClient.get a_url, {:Authorization => 'Bearer ' + token})
    a_created = a_json["created_at"]
    a_updated = a_json["updated_at"]
  end
  puts "✅"
  # aquire submissions
  print "Collecting quiz submissions... "
  sub_url = url + "/submissions?per_page=100"
  scrape = scraper(sub_url, token, true)
  submissions = []
  # transform submission data into orderly array of hashes
  scrape.each { |s| submissions.concat(s["quiz_submissions"])}
  # find submissions with multiple attempts
  multi = submissions.select { |k,v| k["attempt"] > 1 }
  # collect all previous attempts
  multi.each do |s|
    attempt_count = s["attempt"] - 1
    while attempt_count > 0
      prev_url = url + "/submissions/#{s["id"]}?attempt=#{attempt_count}"
      prev_attempt = JSON.parse(RestClient.get prev_url, {:Authorization => 'Bearer ' + token})
      submissions.concat(prev_attempt["quiz_submissions"])
      attempt_count =- 1
    end
  end
  puts "✅"

  puts "Analyizing submission information ⏳"
  # group submissions by quiz version
  grouped = submissions.group_by { |x| x["quiz_version"] }
  # grouped.first[1][0]["started_at"]
  # collect the earliest submission of each version
  start_times = []
  grouped.keys.each do |v|
    sorted = grouped[v].sort_by { |x| x["started_at"] }
    first = sorted.first["started_at"]
    last = sorted.last["started_at"]
    start_times.push({ "version" => v, "first_attempt" => first, "last_attempt" => last })
  end
  puts ""
  puts "Complete 🍻"
  puts ""
  puts "#{submissions.count} total submissions to quiz"
  puts "No assignment object associated to quiz" if a_id.nil?
  puts "#{grouped.keys.count} different quiz versions taken by students"
  puts "#{a_created} : assignment object created"
  puts "#{a_updated} : assignment object last updated"
  puts "============"
  start_times.sort_by! { |x| x["version"] }
  start_times.each do |v|
    puts "#{v["first_attempt"]} : version #{v["version"]} first taken"
    puts "#{v["last_attempt"]} : version #{v["version"]} last taken"
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

  Utility Commands:
  `-q` Accepts quiz URL, returns a timeline of quiz version changes according to submission data
  
  BANNER

  opts.on('-u', '--url url', 'Accepts Canvas API URL [required]') do |url|
    scraper(url_helper(url), token, false)
    exit
  end
	opts.on('-h', '--help', 'Displays the help menu') do
		puts opts
		exit 
  end
  
  opts.on('-q', '--quiz quiz', 'Accepts Canvas quiz URL') do |quiz|
    quiz_timeline(url_helper(quiz), token)
    exit
  end

end

parser.parse!
puts 'Please pass a valid URL using the -u argument. See --help for more info'