###############################################################################
# Project::     Bored Game
# Application:: HotspotEditor
# Classes::     GenerateDialog
#
# Author::      Bil Bas
# Modified::    $Date: 2004/07/23 15:25:22 $
#
###############################################################################

###############################################################################
# A dialog to set settings in order to automatically generate a grid of
# hotspots.
#
# Author:: Bil Bas (mailto:bil.bas@uclan.ac.uk)
#
class GenerateDialog < FXDialogBox

  # Whether to create rectangular or hexagonal hotspots.
  SHAPE_RECTANGLE = 0
  SHAPE_HEXAGON = 1

  # :stopdoc:
  # Default height and width of hotspots to create.
  DEFAULT_HS_WIDTH = 50
  DEFAULT_HS_HEIGHT = 50

  # Number of rows and columns of hotspots to create.
  DEFAULT_ROWS = 5
  DEFAULT_COLUMNS = 5

  # Number of characters wide for the integer input fields.
  INPUT_INT_WIDTH = 4
  # :startdoc:

  #
  # Creates a new generator dialog.
  #
  private
  def initialize(master)
    super master, "Generate hotspots", DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE

    # Shapes - rectangles or hexagons.
    shapeBox = FXGroupBox.new self, "Shape",
                     LAYOUT_CENTER_X|LAYOUT_BOTTOM|FRAME_GROOVE|LAYOUT_FILL_X

# WORKS, BUT IT IS *UNBEARABLY* SLOW
#     @shapeChosen = FXDataTarget.new(SHAPE_RECTANGLE)
#     @radioRectangle = FXRadioButton.new shapeBox, "Rectangles", @shapeChosen, FXDataTarget::ID_OPTION+1
#     @radioHexagon = FXRadioButton.new shapeBox, "Hexagons", @shapeChosen, FXDataTarget::ID_OPTION+2
#     @radioRectangle.check = TRUE

    @radioRectangle = FXRadioButton.new shapeBox, "Rectangles"
    @radioHexagon = FXRadioButton.new shapeBox, "Hexagons"
    @radioRectangle.check = TRUE

    # Todo: These connections should not be needed. Use FXDataTarget?
    @radioHexagon.connect(SEL_COMMAND) { |sender, sel, data|
      @radioRectangle.check = FALSE
    }

    @radioRectangle.connect(SEL_COMMAND) { |sender, sel, data|
      @radioHexagon.check = FALSE
    }

    # Dimensions of the items.
    sizeFrame = FXGroupBox.new self, "Hotspot dimensions",
                     LAYOUT_CENTER_X|LAYOUT_BOTTOM|FRAME_GROOVE|LAYOUT_FILL_X
    centreMatrix = FXMatrix.new sizeFrame, 1, PACK_UNIFORM_WIDTH|MATRIX_BY_ROWS|LAYOUT_FILL_X
    FXLabel.new centreMatrix, "Width" 
    @hsWidth = FXTextField.new(centreMatrix, INPUT_INT_WIDTH, nil, 0,
        TEXTFIELD_INTEGER|TEXTFIELD_NORMAL)

    FXLabel.new centreMatrix, "Height"
    @hsHeight = FXTextField.new(centreMatrix, INPUT_INT_WIDTH, nil, 0,
        TEXTFIELD_INTEGER|TEXTFIELD_NORMAL)

    @hsWidth.text = DEFAULT_HS_WIDTH.to_s
    @hsHeight.text = DEFAULT_HS_HEIGHT.to_s

    # Number of rows and columns.
    colRowFrame = FXGroupBox.new self, "Number of hotspots",
                     LAYOUT_CENTER_X|LAYOUT_BOTTOM|FRAME_GROOVE
    centreMatrix = FXMatrix.new colRowFrame, 1, PACK_UNIFORM_WIDTH|MATRIX_BY_ROWS|LAYOUT_FILL_X
    FXLabel.new centreMatrix, "Rows" 
    @numRows = FXTextField.new(centreMatrix, INPUT_INT_WIDTH, nil, 0,
        TEXTFIELD_INTEGER|TEXTFIELD_NORMAL)

    FXLabel.new centreMatrix, "Columns"
    @numColumns = FXTextField.new(centreMatrix, INPUT_INT_WIDTH, nil, 0,
        TEXTFIELD_INTEGER|TEXTFIELD_NORMAL)

    @numRows.text = DEFAULT_ROWS.to_s
    @numColumns.text = DEFAULT_COLUMNS.to_s

    # Buttons
    buttonFrame = FXHorizontalFrame.new self,
                     LAYOUT_CENTER_X|LAYOUT_BOTTOM|FRAME_NONE
    FXButton.new buttonFrame, 'Cancel', nil, self, FXDialogBox::ID_CANCEL

    FXButton.new buttonFrame, 'Generate', nil, self, FXDialogBox::ID_ACCEPT
  end

  #
  # Which shape has been chosen for the new hotspots?
  # * +SHAPE_RECTANGLE+
  # * +SHAPE_HEXAGON+
  #
  public
  def shape()
    if @radioRectangle.checked?
      return SHAPE_RECTANGLE
    elsif @radioHexagon.checked?
      return SHAPE_HEXAGON
    end
  end

  #
  # Number of columns of hotspots to create.
  #
  public
  def columns()
    @numColumns.text.to_i
  end

  #
  # Number of rows of hotspots to create.
  #
  public
  def rows()
    @numRows.text.to_i
  end

  #
  # Width (in pixels) of the hotspots to create. Ignored for hexagons.
  #
  public
  def hotspotWidth()
    @hsWidth.text.to_i
  end

  #
  # Height (in pixels) of the hotspots to create. Ignored for hexagons.
  #
  public
  def hotspotHeight()
    @hsHeight.text.to_i
  end
end