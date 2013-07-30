require 'open3'
module Scribble

  class ScribbleError < Exception
  end

  def render(source)
    # NOTE(dbp): if we don't end it in .html, scribble adds that
    # for us.
    dest = Tempfile.new(["scribble", '.html'])
    path = Pathname.new(dest.path)
    # NOTE(dbp): --dest-name is confusing - if you pass it an
    # absolute path, it essentially basenames it. --dest, on the
    # other hand, sets the directory. Combining both, we can tell
    # it where to put the output. NB@joe: trying hard to do your
    # resolution for the year.
    Open3.popen3('scribble', '--dest', 
                 path.dirname.to_s, 
                 '--dest-name', path.basename.to_s, 
                 source.path) do |stdin, stdout, stderr, wait|
      # an ode to "wouldn't it be nice if scribble 
      # had a stdout option"
      wait.value # wait for the process to end
      
      err = stderr.gets(nil) # pass any errors up
      if !err.nil?
        raise ScribbleError,err
      end
      dest.rewind # go to the beginning of temp file
      @rv = dest.gets(nil) # read contents (what scribble wrote)
    end
    @rv
  end
  
  module_function :render
end
