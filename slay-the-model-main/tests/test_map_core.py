"""
Core test for map system without Room dependencies.
"""
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))


def test_map_generation():
    """Test basic map generation."""
    print("=" * 60)
    print("Test: Map Generation Core")
    print("=" * 60)
    
    # Import only core modules
    from map.map_node import MapNode
    from map.map_data import MapData
    from utils.types import RoomType
    
    # Create a simple map manually
    map_data = MapData(act_id=1)
    
    # Add floor 0
    floor_0_nodes = [
        MapNode(0, 0, RoomType.MONSTER, connections_up=[0, 1]),
        MapNode(0, 1, RoomType.MONSTER, connections_up=[1, 2]),
        MapNode(0, 2, RoomType.MONSTER, connections_up=[2]),
        MapNode(0, 3, RoomType.MONSTER, connections_up=[1]),
    ]
    map_data.add_floor(floor_0_nodes)
    
    # Add floor 1
    floor_1_nodes = [
        MapNode(1, 0, RoomType.ELITE),
        MapNode(1, 1, RoomType.REST),
        MapNode(1, 2, RoomType.MONSTER),
    ]
    map_data.add_floor(floor_1_nodes)
    
    # Add floor 2
    floor_2_nodes = [
        MapNode(2, 0, RoomType.BOSS),
    ]
    map_data.add_floor(floor_2_nodes)
    
    print(f"Created map with {map_data.floor_count} floors")
    print()
    
    # Display map
    for floor in range(map_data.floor_count):
        floor_nodes = map_data.get_floor(floor)
        print(f"Floor {floor}:")
        for node in floor_nodes or []:
            print(f"  Position {node.position}: {node.room_type.value}")
            print(f"    Up: {node.connections_up}")
    
    print()
    print("[OK] Map created successfully")
    print()
    # Test passed


def test_navigation():
    """Test navigation between nodes."""
    print("=" * 60)
    print("Test: Navigation")
    print("=" * 60)
    
    from map.map_data import MapData
    from utils.types import RoomType
    from map.map_node import MapNode
    
    # Create test map
    map_data = MapData(act_id=1)
    
    floor_0 = [
        MapNode(0, 0, RoomType.MONSTER, connections_up=[0, 1]),
        MapNode(0, 1, RoomType.MONSTER, connections_up=[1]),
    ]
    map_data.add_floor(floor_0)
    
    floor_1 = [
        MapNode(1, 0, RoomType.REST),
        MapNode(1, 1, RoomType.MONSTER),
    ]
    map_data.add_floor(floor_1)
    
    # Test setting position
    map_data.set_current_position(0, 0)
    print(f"Set position to Floor 0, Position 0")
    current = map_data.get_current_node()
    assert current is not None
    print(f"Current node: Floor {current.floor}, Position {current.position}, "
          f"Type: {current.room_type.value}")
    print(f"Visited: {current.visited}")
    print()
    
    # Test getting nodes
    node = map_data.get_node(1, 1)
    assert node is not None
    print(f"Got node at Floor 1, Position 1: {node.room_type.value}")
    print()
    
    print("[OK] Navigation working correctly")
    print()


def test_room_types():
    """Test room type enum."""
    print("=" * 60)
    print("Test: Room Types")
    print("=" * 60)
    
    from utils.types import RoomType
    
    print("Available room types:")
    for room_type in RoomType:
        print(f"  - {room_type.name}: {room_type.value}")
    
    print()
    print("[OK] Room types defined correctly")
    print()


def main():
    """Run all tests."""
    print("\n")
    print("============================================================")
    print("             Map Core Test Suite")
    print("============================================================")
    print("\n")
    
    try:
        # Test room types
        test_room_types()
        
        # Test map generation
        test_map_generation()
        
        # Test navigation
        test_navigation()
        
        print("=" * 60)
        print("All core tests completed successfully!")
        print("=" * 60)
        
    except Exception as e:
        print(f"\n[ERROR] Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
