###############################################################################
# Project::     Bored Game
# Application:: HotspotEditor
# Classes::     HotspotEditor
#
# Author::      Bil Bas
# Modified::    $Date: 2004/07/23 15:25:22 $
#
###############################################################################
require 'fox16'
include Fox

require 'rexml/document'

$:.push '../lib' # Add library to search path.

require 'generatedialog'
require 'settings'
require 'drawarea'
require 'panels'
require 'aboutdialog'

require 'menu'
include Menu

PROGRAM = 'Hotspot Editor'
AUTHOR  = 'Bil Bas'

###############################################################################
#
class HotspotEditor < FXMainWindow
  DIALOG_CANCEL = 0
  DIALOG_ACCEPT = 1

  # :stopdoc:
  EXIT_CONFIRMED = 0
  EXIT_CANCELLED = 1

  # Settings will be saved to this file.
  SETTINGS_FILE = "editor.ini"

  SECTION_WIN    = "WINDOW"
  KEY_WIN_WIDTH  = "width"
  KEY_WIN_HEIGHT = "height"
#   KEY_MAXIMIZED  = "maximized"
  KEY_WIN_X      = "x"
  KEY_WIN_Y      = "y"

  SECTION_SHOW      = "SHOW"
  KEY_SHOW_MODE_BAR = "modeBar"
  KEY_SHOW_STATUS   = "statusBar"
  KEY_SHOW_TOOL_BAR = "toolBar"

  SECTION_FILE     = "FILES"
  KEY_FILE_CURRENT = "currentFile"
  DEF_CURRENT_FILE = "./" 
  
  DEF_WIN_X = 0
  DEF_WIN_Y = 0
  DEF_WIN_WIDTH  = 800
  DEF_WIN_HEIGHT = 500

  INFO_FRAME_WIDTH = 150

  TOOLBAR_IMAGE_DIR = "../image/"
  # :startdoc:

  #
  #
  #
  private
  def initialize(app)

#     # Iconified icon (Mac only)
#     @bigIcon = FXPNGIcon.new(app, File.open("#{MAIN_IMAGE_DIR}/icon.png", "rb").read)

#     # Mini icon for top left corner of window.
#     smallIcon = FXPNGIcon.new(app, File.open("#{MAIN_IMAGE_DIR}/mini_icon.png", "rb").read)

#     super(app, PROGRAM, @bigIcon, smallIcon,
#         DECOR_ALL|LAYOUT_MIN_WIDTH|LAYOUT_MIN_HEIGHT, 0, 0, 800, 550)

    @settings = Settings.new SETTINGS_FILE

    super(app, PROGRAM, nil, nil,
        DECOR_ALL,
        @settings.getValue(SECTION_WIN, KEY_WIN_X, DEF_WIN_X),
        @settings.getValue(SECTION_WIN, KEY_WIN_Y, DEF_WIN_Y),
        @settings.getValue(SECTION_WIN, KEY_WIN_WIDTH, DEF_WIN_WIDTH),
        @settings.getValue(SECTION_WIN, KEY_WIN_HEIGHT, DEF_WIN_HEIGHT))

    connect(SEL_CLOSE, method(:confirmExit)) # top right X pressed
    connect(SEL_CONFIGURE) {
      # Record the new size of the main window.
      @settings.setValue SECTION_WIN, KEY_WIN_WIDTH, width
      @settings.setValue SECTION_WIN, KEY_WIN_HEIGHT, height
#       @settings.setValue SECTION_WIN, PLACEMENT_MAXIMIZED, true
    }
    # TODO: This a nastily messy way of tracking this. Must be better way?
    connect(SEL_UPDATE) {
      @settings.setValue SECTION_WIN, KEY_WIN_X, x
      @settings.setValue SECTION_WIN, KEY_WIN_Y, y
    }

    @menuBar = MenuBar.new self, File.open("../lib/menu.yml"), self

