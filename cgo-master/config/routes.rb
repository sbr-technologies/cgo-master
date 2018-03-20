Cgray::Application.routes.draw do
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

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'

  resources :sitemap do 
    collection do 
      get :basic
      get :jobfairs
      get :jobs
      get :employers
      get :static
    end
  end

  resources :users, :controller => "user"
  
  resources :sessions, :controller => 'session' do
    collection do
      get :password_reminder 
    end
  end


  resources :authentications, :controller => 'authentication' do
    collection do
      post :link
    end
  end

  resources :applicants, :controller=> 'applicant' do 

    collection do
      get  :deactivate
      post :process_deactivation 
    end

    member do 
      post :apply 
      post :enable_social_login
      get  :photo
    end
  end

  resources :connections do
    member do
      get :photo
    end
  end

  resources :employers, :controller => 'employer' do

    collection do
      get :job_fairs 
      get :services
    end

    member  do  
      get :public_profile 
    end

    resources :recruiters, :controller => 'recruiter' do 
      member do
        get :current_status 
        get :dashboard 
      end
    end

    resources :ofccp do 
      collection do
        post :download_to_excel
        post :download 
      end
    end

  end

  resources :jobs do 
    
    collection do 
      get :search 
      get :quick_search 
      post :auto_complete_for_employer_name 
    end

	member do 
      get :repost 
      get :apply 
      get :apply_notify
      get :add_to_inbox
      get :remove_from_inbox 
      get :public_profile 
    end

  end

  resources :resumes do 

    collection do 
      get :search
      get :quick_search 
      get :guest_search
      get :guest_index
    end

	member do 
      get :add_to_inbox 
      get :remove_from_inbox 
      get :print 
     post :forward 
      get :download 
      get :attachment 
    end
  end

  resources :positions do
    member do
      post :validate
    end
  end

  resources :educations do
    member do
      post :validate
    end
  end

  resources :jobfairs, :controller => "jobfair" do 
    member do 
      get :registered_employers 
    end

	   resources :registrations
  end

  resources :messages

  resources :registrations do
    collection do 
      get  :new_from_affiliate 
      post :post_from_affiliate 
    end
  end

  
  # ------------------   ADMIN ROUTES --------------------------------------------------
  namespace :admin do 

    resources :jobfairs

	   resources :registrations do
      member do 
        get :enable_search 
      end
    end

    resources :employers do
      member do 
        post :administrator_name 
      end

      resources :recruiters do 
        collection do 
          get :download_to_excel 
        end
      end

      resources :jobs
    end

    resources :recruiters do 
      collection do 
        post :auto_complete_for_employer_name 
        post :update_employer 
        get  :edit_employer
      end
    end

    resources :applicants do 
      collection do 
        post :upload
        post :download_to_excel 
      end

    end

    resources :resumes do 
      collection do
        get :search 
      end

      member do 
        get :download 
        get :attachment 
       post :forward
      end

    end

    resources :users do 
      member do
        get :skip_email_verification 
      end
    end

	   resources :ofccp do
      collection do 
        post :download_to_excel 
      end
    end

  end 
  
  # -----------------------------------------------------------------------------------
  
  root :to => 'welcome#index'
  match 'welcome' => 'welcome#index', :as => 'welcome' 


  match 'admin' => "admin/welcome#index", :as => "admin"
  match 'request_authsub_authorization' => "admin/welcome#request_authsub_authorization", :as => "admin"

  match '/auth/:provider/callback' => 'authentication#create'
  match '/auth/failure' => 'authentication#failure'

  match 'login' => 'session#new', :as => 'login'
  match 'logout' => 'session#destroy', :as => 'logout'
  match 'activate/:activation_code' => 'session#activate', :as => 'activate'


  # Static content (wrapped in site's layout)
  match 'enewsletter' => 'static#enewsletter'
  match 'blog' => 'static#blog'
  match 'GeneralDynamics' => 'static#general_dynamics'
  match 'UnisysDescriptions' => 'static#unisys_descriptions'
  match 'BNSF-hot-job' => 'static#bnsf_hot_job'

  match 'static/download_docx/*path' => 'static#download_docx'
  match 'static/employer/*path' => 'static#index'
  match 'static/*path' => 'static#index'
  
  # Install the default routes as the lowest priority.
  match ':controller/:action.:format'
  match ':controller/:action/:id'
  match ':controller/:action/:id.:format'
end
