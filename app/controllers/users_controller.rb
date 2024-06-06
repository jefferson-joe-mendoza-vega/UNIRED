# app/controllers/users_controller.rb
class UsersController < ApplicationController
  skip_before_action :protect_pages, only: :show

  def index
    if params[:query].present? && params[:query].start_with?('@')
      username = params[:query][1..-1]
      @usuarios = User.includes(:faculty).where("username ILIKE ?", "%#{username}%")
    elsif params[:query].present? && params[:query].start_with?('!')
      faculty_name = params[:query][1..-1]
      @usuarios = User.includes(:faculty).joins(:faculty).where("faculties.name ILIKE ?", "%#{faculty_name}%").order("promotion DESC")
    elsif params[:query].present? && params[:query].start_with?('#')
      promotion_ano = params[:query][1..-1]
      @usuarios = User.where("promotion ILIKE ?", "%#{promotion_ano}%")
    else
      @usuarios = User.includes(:faculty).all.order(created_at: :desc)
    end

    @usuarios = @usuarios.paginate(page: params[:page], per_page: 15)
  end
    

    

def show
  if params[:username].present?
    @user = User.find_by(username: params[:username])

    if @user.nil?
      redirect_to root_path, alert: 'Usuario no encontrado'
    else
      @publicaciones = @user.publicacions.order(created_at: :desc)
    end
  end
end

def destroy
  @user = User.find_by(id: params[:username])

  if @user.destroy
    redirect_to root_path, notice: 'Usuario eliminado correctamente.'
  else
    redirect_to root_path, notice: 'Usuario no se elimino.'
  end
  
end

def buscar
  query = params[:query].strip

  if query.present? && query.length >= 3
    if query.start_with?('@')
      username = query[1..-1]
      @usuarios = User.includes(:faculty).where("username ILIKE ?", "%#{username}%").limit(10)
    elsif query.start_with?('!')
      faculty_name = query[1..-1]
      @usuarios = User.includes(:faculty).joins(:faculty).where("faculties.name ILIKE ?", "%#{faculty_name}%").order("promotion DESC").limit(10)
    elsif query.start_with?('#')
      promotion_ano = query[1..-1]
      @usuarios = User.where("promotion ILIKE ?", "%#{promotion_ano}%").limit(10)
    else
      @usuarios = User.includes(:faculty).where("username ILIKE ?", "%#{query}%").limit(10)
    end

    respond_to do |format|
      format.json { render json: @usuarios.map { |u| { username: u.username, faculty: u.faculty&.name } } }
    end
  else
    respond_to do |format|
      format.json { render json: [] }
    end
  end
end
def make_leader
  if Current.user && Current.user.admin?
    user = User.find_by(username: params[:username])
    if user
      user.toggle!(:lider)  # Cambiar el estado de liderazgo del usuario
      if user.lider?
        flash[:success] = "El usuario #{user.username} ahora es un líder."
      else
        flash[:success] = "Se ha quitado el liderazgo al usuario #{user.username}."
      end
    else
      flash[:error] = "No se encontró el usuario."
    end
  else
    flash[:error] = "No tienes permisos para realizar esta acción."
  end
  redirect_to usuario_path(params[:username])
end

end




