###############################################################################
# Project::     Bored Game
# Application:: Hotspot Editor
# Classes::     AboutDialog
#
# Author::      Bil Bas
# Modified::    $Date: 2004/07/23 15:25:22 $
#
###############################################################################

###############################################################################
#
#
class AboutDialog < FXDialogBox
  # :stopdoc:
  FONT_FAMILY     = "arial"
  TITLE_FONT_SIZE = 14
  # :startdoc:

  ###
  # Constructs a dialog showing some information about the application.
  #
  private
  def initialize(master, icon)
    super(master, "About #{PROGRAM}", DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE,
      0, 0, 0, 0, 6, 6, 6, 6, 4, 4)

    frame = FXHorizontalFrame.new self, LAYOUT_TOP

    # Just an icon
    FXLabel.new frame, '', icon, LAYOUT_LEFT|LAYOUT_TOP

    # Frame contains textual details.
    frame2 = FXVerticalFrame.new frame, LAYOUT_RIGHT

    prog = FXLabel.new frame2, PROGRAM, nil, LAYOUT_TOP|JUSTIFY_LEFT
    prog.font = FXFont.new(app, FONT_FAMILY, TITLE_FONT_SIZE, FONTWEIGHT_BOLD)

    text = <<END_TEXT
An editor which allows the editing of
hotspot regions of various shapes.
Part of Bored Game.

by #{AUTHOR} @2004

Running under:
        FXRuby #{Fox.fxrubyversion}
        FOX #{Fox.fxversion}
END_TEXT

    details = FXLabel.new frame2, text, nil, JUSTIFY_LEFT

    FXButton.new self, 'OK', nil, self,
        FXDialogBox::ID_ACCEPT,
        LAYOUT_CENTER_X|BUTTON_INITIAL|BUTTON_DEFAULT
  end # initialize()

  ###
  #
  #
  #
  public
  def execute()
    super PLACEMENT_OWNER
  end # execute()
end # AboutDialog()