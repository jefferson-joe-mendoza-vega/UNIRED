class Authentication::SessionsController < ApplicationController
    skip_before_action :protect_pages
    
    def new
    end

    def create
        @user = User.find_by("emails = :login OR username = :login", { login: params[:login] })
        
        if @user&.authenticate(params[:password])
            session[:user_id] = @user.id
            # Establecemos que la cookie de sesión expire en 30 días (opcional, ya que está configurado globalmente en session_store)
            session.options[:expire_after] = 1.year
            redirect_to publicaciones_path, notice: 'Bienvenido'
        else
            redirect_to new_session_path, alert: 'Login inválidos'
        end
    end

    def destroy
        session.delete(:user_id)
        redirect_to root_path, notice: 'Sesión cerrada exitosamente.'
    end
end
