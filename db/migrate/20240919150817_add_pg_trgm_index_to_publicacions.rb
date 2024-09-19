class AddPgTrgmIndexToPublicacions < ActiveRecord::Migration[6.1]
  def change
    # Asegúrate de habilitar la extensión pg_trgm si aún no lo has hecho
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')

    # Agregar índices trigram en las columnas de titulo y descripcion en la tabla publicacions
    add_index :publicacions, :titulo, using: :gin, opclass: :gin_trgm_ops
    add_index :publicacions, :descripcion, using: :gin, opclass: :gin_trgm_ops
  end
end
