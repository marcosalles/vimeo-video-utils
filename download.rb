# encoding: utf-8

require_relative "configs"
require_relative "vimeo_downloader"

class Download

	def initialize
		@maxThreads = Configs.threadThreshold
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

	def downloadVideosFromFile fileName
		content = File.open(fileName).read
		content.gsub! /\r\n?/, "\n"
		videos = []
		content.each_line do |line|

			course = line.split(" ")[0]
			videoId = line.split(" ")[1].gsub(/.*\//, "")
			videos << {
				course: course,
				videoId: videoId,
				downloaded: false
			}
		end
		downloadVideos videos
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
			puts "\nRemaining requests: #{remaining}\n"
			videosToDownload = rawVideos[:videos].count
			puts "Will download [#{videosToDownload}] videos\n"
			hasNextPage = rawVideos[:hasNext]
			lastDownloaded = startingAtVideo
			rawVideos[:videos].each_with_index do |video, index|
				if Thread.list.size > @maxThreads
					puts "Waiting for thread[#{Thread.list.size-1}/#{@maxThreads}] limit. Stopped at album[#{album[:id]}]/video[#{video[:id]}]..\n"
					joinThreads
					puts "Back to work!\n"
				end
				if remaining - index <= Configs.requestThreshold
					sleepTime = videoInfo[:requestsResetIn]
					puts "Waiting (#{sleepTime}) for request[#{remaining - index}] limit. Stopped at album[#{album[:id]}]/video[#{video[:id]}]..\n"
					sleep sleepTime
					puts "Back to work!\n"
					return downloadAlbum album, lastDownloaded
				end
				(Thread.new do
					downloadVideo albumName, video
				end)[:id] = "album[#{albumId}][#{videoId}]"
				lastDownloaded += 1
			end
		end
		joinThreads
		puts "Finished album[#{album[:id]}]"
	end

	def downloadVideos videos
		filteredVideos = videos.select{ |video| !video[:downloaded] }
		puts "Downloading videos.. will download [#{filteredVideos.size}] videos\n"
		filteredVideos.each do |video|
			courseName = video[:course]
			videoId = video[:videoId]
			if Thread.list.size > @maxThreads
				puts "Waiting for threads[#{Thread.list.size-1}/#{@maxThreads}] to join. Stopped at course[#{courseName}]/video[#{videoId}]..\n"
				joinThreads
				puts "Back to work!\n"
			end
			videoInfo = @downloader.getVideoInfo videoId
			remaining = videoInfo[:requestsRemaining]
			puts "\nRemaining requests[#{remaining}], threads[#{Thread.list.size-1}/#{@maxThreads}]\n"
			if videoInfo[:error]
				puts "\t** ERROR video[#{videoId}] might not be owned by Alura.\n"
				video[:downloaded] = true
				next
			end
			if remaining <= Configs.requestThreshold
				sleepTime = videoInfo[:requestsResetIn]
				puts "Waiting (#{sleepTime}) for request[#{remaining}] limit. Stopped at course[#{courseName}]/video[#{videoId}]..\n"
				sleep sleepTime
				puts "Back to work!\n"
				return downloadVideos filteredVideos
			end
			puts "\tStarting download for video[#{courseName}/#{videoId}]..\n"
			(Thread.new do
				video[:downloaded] = downloadVideo courseName, videoInfo, videoId
			end)[:id] = "video[#{videoId}]"
		end
		joinThreads
		puts "Finished downloading all videos!\n"
	end

	def downloadVideo courseName, video, videoId
		downloaded = false
		Configs.videoQuality.each do |quality|
			video[:downloadLinks].each do |link|
				return true if downloaded
				if link[:quality].downcase.eql? quality
					downloaded ||= @downloader.downloadVideo courseName, videoId, link
					puts "\t>#{Thread.current[:id]}> Failed to download video[#{videoId}][#{quality}].\n" if !downloaded
				end
			end
			puts "\t>#{Thread.current[:id]}> Failed to download video[#{videoId}][#{quality}]. Quality not found.\n"
		end
		downloaded
	end

	def slug text
		text.downcase.strip.gsub(" ", "-").gsub(/[^\w-]/, "")
	end

	def joinThreads
		Thread.list.each{ |t| t.join unless t == Thread.current}
	end
end

Download.new.downloadVideosFromFile "videos.txt"
