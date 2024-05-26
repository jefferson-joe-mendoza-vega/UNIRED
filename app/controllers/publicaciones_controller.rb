class PublicacionesController < ApplicationController
  require 'open3'
  skip_before_action :protect_pages, only: [:index, :show]
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

  private
  def resize_and_compress_image
    begin
      image = @publicacion.imagen.variant(resize_to_limit: [800, 800], quality: '50%').processed
      @publicacion.imagen.attach(image)
    rescue ActiveStorage::FileNotFoundError => e
      Rails.logger.error "Error procesando la imagen: #{e.message}"
    end

  end
  def compress_and_attach_video
    # Path del video original
    original_video_path = ActiveStorage::Blob.service.path_for(@publicacion.video.key)
  
    # Path donde se guardará el video comprimido
    compressed_video_path = "#{Rails.root}/tmp/compressed_video.mp4"
  
    # Comando FFmpeg para comprimir el video
    ffmpeg_command = "ffmpeg -i #{original_video_path} -vf scale=640:-2 -c:v libx264 -preset medium -crf 28 -c:a aac -b:a 128k -movflags +faststart #{compressed_video_path}"
  
    begin
      # Ejecutar el comando FFmpeg para comprimir el video
      stdout, stderr, status = Open3.capture3(ffmpeg_command)
  
      if status.success?
        # Adjuntar el video comprimido a la publicación
        @publicacion.video.attach(io: File.open(compressed_video_path), filename: 'compressed_video.mp4')
  
        # Eliminar el archivo temporal del video comprimido
        File.delete(compressed_video_path) if File.exist?(compressed_video_path)
      else
        # Manejar errores si FFmpeg no pudo comprimir el video
        Rails.logger.error "Error al comprimir el video: #{stderr}"
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
