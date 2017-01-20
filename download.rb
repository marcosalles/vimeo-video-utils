# encoding: utf-8

require_relative "configs"
require_relative "vimeo_downloader"
require_relative "log"

class Download

	def initialize
		@maxThreads = Configs.threadThreshold
		@downloader = VimeoDownloader.new
		@log = Log.logger
	end

	def downloadAlbums
		hasNextPage = true
		albumPage = 1
		while hasNextPage
			rawAlbums = @downloader.getUserAlbums albumPage
			albumPage = rawAlbums[:page] += 1
			remaining = rawAlbums[:requestsRemaining]
			@log.info "Remaining requests: #{remaining}"
			@log.info "Will download [#{rawAlbums[:albums].count}] albums"
			hasNextPage = rawAlbums[:hasNext]
			rawAlbums[:albums].each do |album|
				if remaining <= Configs.requestThreshold
					@log.info "Waiting for request limit. Stopped at album[#{album[:id]}].."
					sleep @timeout
					@log.info "Back to work!"
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
			if videoAlreadyDownloaded course, videoId
				@log.info "Already downloaded file[#{course}/#{videoId}]. Skipping.."
			else
				videos << {
					course: course,
					videoId: videoId,
					downloaded: false
				}
			end
		end
		downloadVideos videos
	end
	private

	def videoAlreadyDownloaded course, videoId
		dirName = "#{Configs.downloadDirectory}/#{course}"
		fileName = "#{videoId}"
		Configs.videoQuality.each do |quality|
			path = "#{dirName}/#{fileName}-#{quality}.mp4"
			return true if File.file?(path)
		end
		false
	end

	def downloadAlbum album, startingAtVideo
		@log.info "Downloading album: #{album}"
		albumName = slug album[:name]
		albumId = album[:id]
		hasNextPage = true
		videoPage = 1
		while hasNextPage
			rawVideos = @downloader.getAlbumVideos albumId, videoPage
			videoPage = rawVideos[:page] += 1
			remaining = rawVideos[:requestsRemaining]
			@log.info "Remaining requests: #{remaining}"
			videosToDownload = rawVideos[:videos].count
			@log.info "Will download [#{videosToDownload}] videos"
			hasNextPage = rawVideos[:hasNext]
			lastDownloaded = startingAtVideo
			rawVideos[:videos].each_with_index do |video, index|
				if Thread.list.size > @maxThreads
					@log.info "Waiting for thread[#{Thread.list.size-1}/#{@maxThreads}] limit. Stopped at album[#{album[:id]}]/video[#{video[:id]}].."
					joinThreads
					@log.info "Back to work!"
				end
				if remaining - index <= Configs.requestThreshold
					sleepTime = videoInfo[:requestsResetIn]
					@log.info "Waiting (#{sleepTime}) for request[#{remaining - index}] limit. Stopped at album[#{album[:id]}]/video[#{video[:id]}].."
					sleep sleepTime
					@log.info "Back to work!"
					return downloadAlbum album, lastDownloaded
				end
				(Thread.new do
					downloadVideo albumName, video
				end)[:id] = "album[#{albumId}][#{videoId}]"
				lastDownloaded += 1
			end
		end
		joinThreads
		@log.info "Finished album[#{album[:id]}]"
	end

	def downloadVideos videos
		filteredVideos = videos.select{ |video| !video[:downloaded] }
		@log.info "Downloading videos.. will download [#{filteredVideos.size}] videos"
		filteredVideos.each do |video|
			courseName = video[:course]
			videoId = video[:videoId]
			if Thread.list.size > @maxThreads
				@log.info "Waiting for threads[#{Thread.list.size-1}/#{@maxThreads}] to join. Stopped at course[#{courseName}]/video[#{videoId}].."
				joinThreads
				@log.info "Back to work!"
			end
			videoInfo = @downloader.getVideoInfo videoId
			remaining = videoInfo[:requestsRemaining]
			@log.info "Remaining requests[#{remaining}], threads[#{Thread.list.size-1}/#{@maxThreads}]"
			if videoInfo[:error]
				@log.error "*** Video[#{videoId}] might not be owned by Alura."
				video[:downloaded] = true
				next
			end
			if remaining <= Configs.requestThreshold
				sleepTime = videoInfo[:requestsResetIn]
				@log.info "Waiting (#{sleepTime}) for request[#{remaining}] limit. Stopped at course[#{courseName}]/video[#{videoId}].."
				sleep sleepTime
				@log.info "Back to work!"
				return downloadVideos filteredVideos
			end
			@log.info "  Starting download for video[#{courseName}/#{videoId}].."
			(Thread.new do
				video[:downloaded] = downloadVideo courseName, videoInfo, videoId
			end)[:id] = "video[#{videoId}]"
		end
		joinThreads
		@log.info "Finished downloading all videos!"
	end

	def downloadVideo courseName, video, videoId
		downloaded = false
		Configs.videoQuality.each do |quality|
			video[:downloadLinks].each do |link|
				return true if downloaded
				if link[:quality].downcase.eql? quality
					downloaded ||= @downloader.downloadVideo courseName, videoId, link
					@log.info "  #{Thread.current[:id]}>> Failed to download video[#{videoId}][#{quality}]." if !downloaded
				end
			end
			@log.info "  #{Thread.current[:id]}>> Failed to download video[#{videoId}][#{quality}]. Quality not found."
		end
		downloaded
	end

	def slug text
		text.downcase.strip.gsub(" ", "-").gsub(/[^\w-]/, "")
	end

	def joinThreads
		Thread.list.each{|t| t.join unless t == Thread.current}
	end
end

Download.new.downloadVideosFromFile "videos.txt"
