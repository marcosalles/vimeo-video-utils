# Vimeo backup

Setup config file `configs.rb` with info needed for download and upload.
Download and all videos listed on file `resources/videos.txt`, one per line with pattern `folder uriEndingWithId`. Example:
```
foo //server.com/video/11111
bar //server.com/video/11112/download
//server.com/video/11113
```
- The first line will download the file `11111` to folder `foo`.
- The second line will download nothing because the uri does not END with the video vimeo id.
- The third line might break the program, didn't test that yet.

If `Configs.uploadFiles` is `true`, will try to upload files to both S3 and Glacier after download and then remove the files, working as a remote backup tool.

All logs are stored on `backup.log` file.

Run `ruby backup_manager.rb`
