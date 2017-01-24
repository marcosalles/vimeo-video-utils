# encoding: utf-8

class BackupManager
	require_relative "vimeo_dao"
	require_relative "local_dao"
	require_relative "amazon_dao"

	def initialize
		@log = Log.logger
		@vimeoDao = VimeoDAO.new
		@localDao = LocalDAO.new
		@amazonDao = AmazonDAO.new
		@maxThreads = Configs.threadThreshold
		@requestThreshold = Configs.requestThreshold
		@root = Configs.downloadDirectory
	end

	def backupFromFile fileName
		videos = @localDao.filteredVideosFromFile fileName
		backup videos
	end


	private

	def backup videos
		filteredVideos = videos.select{|v| !v[:backedUp]}
		@log.info "Backing up.. will backup [#{filteredVideos.size}] videos"
		filteredVideos.each do |video|
			path = video[:path]
			id = video[:id]
			@log.info "Will backup video[#{path}/#{id}]"
			if Thread.list.size > @maxThreads
				@log.info "Waiting for threads[#{Thread.list.size-1}/#{@maxThreads}] to join. Stopped at [#{path}]/video[#{id}].."
				joinThreads
				@log.info "Back to work!"
			end
			info = @vimeoDao.getVideoInfo video[:id]
			remaining = info[:requestsRemaining]
			@log.info "Remaining requests[#{remaining}], threads[#{Thread.list.size-1}/#{@maxThreads}]"
			if info[:error]
				@log.error "*** Video[#{id}] might not be owned by Alura."
				videoBackedUp video
				next
			end
			if remaining <= @requestThreshold
				sleepTime = info[:requestsResetIn]
				@log.info "Waiting (#{sleepTime}) for request[#{remaining}] limit. Stopped at [#{path}]/video[#{id}].."
				sleep sleepTime/10
				@log.info "Back to work!"
				return backup filteredVideos
			end
			@log.info "  Starting download for video[#{path}/#{id}].."
			(Thread.new do
				backupVideo video, info
				videoBackedUp video
			end)[:id] = "video[#{id}]"
		end
		joinThreads
		@log.info "Finished backing up all videos!"
	end

	def videoBackedUp video
		video[:backedUp] = true
		@localDao.addToBackupList video[:id]
	end

	def backupVideo video, info
		s3FilePath = @vimeoDao.downloadForS3 video, info
		if !s3FilePath.nil?
			@amazonDao.uploadToS3 s3FilePath, s3FilePath.gsub(/#{@root}\//, ""), Configs.storageRoot if Configs.uploadFiles
			glacierFilePath = @vimeoDao.downloadForGlacier video, info
			if !glacierFilePath.nil? && Configs.uploadFiles
				@amazonDao.uploadToGlacier glacierFilePath, glacierFilePath.gsub(/#{@root}/, ""), Configs.storageRoot
			end
		end
		if Configs.uploadFiles
			@localDao.deleteFile "#{s3FilePath}"
			@localDao.deleteFile "#{glacierFilePath}"
			@localDao.deleteFolder "#{@root}/#{video[:path]}"
		end
	end

	def joinThreads
		Thread.list.each{|t| t.join unless t == Thread.current}
	end

end


BackupManager.new.backupFromFile "../resources/videos.txt"