#     editPane = @menuBar[:edit].menu
#     @drawArea.clipBoard.setMenus editPane[:cut], editPane[:copy], editPane[:paste]

    if @settings.getValue(SECTION_SHOW, KEY_SHOW_TOOL_BAR, true)
      @menuBar[:view].menu[:barsShown].menu[:toolBarToggle].check = true
    end

    if @settings.getValue(SECTION_SHOW, KEY_SHOW_STATUS, true)
      @menuBar[:view].menu[:barsShown].menu[:statusBarToggle].check = true
    end

    if @settings.getValue(SECTION_SHOW, KEY_SHOW_MODE_BAR, true)
      @menuBar[:view].menu[:barsShown].menu[:modeBarToggle].check = true
    end

    initToolBar

#     FXHorizontalSeparator.new self

    FXToolTip.new app

    # Frames for layout
    fDimensions = [ 0, 0, 0, 0, 5, 5, 5, 5 ]

    @layoutFrame = FXVerticalFrame.new(self, 
                     LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_NONE,
                     0, 0, 0, 0, 0, 0, 0, 0)

    # Status bar at the bottom.
    @statusBar = FXStatusBar.new(@layoutFrame,
                   LAYOUT_FILL_X|LAYOUT_BOTTOM|STATUSBAR_WITH_DRAGCORNER)
    @posPanel = FXTextField.new @statusBar, 10, nil, 0, JUSTIFY_RIGHT|FRAME_NORMAL
    @posPanel.enabled = false
    unless @settings.getValue SECTION_SHOW, KEY_SHOW_STATUS, true
      @statusBar.hide
    end

    @mainFrame = FXHorizontalFrame.new(@layoutFrame,
        LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_LEFT|FRAME_NONE,
        0, 0, 0, 0, 0, 0, 0, 0)

    initModeBar @mainFrame

    infoFrame = FXVerticalFrame.new(@mainFrame,
        LAYOUT_FIX_WIDTH|LAYOUT_FILL_Y|LAYOUT_RIGHT|LAYOUT_TOP|FRAME_NONE,
        0, 0, INFO_FRAME_WIDTH, 0, 0, 0, 0, 0)

    # Undo list controls undo and redo of actions.
    @undoList = FXUndoList.new
    @undoList.mark
    @menuBar[:edit].menu[:undo].target     = @undoList
    @menuBar[:edit].menu[:undo].selector   = FXUndoList::ID_UNDO
    @menuBar[:edit].menu[:redo].target     = @undoList
    @menuBar[:edit].menu[:redo].selector   = FXUndoList::ID_REDO
    @menuBar[:edit].menu[:revert].target   = @undoList
    @menuBar[:edit].menu[:revert].selector = FXUndoList::ID_REVERT

    @drawArea = DrawArea.new @mainFrame, infoFrame, @undoList, @posPanel
  end # initialize()

  #
  # Allow user to cancel, save or quit if they try to exit with unsaved data.
  #
  public
  def confirmExit(sender, sel, event)

    if !@undoList.marked?
      result = FXMessageBox.question(self, MBOX_QUIT_SAVE_CANCEL,
             "Confirm exit",
             "The current hotspots have not been saved.\n" +
             "Do you want to quit anyway, save the hotspots, or cancel?")

      case result
      when MBOX_CLICKED_QUIT
        ret = EXIT_CONFIRMED

      when MBOX_CLICKED_SAVE
        commandSaveHotspots sender, sel, event # Auto-save or offer dialog.
        ret = EXIT_CONFIRMED # Todo: Only exit if saved OK?

      when MBOX_CLICKED_CANCEL
        ret = EXIT_CANCELLED
      end

    else # @undoList.marked?
      ret = EXIT_CONFIRMED
    end

    if ret == EXIT_CONFIRMED
      @settings.save
    end

    return ret
  end # confirmExit()

  private
  def commandQuit(sender, sel, event)
    if confirmExit(sender, sel, event) == EXIT_CONFIRMED
      app.exit
    end
  end

  private
  def commandCut(*args)
    @drawArea.commandCut *args
  end

  private
  def commandCopy(*args)
    @drawArea.commandCopy *args
  end

  private
  def commandPaste(*args)
    @drawArea.commandPaste *args
  end

  private
  def commandSelectAll(*args)
    @drawArea.commandSelectAll *args
  end

  private
  def commandAbout(sender, sel, event)
    about = AboutDialog.new self, nil #@bigIcon
    about.create
    about.execute
  end
  # 
  #
  private
  def commandSaveHotspotsAs(sender, sel, event)
    FXFileDialog.new(self, "Save hotspots as") do |dialog|
      dialog.filename = @settings.getValue SECTION_FILE, KEY_FILE_CURRENT,
                                            DEF_CURRENT_FILE
      dialog.patternList = [ HotspotList::PATTERN ]

      if dialog.execute == DIALOG_ACCEPT
        save dialog.filename
      end
    end
  end # commandSaveHotspotsAs()

  #
  #
  private
  def commandSaveHotspots(sender, sel, event)
    unless @undoList.marked?
      currFile = @settings.getValue SECTION_FILE, KEY_FILE_CURRENT,
                                     DEF_CURRENT_FILE
      if currFile != ''
        save currFile 
      else
        commandSaveHotspotsAs(sender, sel, event)
      end
    end
  end # commandSaveHotspots()

  #
  #
  private
  def save(filename)
    begin
      app.beginWaitCursor do
        doc = REXML::Document.new
  
        doc.add REXML::DocType.new("svg PUBLIC",
                      '"-//W3C//DTD SVG 1.1//EN" ' +
                      '"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"')
        doc.add REXML::XMLDecl.default
  
        @drawArea.saveSVG doc
        File.open(filename, "w") do |file|
          doc.write file, 1
        end
      end

      @settings.setValue SECTION_FILE, KEY_FILE_CURRENT, filename
      @undoList.mark

