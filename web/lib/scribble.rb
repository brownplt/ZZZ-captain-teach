require 'open3'
module Scribble
  def render(path_ref)
    #scribble_command = "../../../src/scribble/ct-lang-main.rkt"
    #ct_lang = File.expand_path(scribble_command, __FILE__)
    source = path_ref.create_temporary
    dest = Tempfile.new(["scribble", '.html'])
    path = Pathname.new(dest.path)
    rv = "NO VALUE"
    Open3.popen3('scribble', '--dest', path.dirname.to_s, '--dest-name', path.basename.to_s, source.path) do |stdin, stdout, stderr|
      dest.rewind
      rv = dest.gets(nil)
    end
    rv
  end

  module_function :render
end
