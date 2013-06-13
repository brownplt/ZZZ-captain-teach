module Commands

  class InvalidCommand < Exception
  end
  class InvalidTag < Exception
    attr :tag
    def initialize(tag)
      super
      @tag = tag
    end
  end

  def interp_tag(version, tag)
    if !tag.is_a?(Hash) or !tag.has_key?("tag") or !tag["tag"].is_a?(String)
      raise InvalidTag.new(tag)
    end
    name = tag["tag"]
    pair = [version,name]
    if @versions.has_key?(version) and
       @versions[version].respond_to?(name)
      @versions[version].send(name, tag)
    else
      raise InvalidCommand, tag
    end
  end
  module_function :interp_tag

  class Version1
    # NOTE(dbp): this just used so that we can test nested constructs
    def test(tag)
      {"type" => "test"}
    end
    def assignment(tag)
      if !tag.has_key?("name") or !tag["name"].is_a?(String) or
          !tag.has_key?("description") or !tag["description"].is_a?(String) or
          !tag.has_key?("instructions") or !tag["instructions"].is_a?(String) or
          !tag.has_key?("pieces") or !tag["pieces"].is_a?(Array)
        raise InvalidTag, tag
      end
      pieces = tag["pieces"].collect {|t|
        begin
          Commands::interp_tag(1, t)
        rescue InvalidCommand
          # an invalid command on a nested tag means this is
          # an invalid tag
          raise InvalidTag, tag
        end
      }
      { "type" => "assignment",
        "name" => tag["name"],
        "description" => tag["description"],
        "instructions" => tag["instructions"],
        "pieces" => pieces }
    end

    def tag_assert(tag, name, pred)
      if !tag.has_key?(name)
        raise InvalidTag, tag
      end
      if !pred.call(tag[name])
        raise InvalidTag, tag
      end
    end
    
    def function(tag)
      @string_checker = lambda {|field| field.is_a?(String) }
      @hash_nil_checker = lambda {|field| field.nil? or field.is_a?(Hash)}
      tag_assert(tag,"name", @string_checker)
      tag_assert(tag,"description", @string_checker)
      tag_assert(tag,"instructions", @string_checker)
      tag_assert(tag,"header", @hash_nil_checker)
      tag_assert(tag,"check_block", @hash_nil_checker)
      tag_assert(tag,"definition", @hash_nil_checker)
      
      header = tag["header"].nil? ? nil : 
        Commands::interp_tag(1, tag["header"])
      checkblock = tag["check_block"].nil? ? nil : 
        Commands::interp_tag(1, tag["check_block"])
      definition = tag["definition"].nil? ? nil : 
        Commands::interp_tag(1, tag["definition"])
      
      { "type" => "function",
        "name" => tag["name"],
        "description" => tag["description"],
        "instructions" => tag["instructions"],
        "header" => header,
        "check_block" => checkblock,
        "definition" => definition
        }
    end

    def header_given(tag)
      @string_checker = lambda {|field| field.is_a?(String) }
      @hash_nil_checker = lambda {|field| field.nil? or field.is_a?(Hash)}
      if !tag.has_key?("fun_name") or !tag["fun_name"].is_a?(String) or
          !tag.has_key?("instructions") or !tag["instructions"].is_a?(String) or
          # NOTE(dbp): only checking one level right now
          !tag.has_key?("arguments") or !tag["arguments"].is_a?(Array) or  
          !tag.has_key?("return") or !tag["return"].is_a?(String) or
          !tag.has_key?("purpose") or !tag["purpose"].is_a?(String)
        raise InvalidTag, tag
      end
      { "type" => "header",
        "editable" => false,
        "fun_name" => tag["fun_name"],
        "instructions" => tag["instructions"],
        "arguments" => tag["arguments"],
        "return" => tag["return"],
        "purpose" => tag["purpose"] }
    end

    def check_block(tag)
      tag
    end

    def definition(tag)
      tag
    end
  end

  # commands is a mapping from [VERSION, "TAGNAME"] to a function
  # that interprets the content of the specified tag.
  @versions = {1 => Version1.new()}

end
