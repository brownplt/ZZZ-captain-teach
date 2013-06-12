module Commands

  class InvalidCommand < Exception
  end
  class InvalidTag < Exception
  end

  def interp_tag(version, tag)
    if !tag.is_a?(Hash) or !tag.has_key?(:tag) or !tag[:tag].is_a?(String)
      raise InvalidTag
    end
    name = tag[:tag]
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
    # NOTE(dbp): this just used so that we can test nested constructs
    def test(tag)
      {type: "test"}
    end
    def assignment(tag)
      if !tag.has_key?(:name) or !tag[:name].is_a?(String) or
          !tag.has_key?(:description) or !tag[:description].is_a?(String) or
          !tag.has_key?(:instructions) or !tag[:instructions].is_a?(String) or
          !tag.has_key?(:pieces) or !tag[:pieces].is_a?(Array)
        raise InvalidTag
      end
      pieces = tag[:pieces].each {|t|
        begin
          Commands::interp_tag(1, t)
        rescue InvalidCommand
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

    def function(tag)
      if !tag.has_key?(:name) or !tag[:name].is_a?(String) or
          !tag.has_key?(:description) or !tag[:description].is_a?(String) or
          !tag.has_key?(:instructions) or !tag[:instructions].is_a?(String) or
          !tag.has_key?(:header) or !(tag[:header].nil? or tag[:header].is_a?(Hash)) or
          !tag.has_key?(:checkblock) or !(tag[:checkblock].nil? or tag[:checkblock].is_a?(Hash)) or
          !tag.has_key?(:definition) or !(tag[:definition].nil? or tag[:definition].is_a?(Hash))
        raise InvalidTag
      end
      
      header = tag[:header].nil? ? nil : 
        Commands::interp_tag(1, tag[:header])
      checkblock = tag[:checkblock].nil? ? nil : 
        Commands::interp_tag(1, tag[:checkblock])
      definition = tag[:definition].nil? ? nil : 
        Commands::interp_tag(1, tag[:definition])
      
      { type: "function",
        name: tag[:name],
        description: tag[:description],
        instructions: tag[:instructions],
        header: header,
        checkblock: checkblock,
        definition: definition
        }
      
    end
  end

  # commands is a mapping from [VERSION, "TAGNAME"] to a function
  # that interprets the content of the specified tag.
  @versions = {1 => Version1.new()}

end
