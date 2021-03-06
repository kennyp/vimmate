require 'listed_item'
module VimMate
  class ListedFile < ListedItem
    column :full_path, String
    column :icon, Gdk::Pixbuf
    column :status, String
    def initialize(opts = {})
      super
      if fp = opts[:full_path]
        self.full_path = fp
        self.icon = Icons.by_name icon_name
        self.status = "normal" if Config[:files_show_status]
      end
    end
    def icon_name
      'file'
    end
    def refresh
      Gtk.queue do
        self.icon = Icons.by_name icon_name
        self.status = "normal" if Config[:files_show_status]
      end
    end
    def full_path=(new_full_path)
      unless new_full_path.empty?
        self.name = File.basename new_full_path
        self.iter[FULL_PATH] = new_full_path
        self.sort = sort_string
      end
    end
    def sort_string
      "2-#{name}-1"
    end
    def file?
      referenced_type == 'ListedFile' && full_path && ::File.file?(full_path)
    end
    def directory?
      referenced_type == 'ListedDirectory' && full_path && ::File.directory?(full_path)
    end
    def exists?
      File.file? full_path
    end
    def file_or_directory?
      file? || directory?
    end

    def after_show!
      i = iter
      while i = i.parent
        i[VISIBLE] = true
      end
    end

    def self.setup_view_column(column)
      column.title = "Files"

      # Icon
      icon_cell_renderer = Gtk::CellRendererPixbuf.new
      column.pack_start(icon_cell_renderer, false)
      column.set_attributes(icon_cell_renderer, :pixbuf => ICON)

      # File name
      text_cell_renderer = Gtk::CellRendererText.new
      if Config[:files_use_ellipsis]
        text_cell_renderer.ellipsize = Pango::Layout::EllipsizeMode::MIDDLE
      end
      column.pack_start(text_cell_renderer, true)
      column.set_attributes(text_cell_renderer, :text => NAME)
      
      # Status
      if Config[:files_show_status]
        text_cell_renderer2 = Gtk::CellRendererText.new
        if Config[:files_use_ellipsis]
          text_cell_renderer2.ellipsize = Pango::Layout::EllipsizeMode::END
        end
        column.pack_start(text_cell_renderer2, true)
        column.set_attributes(text_cell_renderer2, :text => STATUS)
      end
      column
    end
  end
end

require 'listed_directory'