#     rescue Exception => error
# p "Failed to save file '#{filename}': #{error}"
    end
  end # save()

  #
  #
  private
  def commandOpenHotspots(sender, sel, event)
     FXFileDialog.new(self, "Load hotspots") do |dialog|
      dialog.filename = @settings.getValue SECTION_FILE, KEY_FILE_CURRENT,
                                            DEF_CURRENT_FILE
      dialog.patternList = [ HotspotList::PATTERN ]

      if dialog.execute == DIALOG_ACCEPT
        begin
          File.open(dialog.filename) do |file|
            doc = REXML::Document.new file
            # Check that we aren't going to delete hotspots the user wants.
            if (@undoList.marked? ||
               FXMessageBox.question(self, MBOX_OK_CANCEL,
                 "Confirm deletion before loading",
                 "Really delete the current hotspots and load another set?") ==
                 MBOX_CLICKED_OK)

              app.beginWaitCursor do
                @drawArea.loadSVG doc
              end

              @settings.setValue SECTION_FILE, KEY_FILE_CURRENT, dialog.filename
              @undoList.clear
              @undoList.mark
            end
          end

#         rescue Exception => error
# p "Failed to read file '#{dialog.filename}': #{error}"
        end
      end
    end
  end # commandOpenHotspots()

  #####
  #
  private
  def commandNewHotspots(sender, sel, event)
    # Clear hotspots only if there have been no modifications or user overrides.
    if @undoList.marked? ||
       FXMessageBox.question(self, MBOX_OK_CANCEL, "Confirm deletion",
         "Really delete the current hotspots and start again?") == MBOX_CLICKED_OK
      @drawArea.clearHotspots
      @undoList.clear
      @undoList.mark
   end
  end # commandNewHotspots()

  #
  #
  #
  private
  def initToolBar()
    @toolBar = FXToolBar.new(self, LAYOUT_SIDE_TOP|PACK_UNIFORM_WIDTH|
                                 PACK_UNIFORM_HEIGHT|FRAME_RAISED|LAYOUT_FILL_X)

    buttonOpts = BUTTON_DEFAULT|ICON_ABOVE_TEXT

    # Hotspot file commands.
    icon = FXGIFIcon.new app,
                File.open(TOOLBAR_IMAGE_DIR + "help.gif", "rb").read
    @toolBarNew = FXButton.new(@toolBar, "New", icon, nil, 0, buttonOpts)
    @toolBarNew.connect(SEL_COMMAND, method(:commandNewHotspots))
    @toolBarNew.disable
    @toolBarNew.tipText = "New hotspots"

    icon = FXGIFIcon.new app,
                File.open(TOOLBAR_IMAGE_DIR + "help.gif", "rb").read
    FXButton.new(@toolBar, "Load", icon, nil, 0, buttonOpts) { |button|
      button.connect(SEL_COMMAND, method(:commandOpenHotspots))
      button.tipText = "Load new hotspots"
    }

    icon = FXGIFIcon.new app,
                File.open(TOOLBAR_IMAGE_DIR + "help.gif", "rb").read
    FXButton.new(@toolBar, "Save", icon, nil, 0, buttonOpts) { |button|
      button.connect(SEL_COMMAND, method(:commandSaveHotspots))
    }

    icon = FXGIFIcon.new app,
                File.open(TOOLBAR_IMAGE_DIR + "help.gif", "rb").read
    FXButton.new(@toolBar, "Save As", icon, nil, 0, buttonOpts) { |button|
      button.connect(SEL_COMMAND, method(:commandSaveHotspotsAs))
    }

