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
    puts EDITOR_DIR
    user_repo = UserRepo.create!(path: EDITOR_DIR)
    path = PathRef.create!(user_repo: user_repo, path: @editor.uid)
    path.create_file("", "initial commit for editor",EDITOR_USER)
    @editor.path_ref = path
    @editor.save!
    redirect_to editor_path(@editor.uid)
  end

  def update
    puts params
    @editor = Editor.find_by(uid: params[:format])
    @editor.title = params[:title]
    @editor.path_ref.save_file(params[:code], "updating editor",
                               EDITOR_USER)
    @editor.save!
    redirect_to editor_path(@editor.uid)
  end
  
end
