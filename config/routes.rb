ActionController::Routing::Routes.draw do |map|
  map.resource :session
  map.resources :users
  map.resources :groups
  map.resources :courses
  map.resources :course_instances, :except => [:index]
  map.resources :exercises, :member => ['results','statistics','batch_assign']
  map.resources :rubrics
  map.resources :submissions
  map.resources :reviews
  map.resources :feedbacks

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "frontpage"

  # See how all your routes lay out with "rake routes"

  map.connect 'exercise/new/:instance', :controller => 'exercises', :action => 'new'

  map.login '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.submit '/submit/:exercise', :controller => 'submissions', :action => 'new'

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  #map.connect ':controller/:action/:id.:format'
end
