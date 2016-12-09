class AlbumParser
	require "rubygems"
	require "json"

	def self.collectionAsJson response
		data = JSON.parse response.body
		{
			page: data["page"],
			hasNext: data["total"].to_f/data["per_page"] > data["page"],
			requestsRemaining: response["x-ratelimit-remaining"].to_i,
			albums: albumsAsJson(data["data"])
		}
	end

	private
	def self.albumsAsJson data
		albums = []
		data.each do |album|
			hasNoVideos = album["stats"].empty? || album["stats"]["videos"] < 1 || album["duration"] < 1
			name = album["name"]
			id = album["uri"].gsub(/.*\//, "")
			albums << {
				id: id,
				name: name,
				hasNoVideos: hasNoVideos
			}
		end
		albums
	end

end
