class VideoParser
	require "rubygems"
	require "json"

	def self.collectionAsJson response
		data = JSON.parse response.body
		{
			page: data["page"],
			hasNext: data["total"].to_f/data["per_page"] > data["page"],
			requestsRemaining: response["x-ratelimit-remaining"].to_i,
			videos: videosAsJson(data["data"])
		}
	end

	private
	def self.videosAsJson data
		videos = []
		data.each do |video|
			id = video["uri"].gsub(/.*\//, "")
			name = video["name"]
			downloadLinks = downloadLinksFor video["download"]
			videos << {
				id: id,
				name: name,
				downloadLinks: downloadLinks
			}
		end
		videos
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
