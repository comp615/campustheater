Ydc::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
  
  # Shouldn't have index...
  resources :people 
  match 'people/:id/request_names' => 'people#takeover_request', :as => :takeover_request, :method => :post

  #match ':show_name/reserve' => 'reservations#show_reservation', :as => :show_reservation
  #match ':show_name/reserve/:id' => 'reservations#new', :as => :showtime_reservation
  match 'dashboard' => 'people#dashboard', :as => :dashboard
  match 'login' => 'people#dashboard', :as => :login
  match 'logout' => 'people#logout', :as => :logout
  
  match 'archives(/:term)' => 'shows#archives', :as => :archives
  
  
  resources :shows do
		resources :showtimes, :only => [:show, :index] #Used as reservation viewer for admin
		resources :auditions
		resources :reservations
		member do
	    put 'auditions', :controller => :auditions, :action => :update
	  end
	end
	
	match 'auditions' => 'auditions#all'
	match 'opportunities' => 'auditions#opportunities'
	
	
	match 'search' => 'search#index', :as => :search
	match 'search/lookup' => 'search#lookup', :as => :search_lookup
	
  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'pages#index'
  
  # Hijack guide links and wrap them in a special template
  match 'resources' => 'pages#resources'
  match 'guides/:static_file' => 'pages#guides', :as => :guides
  
  # Detect show slugs last, some legacy support for now
  # TODO: build out /tickets, /reserve, etc.
  match ':url_key' => 'shows#show', :as => "vanity"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
  
  # TODO: Add legacy routes here
end
