require 'oauth'
require 'json'
require 'yaml'

MIN_FOLLOWERS = 10
WAIT_TIME_BETWEEN_POSTS = 3

CONSUMER_KEY = "YOUR_CONSUMER_KEY"
CONSUMER_SECRET = "YOUR_CONSUMER_SECRET"
ACCESS_TOKEN = "YOUR_ACCESS_TOKEN"
ACCESS_SECRET = "YOUR_ACCESS_SECRET"

SEARCH_STRING = "Tick"
REPLY_STRING = "Tock"

script_status = YAML::load_file "status.yml"

# Exchange your oauth_token and oauth_token_secret for an AccessToken instance.
def prepare_access_token(oauth_token, oauth_token_secret)
    consumer = OAuth::Consumer.new(CONSUMER_KEY, CONSUMER_SECRET, { :site => "https://api.twitter.com", :scheme => :header })
     
    # now create the access token object from passed values
    token_hash = { :oauth_token => oauth_token, :oauth_token_secret => oauth_token_secret }
    access_token = OAuth::AccessToken.from_hash(consumer, token_hash )
 
    return access_token
end
 
def post_status_update(status_id, status_msg) 
	# Exchange our oauth_token and oauth_token secret for the AccessToken instance.
	access_token = prepare_access_token(ACCESS_TOKEN, ACCESS_SECRET)
	 
	# use the access token as an agent to get the home timeline
	response = access_token.request(:post, "https://api.twitter.com/1.1/statuses/update.json?in_reply_to_status_id=#{status_id}&status=#{status_msg}")
end 

# Exchange our oauth_token and oauth_token secret for the AccessToken instance.
access_token = prepare_access_token(ACCESS_TOKEN, ACCESS_SECRET)
 
# use the access token as an agent to get the home timeline
response = access_token.request(:get, "https://api.twitter.com/1.1/search/tweets.json?q=#{SEARCH_STRING}&since_id=#{script_status['since_id']}")

tweets = JSON.parse(response.body)
tweets["statuses"].reverse.each do |tweet|

	username = tweet["user"]["screen_name"]
	text = tweet["text"]
	followers = tweet["user"]["followers_count"]
	status_id = tweet["id"]
	date = tweet["created_at"]

	# Eliminate any retweets so as not to have duplicates
	is_retweet = (text[0..3] == "RT @") ? true : false

	if !is_retweet && followers.to_i > MIN_FOLLOWERS
		post_status_update(status_id, REPLY_STRING)
		sleep(WAIT_TIME_BETWEEN_POSTS)
	end

	# Update your status to the most recent status_id
	script_status['since_id'] = status_id

end

File.open("status.yml", "w") do |file|
  file.write script_status.to_yaml
end