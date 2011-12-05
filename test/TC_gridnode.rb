###############################################################################
#
#
require 'test/unit'

# require 'yaml' # For debugging only.

require '../lib/pathfinding'
include PathFinding

###############################################################################
#
class TC_GridNode < Test::Unit::TestCase
  #
  public
  def setup
    # 0 => Empty / no node.
    # 1..n => entry cost.
    # Transpose so it acts the way it looks.
    @grid = [
      [1, 1, 1, 1, 1],
      [6, 0, 0, 0, 1],
      [1, 1, 1, 1, 1],
      [1, 0, 0, 0, 0],
      [1, 1, 1, 1, 1]
    ].transpose
    
    # Change numbers to nodes.
    @grid.size.times do |r|
      @grid.first.size.times do |c|
        if @grid[c][r] == 0
          @grid[c][r] = nil
        else
          @grid[c][r] = GridNode.new((@grid[c][r]), c, r)
        end
      end
    end
    
    # Provide links.
    @grid.size.times do |r|
      @grid.first.size.times do |c|
        if @grid[c][r]
          @grid[c][r].exits.push @grid[c-1][r] if c > 0              && @grid[c-1][r]
          @grid[c][r].exits.push @grid[c+1][r] if c < (@grid.size-1) && @grid[c+1][r]
          @grid[c][r].exits.push @grid[c][r-1] if r > 0              && @grid[c][r-1]
          @grid[c][r].exits.push @grid[c][r+1] if r < (@grid.size-1) && @grid[c][r+1]
        end
      end
    end

  end # setup()
  
  #
  public
  def test_initialize()
    node = GridNode.new 5, 6, 7

    assert_equal node.entryCost, 5
    assert_equal node.x, 6
    assert_equal node.y, 7
    assert_equal node.exits.size, 0
  end # test_initialize()

  #
  public
  def test_distanceTo()
    # Positive nodes.
    node1 = GridNode.new 5, 6, 7
    node2 = GridNode.new 5, 10, 3

    assert_equal 0, node1.distanceTo(node1)

    assert_equal 8, node1.distanceTo(node2)
    assert_equal 8, node2.distanceTo(node1)

    # Negative nodes.
    node3 = GridNode.new 5, -12, -8
    node4 = GridNode.new 5, -4, -2

    assert_equal 0, node3.distanceTo(node3)

    assert_equal 14, node3.distanceTo(node4)
    assert_equal 14, node4.distanceTo(node3)

    # Negative-positive.
    assert_equal 33, node3.distanceTo(node1)
    assert_equal 33, node1.distanceTo(node3)
  end # test_distanceTo()

  #
  public
  def test_shortestPath()
    # Long path to test for shortestPath().
    longPathCoords = [
      [0, 0], [0, 1], [0, 2], [0, 3], [0, 4], [1, 4], [2, 4], [3, 4], [4, 4]
    ]
    # Convert into GridNode array.
    longPath = longPathCoords.collect do |x, y|
      @grid[x][y]
    end
    longPathDistance = 13

    # Unlimited path length.
    path = longPath.first.shortestPath longPath.last
    assert_paths_same(longPath, longPathDistance, path)

    # Test with max distance less than distance expected.
    (0...longPathDistance).each do |limit|
    path = longPath.first.shortestPath longPath.last, limit
      assert_nil path, "Path returned, in spite of limit being too low."
    end

    # Test with max greater than or equal to expected length.
    (longPathDistance..(longPathDistance + 5)).each do |limit|
      path = longPath.first.shortestPath longPath.last, limit
      assert_paths_same(longPath, longPathDistance, path)
    end
  end # test_shortestPath()
  
  #
  public
  def test_absolutePaths()
    # Absolute paths to test for.
    pathsCoords = [
      [ [0, 0], [1, 0], [2, 0], [3, 0], [4, 0] , [4, 1], [4, 2], [3, 2], [2, 2] ],
      [ [0, 0], [0, 1], [0, 2], [0, 3] ],
      [ [0, 0], [0, 1], [0, 2], [1, 2] ]
    ]

    # Convert into GridNode arrays.
    expNodeLists = Array.new
    pathsCoords.each do |coordList|
      path = coordList.collect do |x, y|
        @grid[x][y]
      end
      expNodeLists.push path
    end
    expDistance = 8

    paths = expNodeLists[0][0].absolutePaths expDistance

    # Check that array has correctly been returned.
    assert_kind_of Array, paths, "Paths expected to be in an array"
    assert_equal expNodeLists.size, paths.size, "Wrong # of paths returned."

    # Check each path in returned array.
    expNodeLists.each_with_index do |nodeList, i|
      assert_paths_same(nodeList, expDistance, paths[i])
    end

  end # test_absolutePaths()

  #
  public
  def test_allPaths_limited()
    maxLen = 7
    paths = @grid[0][0].allPaths maxLen
#     if paths
#       paths.each { |path| puts path.join("; ") + " = #{path.distance}" }
#     else
#       puts "Paths not found."
#     end
  end # test_allPaths_limited()
  
  #
  public
  def test_allPaths_unlimited()
    paths = @grid[0][0].allPaths

    # Check that all paths are considered.
    numPossPaths = @grid.flatten.nitems - 1 # Don't include start!
    assert_equal numPossPaths, paths.size, 'Wrong number of paths produced'

#       paths.each { |path| puts path.join("; ") + " = #{path.distance}" }
#     else
#       puts "Paths not found."
#     end
  end # test_allPaths_unlimited()

  #
  private
  def assert_paths_same(expectedNodes, expectedDist, path)
    # Check path is of correct type
    assert_kind_of(Path, path, "'path' is not a Path")

    # Check similarity.
    assert_equal(expectedNodes.size, path.size, "Path has wrong number of nodes.")
    assert_equal(expectedDist, path.distance, "Path of incorrect distance.")
    expectedNodes.each_with_index do |node, i|
      assert_equal(path[i], node, "Bad path node.")
    end
  end
end # class TC_GridNode