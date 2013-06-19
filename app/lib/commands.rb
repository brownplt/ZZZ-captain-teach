module Commands

  class InvalidTag < Exception
    attr :tag, :msg
    def initialize(tag, msg)
      super("#{msg}: #{tag}")
      @tag = tag
      @msg = msg
    end
  end

  R = "r"
  RW = "rw"
  RC = "rw"
    
  module Helpers
    
    def self.tag_assert(tag, name, type)
      if !tag.is_a?(Hash)
        raise InvalidTag.new(tag, "Tag is not a hash")
      end
      if !tag.has_key?(name)
        raise InvalidTag.new(tag, "Tag does not key '#{name}'")
      end

      case type
      when :string
        pred = lambda {|field| field.is_a?(String) }
      when :hash
        pred = pred = lambda {|field| field.is_a?(Hash)}
      when :hash_nil
        pred = lambda {|field| field.nil? or field.is_a?(Hash)}
      when :array
        pred = lambda {|field| field.is_a?(Array) }
      end

      if !pred.call(tag[name])
        raise InvalidTag.new(tag, "Tag attribute '#{name}' is not a '#{type.to_s}'")
      end
    end

    def self.resource(access, ref)
      # NOTE(dbp): need to have user at this point.
      # For now, just hardcode.
      user_id = 1
      return access + ":" + ref + ":" + user_id.to_s
    end

  end

  def interp_tag(version, tag, path)
    Helpers.tag_assert(tag, "tag", :string)
    name = tag["tag"]
    pair = [version,name]
    if @versions.has_key?(version) and
       @versions[version].respond_to?(name)
      @versions[version].send(name, tag, path)
    else
      raise InvalidTag.new(tag, "Tag/Version pair not valid: #{name}/#{version}")
    end
  end
  module_function :interp_tag

  class Version1
    # NOTE(dbp): this just used so that we can test nested constructs
    def test(tag, path)
      {"type" => "test",
      "resource" => Helpers.resource(R,path)}
    end

    def description(tag, path)
      Helpers.tag_assert(tag, "body", :string)
      { "type" => "description", "body" => tag["body"],
        "resource" => Helpers.resource(R,path) }
    end

    def instructions(tag, path)
      Helpers.tag_assert(tag, "body", :string)
      { "type" => "description", "body" => tag["body"],
        "resource" => Helpers.resource(R,path) }
    end

    
    def assignment(tag, path)
      Helpers.tag_assert(tag, "name", :string)
      Helpers.tag_assert(tag, "description", :string)
      Helpers.tag_assert(tag, "instructions", :string)
      Helpers.tag_assert(tag, "pieces", :array)

      pieces = tag["pieces"].each_with_index.map {|t,i|
          Commands::interp_tag(1, t, path + "/pieces/" + i.to_s)
      }

      { "type" => "assignment",
        "name" => tag["name"],
        "description" =>  tag["description"],
        "instructions" => tag["instructions"],
        "pieces" => pieces,
        "resource" => Helpers.resource(RW,path)}
    end
    
    def function(tag, path)
      Helpers.tag_assert(tag,"name", :string)
      Helpers.tag_assert(tag,"description", :string)
      Helpers.tag_assert(tag,"instructions", :string)
      Helpers.tag_assert(tag,"header", :hash_nil)
      Helpers.tag_assert(tag,"check_block", :hash_nil)
      Helpers.tag_assert(tag,"definition", :hash_nil)
      
      header = tag["header"].nil? ? nil : 
        Commands::interp_tag(1, tag["header"], path + "/header")
      checkblock = tag["check_block"].nil? ? nil : 
        Commands::interp_tag(1, tag["check_block"], path + "/check_block")
      definition = tag["definition"].nil? ? nil : 
        Commands::interp_tag(1, tag["definition"], path + "/definition")
      
      { "type" => "function",
        "name" => tag["name"],
        "description" => tag["description"],
        "instructions" => tag["instructions"],
        "header" => header,
        "check_block" => checkblock,
        "definition" => definition,
        "resource" => Helpers.resource(RW,path)
        }
    end

    def header_given(tag, path)
      Helpers.tag_assert(tag, "fun_name", :string)
      Helpers.tag_assert(tag, "instructions", :string)
      # NOTE(dbp): only checking one level deep in arguments for now
      Helpers.tag_assert(tag, "arguments", :array)
      Helpers.tag_assert(tag, "return", :string)
      Helpers.tag_assert(tag, "purpose", :string)
      
      { "type" => "header",
        "editable" => false,
        "fun_name" => tag["fun_name"],
        "instructions" => tag["instructions"],
        # NOTE(dbp): not checking arguments, just passing through.
        "arguments" => tag["arguments"],
        "return" =>  tag["return"],
        "purpose" => tag["purpose"],
        "resource" => Helpers.resource(R,path) }
    end

    def check_block(tag, path)
      tag
    end

    def definition(tag, path)
      tag
    end
  end

  # commands is a mapping from [VERSION, "TAGNAME"] to a function
  # that interprets the content of the specified tag.
  @versions = {1 => Version1.new()}

end
