require 'open3'
module Scribble
  def load(path_ref)
    scribble_command = "../../../src/scribble/ct-lang-main.rkt"
    ct_lang = File.expand_path(scribble_command, __FILE__)
    print(ct_lang)
    tmp = path_ref.create_temporary
    stdin, stdout, stderr = Open3.popen3('racket', ct_lang, tmp.path)
    print(stderr.gets(nil))
    stdout.gets()
  end

  module_function :load
end
