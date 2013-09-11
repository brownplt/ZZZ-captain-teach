App::Application.routes.draw do
  root 'static#index'

  # NOTE(dbp 2013-09-11): So noscripters see a useful message.
  get 'login' => 'static#login'
  # NOTE(dbp 2013-09-11): Not a bug - login and logout page is the same.
  get 'logout' => 'static#login'

  post 'login' => 'sessions#create'
  post 'logout' => 'sessions#destroy'

  post 'review/save/:rid'   => 'review#save'
  get  'review/lookup/:rid' => 'review#lookup'

  get  'resource/lookup'        => 'resource#lookup'
  post 'resource/lookup_create' => 'resource#lookup_create'
  post 'resource/save'          => 'resource#save'
  get  'resource/versions'      => 'resource#versions'
  post 'resource/submit'        => 'resource#submit'

  post 'notification/report_abuse' => 'notification#report_abuse'

  get 'assignment/:uid' => 'assignment#get_assignment', as: :assignment
  get 'grade/:uid/:user_id' => 'assignment#grade_assignment', as: :grade_assignment
  get 'assignment/:uid/edit' => 'assignment#edit_assignment', as: :edit_assignment
  post 'assignment/:uid/edit' => 'assignment#update_assignment', as: :update_assignment

  resource :editor
  get 'editors' => 'editors#index', as: :editors
  post 'editor/:uid/switch' => 'editors#switch_version', as: :editor_switch

  resources :submitted
  get 'submitted/:id/set_good' => 'submitted#good', :as => :submitted_good
  get 'submitted/:id/set_bad' => 'submitted#bad', :as => :submitted_bad
  get 'submitted/:id/set_unknown' => 'submitted#unknown', :as => :submitted_unknown

  resources :user
  post 'user/set_send_email' => 'user#set_send_email', :as => :set_send_email
  get 'user/:id/make_staff' => 'user#make_staff', :as => :make_staff
  get 'user/:id/unmake_staff' => 'user#unmake_staff', :as => :unmake_staff

  resources :course
  post 'course/:id/add_teacher' => 'course#add_teacher', as: :add_teacher
  post 'course/:id/add_student' => 'course#add_student', as: :add_student
  get 'course/:id/show_abuses' => 'course#show_abuses'


  # These all have various security or other concerns for running
  # in production, but are very handy when developing
  if Rails.env.development? or Rails.env.test?
    mount JasmineRails::Engine => "/specs" if defined?(JasmineRails)

    get 'assignments' => 'test#all_assignments'

    get 'begin_masquerade' => 'test#masquerade'
    get 'end_masquerade' => 'test#end_masquerade'

    post 'become_user/:uid' => "awesome#become_user"
    get 'all_users' => "awesome#all_users"
    get 'all_assignments' => "test#all_assignments"
    get 'fetch_assignments' => "test#fetch_assignments"
    get 'test_assignment' => "test#test_assignment"
    get 'editor_tests' => "test#editor_tests"
    get 'server_tests' => "test#server_tests"
    get 'submit_tests' => "test#submit_tests"
    get 'canned_feedback_test' => "test#canned_feedback_test"
    get 'open_response' => "test#open_response"
    get ':action' => 'static#:action'
  end
end
