require 'sinatra'

class DemoApp < Sinatra::Base

    enable :sessions

    get '/' do
        @user_name = session[:value]
        erb :hello
    end

    get '/set/:value' do
      session[:value] = params[:value]
      redirect '/'
    end

    get '/hello/:name' do
        @user_name = params[:name]
        erb :hello
    end
end
