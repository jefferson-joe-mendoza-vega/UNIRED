class ResponsesController < ApplicationController
    before_action :set_comment
    
    def create
      @response = Response.new(response_params)
      

      if @response.save
        @notificacion = Notification.new(
          user_id: @response.comment.user_id,
          publicacion_id: @response.comment.publicacion_id,
          message: "#{Current.user.username} respondió a tu comentario: '#{@comment.content}'"
        ) 
        
        if @notificacion.save
        
          redirect_to @comment, notice: 'Respuesta creada correctamente.'
        end
      else
        redirect_to @comment, alert: 'Hubo un error al crear la respuesta.'
      end
    end
  
    private
  
    def set_comment
      @comment = Comment.find(params[:comment_id])
    end
  
    def response_params
      params.require(:response).permit(:content, :user_id, :comment_id)
    end
end
  