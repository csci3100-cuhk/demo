Rails.application.routes.draw do
  root :to => redirect("/students")
  resources :students
end
