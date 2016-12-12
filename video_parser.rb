class VideoParser
	require "rubygems"
	require "json"
	require "time"

	def self.videoAsJson response
		requestsRemaining = response["x-ratelimit-remaining"].to_i
		return error(requestsRemaining) if response.body.downcase.include? "<html"
		data = JSON.parse response.body
		return error(requestsRemaining) unless data["error"].nil?
		downloadLinks = downloadLinksFor data["download"]
		resetInSeconds = (Time.parse(response["x-ratelimit-reset"]).utc - Time.now.utc).to_i + 1
		{
			duration: data["duration"],
			requestsResetIn: resetInSeconds,
			requestsRemaining: requestsRemaining,
			downloadLinks: downloadLinks
		}
	end

	private

	def self.error requestsRemaining
		{ error: true, requestsRemaining: requestsRemaining }
	end

	def self.downloadLinksFor infos
		links = []
		infos.each do |info|
			links << {
				quality: info["quality"],
				type: info["type"],
				width: info["width"],
				height: info["height"],
				uri: info["link"],
				size: info["size"],
				md5: info["md5"]
			}
		end
		links
	end

end
