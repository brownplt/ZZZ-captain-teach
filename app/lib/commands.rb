module Commands

  class InvalidCommand < Exception
  end

  class Version1
    def summary (tag)
      {type: "description", content: tag[:content]}
    end
  end

  # commands is a mapping from [VERSION, "TAGNAME"] to a function
  # that interprets the content of the specified tag.
  @versions = {1 => Version1.new()}

  def interp_tag(version, name, tag)
    pair = [version,name]
    if @versions.has_key?(version) and 
       @versions[version].respond_to?(name)
      @versions[version].send(name, tag)
    else
      raise InvalidCommand
    end
  end
  module_function :interp_tag
end
