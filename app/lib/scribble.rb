require 'open3'
module Scribble
  def render(path_ref)
    #scribble_command = "../../../src/scribble/ct-lang-main.rkt"
    #ct_lang = File.expand_path(scribble_command, __FILE__)
    source = path_ref.create_temporary
    dest = Tempfile.new(["scribble", '.html'])
    stdin, stdout, stderr = Open3.popen3('scribble', '--dest-name', dest.path, source.path)
    puts dest.path
    puts stdout.read
    puts stderr.read
    dest.seek(0)
    rv = dest.gets(nil)
    puts rv
    rv
  end

  module_function :render
end
