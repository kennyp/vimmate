=begin
= VimMate: Vim graphical add-on
Copyright (c) 2006 Guillaume Benny

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
=end

require 'gtk2'
require 'vimmatelib/config'
require 'vim/integration'

module VimMate

  # A window that can display and send information to the
  # GTK GUI of Vim (gVim)
  class VimWindow

    include VimIntegration

    # Create the VimWindow. You must call start after this window is visible
    def initialize
      # A unique Vim server name
      @vim_server_name = "VimMate_#{Process.pid}"
      @gtk_socket = Gtk::Socket.new
      @gtk_socket.show_all
      @gtk_socket.signal_connect("delete_event") do
        false
      end
      @gtk_socket.signal_connect("destroy") do
        Gtk.main_quit
      end
      @gtk_socket.can_focus = true
      @gtk_socket.has_focus = true
      @vim_started = false
      @extras_sourced = false
    end

    # The "window" for this object
    def gtk_window
      @gtk_socket
    end

    #generate multiline functions that will be sourced on startup
    def source_vimmate_extras
      return if @extras_sourced
      if @vim_started
        source_path = File.join( File.dirname(__FILE__), '..', 'vim', 'source.vim')
        remote_send "<ESC><ESC><ESC>:source #{source_path}<CR>"
        @extras_sourced = true
      end
    end

    # Open the specified file in Vim
    def open(path, kind = :open)
      start
      path = path.gsub "'", "\\'"
      case kind
      when :open, :split_open
        if kind == :split_open
          remote_send '<ESC><ESC><ESC>:split<CR>'
        end
          exec_gvim "--remote '#{path}'"
      when :tab_open
          exec_gvim "--remote-tab '#{path}'"
      else
        raise "Unknow open kind: #{kind}"
      end
      remote_send "<ESC><ESC><ESC>:buffer #{path}<CR>"
      focus_vim
      self
    end

    def open_and_jump_to_line(path,lnum)
      unless buffer = buffers.index(path)
        open path, Config[:files_default_open_in_tabs] ? :tab_open : :open
        sleep 0.5
      end
      send_command buffer, 'setDot', [lnum,0]
      focus_vim
      self
    end
    
    def jump_to_line(line)
      start
      if line >= 0
        # TODO use neatbeans
        remote_send "<ESC><ESC><ESC>:#{line}<CR>"
      end
    end

    # Start Vim's window. This must be called after the window which
    # will contain Vim is visible.
    def start
      return if @vim_started
      @vim_started = true
      listen
      fork do
        exec_gvim "--socketid #{@gtk_socket.id} -nb:localhost:#{port}:#{Password}"
      end
      sleep 0.5
      source_vimmate_extras
      self
    end

    # Set the focus to Vim
    def focus_vim
      @gtk_socket.can_focus = true
      @gtk_socket.has_focus = true
    end

    def get_current_buffer_path
      if @vim_started
        #`gvim --servername #{@vim_server_name} --remote-send ':redir! > outputfile<cr>'`
        #`gvim --servername #{@vim_server_name} --remote-send ':echo getcwd()<cr>'`
        #`gvim --servername #{@vim_server_name} --remote-send ':echo bufname(bufnr(""))<cr>'`
        #`gvim --servername #{@vim_server_name} --remote-send ':redir END<cr>'`

        get_current_buffer_number

        cwd = exec_gvim "--remote-expr 'getcwd()'".chomp+'/'
        if cwd
          return cwd + exec_gvim(%Q~--remote-expr 'bufname(bufnr(""))'~)
        end
      end
    end

    def get_current_buffer_number
      send_function('getCursor')
    end

    def get_all_buffer_paths
      buffers[1..-1]
    end

  end
end

