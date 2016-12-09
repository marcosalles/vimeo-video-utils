# encoding: utf-8

require_relative "configs"
require_relative "vimeo_downloader"

class Download

	def initialize
		@threads = []
		@timeout = 60*40 #40min
		@downloader = VimeoDownloader.new
	end

	def downloadAlbums
		hasNextPage = true
		albumPage = 1
		while hasNextPage
			rawAlbums = @downloader.getUserAlbums albumPage
			albumPage = rawAlbums[:page] += 1
			remaining = rawAlbums[:requestsRemaining]
			puts "Remaining requests: #{remaining}\n"
			puts "Will download [#{rawAlbums[:albums].count}] albums\n"
			hasNextPage = rawAlbums[:hasNext]
			rawAlbums[:albums].each do |album|
				if remaining <= Configs.requestThreshold
					puts "Waiting for request limit. Stopped at album[#{album[:id]}]..\n"
					sleep @timeout
					puts "Back to work!\n"
				end
				downloadAlbum album, 0 unless album[:hasNoVideos]
			end
		end
	end

	private

	def downloadAlbum album, startingAtVideo
		puts "Downloading album: #{album}\n"
		albumName = slug album[:name]
		albumId = album[:id]
		hasNextPage = true
		videoPage = 1
		while hasNextPage
			rawVideos = @downloader.getAlbumVideos albumId, videoPage
			videoPage = rawVideos[:page] += 1
			remaining = rawVideos[:requestsRemaining]
			puts "Remaining requests: #{remaining}\n"
			videosToDownload = rawVideos[:videos].count
			puts "Will download [#{videosToDownload}] videos\n"
			hasNextPage = rawVideos[:hasNext]
			lastDownloaded = startingAtVideo
			rawVideos[:videos].each do |video|
				if remaining <= Configs.requestThreshold
					puts "Waiting for request limit. Stopped at album[#{album[:id]}]/video[#{video[:id]}]..\n"
					sleep @timeout
					puts "Back to work!\n"
					return downloadAlbum album, lastDownloaded
				end
				@threads << Thread.new do
					downloadVideo albumName, video, Configs.quality
				end
				lastDownloaded += 1
			end
		end
		@threads.map(&:join)
		puts "Finished album[#{album[:id]}]"
	end

	def downloadVideo albumName, video, quality
		downloaded = false
		video[:downloadLinks].each do |link|
			return if downloaded
			if link[:quality].downcase.eql? quality
				downloaded ||= @downloader.downloadVideo albumName, video[:id], link
			end
		end
		puts "\tFailed to download video[#{video[:id]}][#{quality}]. Quality not found.\n"
	end

	def slug text
		text.downcase.strip.gsub(" ", "-").gsub(/[^\w-]/, "")
	end

end

Download.new.downloadAlbums
