class UserRepo < ActiveRecord::Base

  class UserRepoException < Exception
    attr :path
    def initialize(path)
      super
      @path = path
    end
  end

  class NoSuchDirectory < UserRepoException
  end

  class DirectoryExists < UserRepoException
  end

  class NotAGitRepo < UserRepoException
  end

  class BadGitRepo < UserRepoException
  end

  class PathExists < UserRepoException
  end


  has_many :git_ref
  attr_accessor :path, :repo
  after_initialize :init

  def init()
    begin
      unless Dir.exists?(@path)
        raise NoSuchDirectory.new(@path)
      end
      @repo = UserRepo._get_repo(@path)
      if @repo.empty?
        raise BadGitRepo.new(@path)
      end
    rescue Rugged::RepositoryError => e
      raise NotAGitRepo.new(@path)
    end
  end

  def self.init_repo(where)
    if Dir.exists?(where)
      raise DirectoryExists.new(where)
    end
    begin
      Dir.mkdir(where)
      repo = UserRepo._create_repo(where)
      UserRepo.new(:path => where)
    rescue SystemCallError => e
      raise NoSuchDirectory.new(where)
    rescue Rugged::RepositoryError => e
      raise NotAGitRepo.new(where)
    end
  end

  # Path is relative to repository for create_ and lookup_
  def create_file(path, contents, message, user)
    @repo = Rugged::Repository.new(@path)

    existing_blob = @repo.empty? ? nil : @repo.blob_at(@repo.head.target, path)
    unless existing_blob.nil?
      raise PathExists.new(path)
    end

    oid = @repo.write(contents, :blob)
    index = @repo.index()
    tree = @repo.lookup(@repo.head.target).tree
    index.read_tree(tree)
    index.add(:path => path, :oid => oid, :mode => 0100644)

    options = {}
    options[:tree] = index.write_tree(@repo)
    options[:message] = message
    options[:author] = { :email => user[:email],
                         :name => user[:name],
                         :time => Time.now }
    options[:committer] = { :email => "",
                            :name => "Blackbeard",
                            :time => Time.now }
    options[:parents] = @repo.empty? ? [] : [@repo.head.target].compact
    options[:update_ref] = "HEAD"

    Rugged::Commit.create(@repo, options)
  end

  def lookup_file(path)
  end

  def self._create_repo(where)
    @repo = Rugged::Repository.init_at(where, :bare)
    oid = @repo.write("Master anchor", :blob)
    index = Rugged::Index.new
    index.add(:path => ".captain-init", :oid => oid, :mode => 0100644)

    options = {}
    options[:tree] = index.write_tree(@repo)
    options[:message] = "Initial captain-teach commit"
    options[:author] = { :email => "",
                         :name => "Blackbeard",
                         :time => Time.now }
    options[:committer] = { :email => "",
                            :name => "Blackbeard",
                            :time => Time.now }
    options[:parents] = []
    options[:update_ref] = "HEAD"

    Rugged::Commit.create(@repo, options)
    @repo
  end

  def self._get_repo(where)
    Rugged::Repository.new(where)
  end

end
