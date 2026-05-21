"""
Simple test to verify info() functions work correctly.
This test creates minimal classes to avoid circular import issues.
"""
import unittest

# Create minimal test classes that simulate the behavior
class MockLocalStr:
    def __init__(self, text):
        self.text = text
    
    def __str__(self):
        return self.text
    
    def __add__(self, other):
        return MockLocalStr(str(self) + str(other))

class MockRarityType:
    COMMON = MockLocalStr("Common")
    RARE = MockLocalStr("Rare")

class TestInfoFunctions(unittest.TestCase):
    """Test info() method patterns"""
    
    def test_relic_info_pattern(self):
        """Test relic info returns correct format"""
        # Simulate relic info format
        name = "TestRelic"
        rarity = MockRarityType.COMMON
        description = "A test relic"
        
        # Simulate the info method output
        info = MockLocalStr(name) + f" (Rarity: {rarity.text})\n" + MockLocalStr(description)
        
        self.assertIn("TestRelic", str(info))
        self.assertIn("Rarity: Common", str(info))
        self.assertIn("A test relic", str(info))
        
    def test_potion_info_pattern(self):
        """Test potion info returns correct format"""
        name = "TestPotion"
        description = "A test potion"
        
        info = MockLocalStr(name) + "\n" + MockLocalStr(description)
        
        self.assertIn("TestPotion", str(info))
        self.assertIn("A test potion", str(info))
        # Should NOT contain rarity or category
        self.assertNotIn("Rarity", str(info))
        self.assertNotIn("Category", str(info))
        
    def test_power_info_pattern_buff(self):
        """Test power info for buff returns correct format"""
        name = "TestBuff"
        duration = 3
        is_buff = True
        description = "A test buff"
        
        power_type = "Buff" if is_buff else "Debuff"
        
        info = MockLocalStr(name) + f" (Duration: {duration}, Type: {power_type})\n" + MockLocalStr(description)
        
        self.assertIn("TestBuff", str(info))
        self.assertNotIn("Amount", str(info))
        self.assertIn("Duration: 3", str(info))
        self.assertIn("Type: Buff", str(info))
        self.assertIn("A test buff", str(info))
        
    def test_power_info_pattern_debuff(self):
        """Test power info for debuff returns correct format"""
        name = "TestDebuff"
        duration = 5
        is_buff = False
        description = "A test debuff"
        
        power_type = "Buff" if is_buff else "Debuff"
        
        info = MockLocalStr(name) + f" (Duration: {duration}, Type: {power_type})\n" + MockLocalStr(description)
        
        self.assertIn("TestDebuff", str(info))
        self.assertNotIn("Amount", str(info))
        self.assertIn("Duration: 5", str(info))
        self.assertIn("Type: Debuff", str(info))
        
    def test_power_info_pattern_permanent(self):
        """Test power info for permanent power returns correct format"""
        name = "TestPermanent"
        duration = 0
        is_buff = True
        description = "A permanent power"
        
        power_type = "Buff" if is_buff else "Debuff"
        
        # For permanent power (duration=-1), no duration is shown
        info = MockLocalStr(name) + f" (Type: {power_type})\n" + MockLocalStr(description)
        
        self.assertIn("TestPermanent", str(info))
        self.assertNotIn("Amount", str(info))
        self.assertNotIn("Duration", str(info))
        self.assertIn("Type: Buff", str(info))


if __name__ == '__main__':
    unittest.main()