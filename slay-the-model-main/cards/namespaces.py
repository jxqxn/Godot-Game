"""
Card namespaces and color definitions.

Each namespace corresponds to a character's card set and has an associated color
for command-line display purposes.
"""

# Namespace to color mapping
NAMESPACE_COLORS = {
    "ironclad": "Red",
    "silent": "Green", 
    "defect": "Blue",
    "watcher": "Purple",
    "colorless": "Colorless",
    "curse": "Colorless",
    "status": "Colorless",
}

# Character to namespace mapping
CHARACTER_NAMESPACES = {
    "Ironclad": "ironclad",
    "Silent": "silent",
    "Defect": "defect",
    "Watcher": "watcher",
}

# Registry of cards by namespace
CARD_NAMESPACES = {namespace: {} for namespace in NAMESPACE_COLORS.keys()}


def get_namespace_for_character(character: str) -> str:
    """Get the namespace for a given character."""
    return CHARACTER_NAMESPACES.get(character, "colorless")


def get_color_for_namespace(namespace: str) -> str:
    """Get the color for a given namespace."""
    return NAMESPACE_COLORS.get(namespace, "Colorless")


def namespace_from_module(module_path):
    """Extract namespace from module path.
    
    Expected module structure: cards.{namespace}.{filename}
    
    Args:
        module_path: Module path string or None
    """
    if not module_path:
        return "colorless"
    
    parts = module_path.split(".")
    if len(parts) >= 2 and parts[0] == "cards":
        # Check if the second part is a known namespace
        if len(parts) > 1 and parts[1] in NAMESPACE_COLORS:
            return parts[1]
    
    # Try to infer from folder structure
    import os
    module_file = module_path.replace(".", "/") + ".py"
    if os.path.exists(module_file):
        # Check parent directory
        parent_dir = os.path.dirname(module_file)
        if parent_dir and os.path.basename(parent_dir) in NAMESPACE_COLORS:
            return os.path.basename(parent_dir)
    
    return "colorless"