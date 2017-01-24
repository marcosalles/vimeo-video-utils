# encoding: utf-8

class LocalDAO
	require "fileutils"

	def initialize
		@log = Log.logger
		@backedUpFileName = "../resources/backedUpIds.txt"
	end

	def filteredVideosFromFile fileName
		file = File.open(fileName)
		content = file.read
		content.gsub! /\r\n?/, "\n"
		videos = []
		videosToRemove = alreadyBackedUpVideos
		content.each_line do |line|
			path = line.split(" ")[0]
			id = line.split(" ")[1].gsub(/.*\//, "")
			if videosToRemove[id.to_i]
				@log.debug "File[#{path}/#{id}] will be skipped.."
			else
				videos << {
					path: path,
					id: id,
					backedUp: false
				}
			end
		end
		file.close
		videos
	end

	def addToBackupList id
		file = File.open(@backedUpFileName, "a")
		file.puts id
		file.close
	end

	def deleteFile path
		File.delete(path) if File.exists?(path)
		@log.info "Deleted file #{path}"
	end

	def deleteFolder path
		FileUtils::rmdir(path) if Dir.exists?(path) && Dir.entries(path).size <= 2
		@log.info "Deleted folder #{path}"
	end

	private

	def alreadyBackedUpVideos
		file = File.open(@backedUpFileName)
		content = file.read
		videos = {}
		content.each_line do |line|
			videos[line.to_i] = true
		end
		file.close
		videos
	end

end