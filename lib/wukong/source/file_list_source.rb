module Wukong
  class Source

    # A FileListSource is a collection of files
    #
    # FileLists are lazy. When given a list of glob patterns for possible files to be included in the file list, instead of searching the file structures to find the files, a FileList holds the pattern for latter use.
    #
    # This allows us to define a number of FileList to match any number of files, but only search out the actual files when then FileList itself is actually used. The key is that the first time an element of the FileList/Array is requested, the pending patterns are resolved into a real list of file names.
    #
    # @see_also http://rdoc.info/gems/rake/Rake/FileList
    #
    class FileListSource < Wukong::Source
    end
  end
end
