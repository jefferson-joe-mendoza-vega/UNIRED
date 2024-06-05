class PublicacionesController < ApplicationController
  require 'open3'
  require 'mini_magick' # Asegúrate de tener la gema MiniMagick instalada
  skip_before_action :protect_pages, only: [:index, :show, :buscar]
  before_action :load_publicaciones, only: [:index]
  before_action :load_publicacion, only: [:show, :edit, :update, :destroy]
  before_action :load_comments, only: [:show]
  before_action :load_reactions_counts, only: [:show]

  def index
    @facultades=Faculty.all.order(:name)
    @categories = Category.order(:name)
    load_faculty_publicaciones if params[:category_id].present? || params[:faculty_id].present?
    search_publicaciones if params[:query].present?
    @publicaciones = @publicaciones.paginate(page: params[:page], per_page: 8)
    
    @publicaciones_fijadas_index = Publicacion.where(fijadaindex: true) unless params[:faculty_id].present?

    
    if params[:faculty_id].present?
      @publicaciones_fijadas_facultad = Publicacion.where(fijada: true)
      faculty_id = params[:faculty_id]
      @publicaciones_fijadas_facultad = @publicaciones_fijadas_facultad.joins(:user).where(users: { faculty_id: faculty_id })
    end
  end

  def show
  end

  def new
    @publicacion = Publicacion.new
  end

  def create
    @publicacion = Publicacion.new(publicacion_params)
    resize_and_compress_image if @publicacion.imagen.attached?
    compress_and_attach_video  if @publicacion.video.attached?

    if @publicacion.save
      redirect_to publicaciones_path, notice: 'Se subió tu publicación.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    autorizar! @publicacion
  end

  def tendencias
    load_trending_publicaciones
  end

  def update
    autorizar! @publicacion
    if @publicacion.update(publicacion_params)
      redirect_to publicaciones_path, notice: 'Tu publicación se ha actualizado correctamente.'
    else 
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    autorizar! @publicacion
    @publicacion.destroy
    redirect_to publicaciones_path, notice: 'La publicación se ha eliminado correctamente.', status: :see_other
  end
  # app/controllers/publicaciones_controller.rb

  def total
    @total_publicaciones = Publicacion.count
    render json: { total_publicaciones: @total_publicaciones }
  end

  def buscar
    query = params[:query].strip

    if query.present? && query.length >= 3
      @publicaciones = Publicacion.where("titulo ILIKE ? OR descripcion ILIKE ?", "%#{query}%", "%#{query}%").limit(10)
    else
      @publicaciones = []
    end

    respond_to do |format|
      format.json { render json: @publicaciones }
    end
  end


  private
  def resize_and_compress_image
    return unless @publicacion.imagen.attached?

    begin
      original_image_path = @publicacion.imagen.blob.service.send(:path_for, @publicacion.imagen.key)
      
      image = MiniMagick::Image.open(original_image_path)
      if image.width > 800 || image.height > 800
        image.resize "800x800"
        image.quality "85"
        
        compressed_image_path = "#{Rails.root}/tmp/compressed_image.jpg"
        image.write(compressed_image_path)

        File.open(compressed_image_path) do |file|
          @publicacion.imagen.attach(io: file, filename: 'compressed_image.jpg')
        end

        File.delete(compressed_image_path) if File.exist?(compressed_image_path)
      end
    rescue => e
      Rails.logger.error "Error procesando la imagen: #{e.message}"
    end
  end

  def compress_and_attach_video
    return unless @publicacion.video.attached?

    begin
      original_video_path = @publicacion.video.blob.service.send(:path_for, @publicacion.video.key)
      video_info_command = "ffprobe -v error -show_entries stream=width,height -of csv=p=0:s=x #{original_video_path}"
      
      stdout, stderr, status = Open3.capture3(video_info_command)
      
      if status.success?
        width, height = stdout.strip.split('x').map(&:to_i)
        
        if height > 480
          compressed_video_path = "#{Rails.root}/tmp/compressed_video.mp4"
          ffmpeg_command = "ffmpeg -i #{original_video_path} -vf scale=-2:480 -c:v libx264 -preset medium -crf 28 -c:a aac -b:a 128k -movflags +faststart #{compressed_video_path}"
          
          stdout, stderr, status = Open3.capture3(ffmpeg_command)
          
          if status.success?
            File.open(compressed_video_path) do |file|
              @publicacion.video.attach(io: file, filename: 'compressed_video.mp4')
            end
            
            File.delete(compressed_video_path) if File.exist?(compressed_video_path)
          else
            Rails.logger.error "Error al comprimir el video: #{stderr}"
          end
        end
      else
        Rails.logger.error "Error al obtener información del video: #{stderr}"
      end
    rescue => e
      Rails.logger.error "Error procesando el video: #{e.message}"
    end
  end

  def load_publicaciones
    @publicaciones = Publicacion.all.with_attached_imagen.order(created_at: :desc)
  end

  def load_faculty_publicaciones
    @publicaciones = @publicaciones.where(category_id: params[:category_id]) if params[:category_id].present?
    @publicaciones = @publicaciones.joins(:user).where(users: { faculty_id: params[:faculty_id] }) if params[:faculty_id].present?
  end

  def search_publicaciones
    @publicaciones = @publicaciones.search(params[:query])
  end

  def load_publicacion
    @publicacion = Publicacion.find(params[:id])
  end

  def load_comments
    @comments = @publicacion.comments.order(created_at: :desc)
    @respuestas = Response.all
  end

  def load_reactions_counts
    reactions = @publicacion.reactions.group(:reaction_type).count
    @me_divierte_count = reactions['me_divierte'].to_i
    @me_gusta_count = reactions['me_gusta'].to_i
    @me_encanta_count = reactions['me_encanta'].to_i
    @me_asombra_count = reactions['me_asombra'].to_i
    @me_entristese_count = reactions['me_entristese'].to_i
    @me_enoja_count = reactions['me_enoja'].to_i
  end

  def load_trending_publicaciones
    fecha_lunes = Date.today.beginning_of_week(:monday)
    fecha_domingo = Date.today.end_of_week(:sunday)
    @publicaciones = Publicacion.left_joins(:comments)
                                .where(created_at: fecha_lunes.beginning_of_day..fecha_domingo.end_of_day)
                                .group(:id)
                                .order('COUNT(comments.id) DESC')
                                .limit(5)
  end

  def publicacion_params
    params.require(:publicacion).permit(:titulo, :descripcion, :imagen, :category_id, :mostrar_nombre, :fijada, :fijadaindex, :video)
  end
end