#     FXVerticalSeparator.new(@toolBar)

    # Loading a new background.
    icon = FXGIFIcon.new app,
                File.open(TOOLBAR_IMAGE_DIR + "help.gif", "rb").read
    FXButton.new(@toolBar, "Background", icon, nil, 0, buttonOpts) { |button|
      button.connect(SEL_COMMAND, method(:commandOpenBackground))
    }

#     FXVerticalSeparator.new(@toolBar, LAYOUT_FILL_Y|SEPARATOR_GROOVE)

    # Generating hotspots.
    icon = FXGIFIcon.new app,
                        File.open(TOOLBAR_IMAGE_DIR + "generate.gif", "rb").read
    FXButton.new(@toolBar, "Generate", icon, nil, 0, buttonOpts) { |button|
      button.connect(SEL_COMMAND, method(:generateHotspots))
    }

#     FXVerticalSeparator.new(@toolBar)

    # Do what the user wants. If they aren't daft, they'll turn toolbar off.
    unless @settings.getValue SECTION_SHOW, KEY_SHOW_TOOL_BAR, true
      @toolBar.hide
    end

  end # initToolBar

  #
  # Hotspot mode tool-bar commands.
  #
  private
  def initModeBar(parent)
    @modeBar = FXToolBar.new(parent, LAYOUT_SIDE_LEFT|LAYOUT_SIDE_TOP|
              PACK_UNIFORM_WIDTH|PACK_UNIFORM_HEIGHT|LAYOUT_FILL_Y)

    buttonOpts = BUTTON_DEFAULT|ICON_ABOVE_TEXT

    # Connect the mode bar icons to the same data group as the mode menu.
    target = @menuBar[:mode].menu.radioGroups[:mode].target
    opt = FXDataTarget::ID_OPTION

    @modeButtons = Array.new

    icon = FXGIFIcon.new app,
                File.open(TOOLBAR_IMAGE_DIR + "help.gif", "rb").read
    @modeButtons.push FXButton.new(@modeBar, "Select", icon, target,
                                      (opt + DrawArea::MODE_SELECT), buttonOpts)

    icon = FXGIFIcon.new app,
                File.open(TOOLBAR_IMAGE_DIR + "help.gif", "rb").read
    @modeButtons.push FXButton.new(@modeBar, "Edit", icon, target,
                                        (opt + DrawArea::MODE_EDIT), buttonOpts)

    icon = FXGIFIcon.new app,
                File.open(TOOLBAR_IMAGE_DIR + "draw_line.gif", "rb").read
    @modeButtons.push FXButton.new(@modeBar, "Polygon", icon, target,
                                (opt + DrawArea::MODE_DRAW_POLYGON), buttonOpts)

    icon = FXGIFIcon.new app,
               File.open(TOOLBAR_IMAGE_DIR + "draw_pencil.gif", "rb").read
    @modeButtons.push FXButton.new(@modeBar, "Pencil", icon, target,
                                 (opt + DrawArea::MODE_DRAW_PENCIL), buttonOpts)

    icon = FXGIFIcon.new app,
                File.open(TOOLBAR_IMAGE_DIR + "help.gif", "rb").read
    @modeButtons.push FXButton.new(@modeBar, "Rectangle", icon, target,
                                   (opt + DrawArea::MODE_DRAW_RECT), buttonOpts)

    # Do what the user wants. If they aren't daft, they'll turn toolbar off.
    unless @settings.getValue SECTION_SHOW, KEY_SHOW_MODE_BAR, true
      @modeBar.hide
    end

  end # initModeBar


  #####
  #
  #
  private
  def modeSet(sender, sel, data)
    @drawArea.modeNum = sender.value
  end # modeSet()


  #####
  # Create required resources.
  #
  public
  def create()
    super 

    # Make us seen!
    if (x != DEF_WIN_X) && (y != DEF_WIN_Y)
      show PLACEMENT_DEFAULT # Place it where it was last left.
    else
      show PLACEMENT_SCREEN # Just stick in middle of screen.
    end
  end

  #####
  # Toggle the toolbar visibility.
  #
  private
  def toolBarToggle(sender, sel, event)
    if event == 1
      @toolBar.show
    else
      @toolBar.hide
    end

    @settings.setValue SECTION_SHOW, KEY_SHOW_TOOL_BAR, @toolBar.shown?

    # Make sure our change is updated.
    @layoutFrame.recalc

  end # toolBarToggle()

  #####
  # Toggle the status bar visibility.
  #
  private
  def statusBarToggle(sender, sel, event)
    if event == 1
      @statusBar.show
    else
      @statusBar.hide
    end

    @settings.setValue SECTION_SHOW, KEY_SHOW_STATUS, @statusBar.shown?

    # Make sure our change is updated.
    @layoutFrame.recalc

  end # statusToggle()

  #####
  # Toggle the drawing mode tool bar visibility.
  #
  private
  def modeBarToggle(sender, sel, event)
    if event == 1
      @modeBar.show
    else
      @modeBar.hide
    end

    @settings.setValue SECTION_SHOW, KEY_SHOW_MODE_BAR, @modeBar.shown?

    # Make sure our change is updated.
    @mainFrame.recalc

  end # modeBarToggle()

  #####
  # commandOpenBackground()
  #
  private
  def commandOpenBackground(sender, sel, event)
    FXFileDialog.new(self, "Select a background image") do |dialog|
      dialog.patternList = "Jpeg images (*.jpg,*.jpeg)\n" +
                           "GIF images (*.gif)\n" +
                           "PNG images (*.png)\n"

      if dialog.execute == DIALOG_ACCEPT
        @drawArea.loadBackground dialog.filename
      end
    end

  end # commandOpenBackground()


  #####
  #
  private
  def generateHotspots(sender, sel, event)
    dialog = GenerateDialog.new(self)

    if dialog.execute == DIALOG_ACCEPT
      case dialog.shape
      when GenerateDialog::SHAPE_RECTANGLE
        @drawArea.generateRectangles dialog.hotspotWidth, dialog.hotspotHeight,
                                     dialog.columns, dialog.rows

      when GenerateDialog::SHAPE_HEXAGON
        @drawArea.generateHexagons dialog.hotspotHeight,
                                   dialog.columns, dialog.rows

      end      
    end
 
  end # generateHotspots()
end


###############################################################################
if __FILE__ == $0
  app = FXApp.new(PROGRAM, AUTHOR)

  # Fix problem with threads (affects FXDataTarget).
  app.threadsEnabled = false

  HotspotEditor.new(app)

  app.create
  
  app.run
end