###############################################################################
# Simple test app.
#
$:.push '../lib'

require 'menu'
include Menu

class MenuTest < FXMainWindow
  #
  #
  #
  private
  def initialize(app)
    super app, "Menu Test", nil, nil,
        DECOR_ALL|LAYOUT_MIN_WIDTH|LAYOUT_MIN_HEIGHT, 0, 0, 600, 300

    @menuBar = MenuBar.new self, File.open("menu_test.yml"), self

    # Check links to commands.
    @menuBar[:file].menu[:open].enabled = false

#     p @menuBar[:file].text
#     p @menuBar[:file].menu[:open]
#     p @menuBar[:file].menu[:open]
#     p ""

#     # Examine the menu group, change the selected button.
#     modeGroup = @menuBar[:mode].menu.radioGroups[:mode]
#     p "RadioGroup: #{modeGroup.inspect}"
#     p "Selected: #{modeGroup.selected}"
#     modeGroup.target.value = 1
#     p "Selected: #{modeGroup.selected}"
#     modeGroup.target.value = 3
#     p "Selected: #{modeGroup.selected}"
#     p ""

#     p @menuBar[:view].menu[:barsShown]
#     p @menuBar[:view].menu[:barsShown].menu[:statusBarToggle]
    @menuBar[:view].menu[:barsShown].menu[:statusBarToggle].check

    layout = FXVerticalFrame.new self, LAYOUT_FILL_X|LAYOUT_FILL_Y,
             0,0,0,0, 0,0,0,0

    @statusBar = FXStatusBar.new(layout,
                   LAYOUT_FILL_X|LAYOUT_BOTTOM|STATUSBAR_WITH_DRAGCORNER)

    canvas = FXCanvas.new layout, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y

    canvas.connect(SEL_RIGHTBUTTONRELEASE, method(:onRightMouseUp))
    canvas.connect(SEL_PAINT) do |sender, sel, event|
      FXDCWindow.new(sender, event) do |dc|
        rect = event.rect
        dc.fillRectangle rect.x, rect.y, rect.w, rect.h
      end
    end
 
    @out = FXLabel.new layout, "Hello!"
  end

  private
  def commandHelp(sender, sel, event);  @out.text = "Help!"; end
  def commandAbout(sender, sel, event); @out.text = "About!"; end

  def commandNewHotspots(sender, sel, event);  @out.text = "New!"; end
  def commandOpenHotspots(sender, sel, event);  @out.text = "Open!"; end
  def commandSaveHotspots(sender, sel, event); @out.text = "Save!"; end
  def commandSaveHotspotsAs(sender, sel, event);  @out.text = "SaveAs!"; end
  def commandOpenBackground(sender, sel, event); @out.text = "Background!"; end
  def commandQuit(sender, sel, event); @out.text = "Quit!"; end

  def modeSet(sender, sel, event)
    @out.text = "Mode '#{@menuBar[:mode].menu.radioGroups[:mode].selected}' " +
      "(#{sender.value}) selected!"
  end

  def stateName(state); (state == 1 ? 'on' : 'off') ; end 
  def toolBarToggle(sender, sel, state); @out.text = "toolbar #{stateName(state)}!"; end
  def statusBarToggle(sender, sel, state); @out.text = "statusbar #{stateName(state)}!"; end
  def modeBarToggle(sender, sel, state); @out.text = "modeBar #{stateName(state)}!"; end

#   def commandUndo(sender, sel, event); @out.text = "undo!"; end
#   def commandRedo(sender, sel, event); @out.text = "redo!"; end

  # Dynamically affect the menu.
  def commandCut(sender, sel, event)
     @out.text = "Cut! (Paste enabled)"
     @menuBar[:edit].menu[:paste].enabled = true
  end
  def commandCopy(sender, sel, event);
    @out.text = "Copy! (Paste enabled)" 
    @menuBar[:edit].menu[:paste].enabled = true
  end
  def commandPaste(sender, sel, event); @out.text = "paste!"; end

  def commandSelectAll(sender, sel, event); @out.text = "select all!"; end
  def generateHotspots(sender, sel, event); @out.text = "generate!"; end

  # Create a context menu on right mouse up.
  def onRightMouseUp(sender, sel, event)
    if !event.moved?
      pane = PopupMenu.new self, File.open("context_menu_test.yml"), self
      pane.create
      pane.runModal event.root_x, event.root_y
    end
  end

  #
  #
  #
  private
  def create()
    super
    show PLACEMENT_SCREEN
  end
end

app = FXApp.new "menu test", "bil"

app.threadsEnabled = false

MenuTest.new(app)

app.create

app.run