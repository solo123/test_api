Rails.application.routes.draw do
  match '(*foo)', via: [:get, :post], to: 'http_funs#index'
end
