module Commands

  class InvalidCommand < Exception
  end
  class InvalidTag < Exception
  end

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

  class Version1
    def assignment(tag)
      if !tag.has_key?(:tag) or tag[:tag] != "assignment" or
          !tag.has_key?(:name) or !tag[:name].is_a?(String) or
          !tag.has_key?(:description) or !tag[:description].is_a?(String) or
          !tag.has_key?(:instructions) or !tag[:instructions].is_a?(String) or
          !tag.has_key?(:pieces) or !tag[:pieces].is_a?(Array)
        raise InvalidTag
      end
      pieces = tag[:pieces].each {|t|
        if !t.is_a?(Hash) or !t.has_key?(:tag)
          raise InvalidTag
        end
        begin
          Commands::interp_tag(1, t[:tag], t)
        rescue InvalidCommand => e
          # an invalid command on a nested tag means this is
          # an invalid tag
          raise InvalidTag
        end
      }
      { type: "assignment",
        name: tag[:name],
        description: tag[:description],
        instructions: tag[:instructions],
        pieces: pieces }
    end
  end

  # commands is a mapping from [VERSION, "TAGNAME"] to a function
  # that interprets the content of the specified tag.
  @versions = {1 => Version1.new()}

end
