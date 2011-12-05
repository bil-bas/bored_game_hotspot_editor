require 'test/unit'

# require 'yaml' # For debugging only.

require '../lib/pathfinding'
include PathFinding

# Allow us to look at children of the node.
class TreeNode
  attr_reader :children
end # TreeNode

###############################################################################
#
class TC_TreeNode < Test::Unit::TestCase

  public
  def setup()
    @gridNodes = Array.new
    @gridNodes.push GridNode.new(1, 2, 3)
    @gridNodes.push GridNode.new(1, 4, 5)
    @gridNodes.push GridNode.new(3, 6, 7)
    @gridNodes.push GridNode.new(1, 8, 9)

    @estDistToGo = 12

    # Simple tree structure.
    #    0
    #    |
    #    1
    #   / \
    #  2   3
   
    # Root node.
    @treeNodes = Array.new
    @treeNodes.push TreeNode.new(nil, @gridNodes[0], @estDistToGo)

    # Create a 2nd node.
    @treeNodes.push TreeNode.new(@treeNodes[0], @gridNodes[1],
                      (@estDistToGo - @gridNodes[1].entryCost))

    # Create a 3rd node.
    @treeNodes.push TreeNode.new(@treeNodes[1], @gridNodes[2],
             (@estDistToGo - @gridNodes[2].entryCost - @gridNodes[1].entryCost))

    # Create a 4th node.
    @treeNodes.push TreeNode.new(@treeNodes[1], @gridNodes[3],
             (@estDistToGo - @gridNodes[3].entryCost - @gridNodes[1].entryCost))

  end # setup()

  public
  def test_initialize()
    # Test root node.
    assert_nil   @treeNodes[0].parent
    assert_equal @gridNodes[0], @treeNodes[0].gridNode
    assert_equal @estDistToGo, @treeNodes[0].estDistToGo
    assert_equal 0, @treeNodes[0].distSoFar # Root costs nothing.

    # Test a child node.
    assert_equal @treeNodes[0], @treeNodes[1].parent
    assert_equal @gridNodes[1], @treeNodes[1].gridNode
    assert_equal (@estDistToGo - @gridNodes[1].entryCost), @treeNodes[1].estDistToGo
    assert_equal @gridNodes[1].entryCost, @treeNodes[1].distSoFar

  end # setup()

  #
  public
  def test_addChild()
  end # test_addChild()

  #
  public
  def test_removeChild()
  end # test_removeChild()

  #
  public
  def test_relocate()
    @treeNodes[2].relocate @treeNodes[0]

    assert_equal @treeNodes[0], @treeNodes[2].parent,
                "New parent not registered."
    assert_equal 1, @treeNodes[0].children.index(@treeNodes[2]),
                 "Node is not a child of new parent."
    assert_nil   @treeNodes[1].children.index(@treeNodes[0]),
                 "Node is still a child of old parent."

    assert_equal @treeNodes[2].distSoFar, @gridNodes[2].entryCost,
                 "DistSoFar has not been updated correctly"
  end # test_Relocate()

  #
  public
  def test_path()
    assert_equal @treeNodes[0].path, [ @gridNodes[0] ]
    assert_equal @treeNodes[1].path, [ @gridNodes[0], @gridNodes[1] ]
    assert_equal @treeNodes[2].path, [ @gridNodes[0], @gridNodes[1], @gridNodes[2] ]
    assert_equal @treeNodes[3].path, [ @gridNodes[0], @gridNodes[1], @gridNodes[3] ]
  end # test_path()

  #
  public 
  def test_estTotalDist()
    @treeNodes.each_with_index do |node, i|
      assert_equal @estDistToGo, node.estTotalDist, "For node #{i}"
    end
  end # test_estTotalDist()


end # class TC_TreeNode