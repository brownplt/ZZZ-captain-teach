class EditorsController < ApplicationController

  EDITOR_DIR = File.expand_path("../../../../editors", __FILE__)
  EDITOR_USER = {name: "Edward Teach", email: ""}
  
  def index
    @editors = Editor.all
  end

  def show
    @editor = Editor.find_by(uid: params[:format])
  end
  
  def create
    # create first, so we can use the uid
    @editor = Editor.create!
    user_repo = UserRepo.create!(path: EDITOR_DIR)
    path = PathRef.create!(user_repo: user_repo, path: @editor.uid)
    path.create_file("", "editor #{@editor.uid}",EDITOR_USER)
    @editor.path_ref = path
    @editor.save!
    redirect_to editor_path(@editor.uid)
  end

  def update
    @editor = Editor.find_by(uid: params[:format])
    @editor.title = params[:title]
    @editor.path_ref.save_file(params[:code],
                               "editor #{@editor.uid}",
                               EDITOR_USER)
    # put us back on HEAD
    @editor.git_ref = nil
    @editor.save!
    redirect_to editor_path(@editor.uid)
  end

  def switch_version
    @editor = Editor.find_by(uid: params[:uid])
    # TODO(dbp): verify the hash is valid (this should be a
    # verification in GitRef).
    ref = GitRef.create!(user_repo: @editor.path_ref.user_repo,
                         path: @editor.path_ref.path,
                         git_oid: params[:hash])
    @editor.git_ref = ref
    @editor.save!
    redirect_to editor_path(@editor.uid)
  end
    
  
end
