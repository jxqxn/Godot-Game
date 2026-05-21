from localization import LocalStr, resolve_text


def test_resolve_text_handles_localized_objects_and_raw_keys():
    assert resolve_text(LocalStr("rooms.ShopRoom.title")) == "Shop"
    assert resolve_text("rooms.ShopRoom.remove_card") == "Remove a card ({price} gold)"
    assert resolve_text("plain text") == "plain text"
    assert resolve_text(None) == ""
