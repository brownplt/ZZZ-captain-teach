App::Application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'
  # for now, editors is the most useful thing we have
  root 'editors#index'

  post 'login' => 'sessions#create'
  post 'logout' => 'sessions#destroy'

  get 'all_assignments' => "test#all_assignments"
  get 'fetch_assignments' => "test#fetch_assignments"
  get 'test_assignment' => "test#test_assignment"
  

  # get  'blob/lookup'        => 'blob#lookup'
  # post 'blob/lookup_create' => 'blob#lookup_create'
  # post 'blob/save'          => 'blob#save'

  get  'resource/lookup'        => 'resource#lookup'
  post 'resource/lookup_create' => 'resource#lookup_create'
  post 'resource/save'          => 'resource#save'
  get  'resource/versions'      => 'resource#versions'
  
  #get 'do_assignment/:uid' => 'assignment#do_assignment'
  get 'assignment/:uid' => 'assignment#get_assignment', as: :assignment
  get 'grade/:uid/:user_id' => 'assignment#grade_assignment', as: :grade_assignment

  get 'editors' => 'editors#index', as: :editors
  post 'editor/:uid/switch' => 'editors#switch_version', as: :editor_switch
  resource :editor

  get 'begin_masquerade' => 'test#masquerade'
  get 'end_masquerade' => 'test#end_masquerade'

  resources :course

  post 'course/:id/add_teacher' => 'course#add_teacher', as: :add_teacher
  post 'course/:id/add_student' => 'course#add_student', as: :add_student
  
  
  # TESTING
  mount JasmineRails::Engine => "/specs" if defined?(JasmineRails) 
  
  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'
  
  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # routing static pages, for testing currently
  if Rails.env.development?
    get ':action' => 'static#:action'
  end
end
